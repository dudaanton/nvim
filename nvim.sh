#!/bin/bash

#===============================================================================
# Neovim Docker Launcher
# Launches Neovim in a Docker container with auto-detection for Swift projects
#===============================================================================

# Check if directory contains a Swift project
is_swift_project() {
  local dir="$1"

  # Check for Swift project indicators
  if [ -f "$dir/Package.swift" ]; then
    return 0  # SPM project
  fi

  if ls "$dir"/*.xcodeproj >/dev/null 2>&1; then
    return 0  # Xcode project
  fi

  if ls "$dir"/*.xcworkspace >/dev/null 2>&1; then
    return 0  # Xcode workspace
  fi

  # Check for .swift files (recursive, max 3 levels)
  if find "$dir" -maxdepth 3 -name "*.swift" -type f 2>/dev/null | grep -q .; then
    return 0  # Has Swift files
  fi

  return 1  # Not a Swift project
}

# Generate buildServer.json for Xcode projects
# Automatically finds all non-test schemes and generates configuration for all at once
generate_build_server_json() {
  local project_dir="$1"
  local force_rebuild="$2"  # true/false

  # Check if this is an Xcode project (look for .xcodeproj directory)
  local xcodeproj=$(find "$project_dir" -maxdepth 1 -name "*.xcodeproj" -type d 2>/dev/null | head -1)
  if [ -z "$xcodeproj" ]; then
    # No .xcodeproj - skip (may be SPM project)
    return 0
  fi

  local project_name=$(basename "$xcodeproj")

  # Check if buildServer.json already exists
  if [ -f "$project_dir/buildServer.json" ] && [ "$force_rebuild" != "true" ]; then
    echo "buildServer.json already exists (use --rebuild-build-server to regenerate)"
    return 0
  fi

  # Check if xcode-build-server is installed
  if ! command -v xcode-build-server &> /dev/null; then
    echo "⚠️  WARNING: xcode-build-server not found"
    echo "   LSP may not work properly with Xcode projects"
    echo "   Install: brew install xcode-build-server"
    echo "   Then run: xcode-build-server config -project $project_name -scheme \"YourScheme\""
    return 1
  fi

  echo "Generating buildServer.json for $project_name..."

  # Get list of schemes
  local schemes=$(xcodebuild -list -project "$xcodeproj" 2>/dev/null | \
    awk '/Schemes:/,0' | \
    grep -v "Schemes:" | \
    sed 's/^[[:space:]]*//' | \
    grep -v -E "Tests?$")  # Filter out schemes ending with Test/Tests

  if [ -z "$schemes" ]; then
    echo "⚠️  WARNING: Could not detect schemes in $project_name"
    echo "   Manually run: xcode-build-server config -project $project_name -scheme \"YourScheme\""
    return 1
  fi

  # Build xcode-build-server config command
  local cmd="xcode-build-server config -project \"$xcodeproj\""

  # Add all schemes
  local scheme_count=0
  while IFS= read -r scheme; do
    if [ -n "$scheme" ]; then
      cmd="$cmd -scheme \"$scheme\""
      scheme_count=$((scheme_count + 1))
    fi
  done <<< "$schemes"

  if [ "$scheme_count" -eq 0 ]; then
    echo "⚠️  WARNING: No non-test schemes found in $project_name"
    return 1
  fi

  echo "  Found $scheme_count scheme(s):"
  echo "$schemes" | sed 's/^/    - /'

  # Execute command in project directory
  (
    cd "$project_dir" || exit 1
    eval "$cmd" > /dev/null 2>&1
  )

  if [ $? -eq 0 ] && [ -f "$project_dir/buildServer.json" ]; then
    echo "✅ buildServer.json generated successfully"
    return 0
  else
    echo "⚠️  WARNING: Failed to generate buildServer.json"
    echo "   Manually run: cd \"$project_dir\" && xcode-build-server config -project $project_name -scheme \"YourScheme\""
    return 1
  fi
}

#===============================================================================
# Configuration
#===============================================================================

DEFAULT_DOCKER_IMAGE="nvim-main"
DEFAULT_PROCESS="nvim"

# Variables for additional parameters
ADDITIONAL_VOLUMES=""
RUN_COMMAND=""
DOCKER_IMAGE="$DEFAULT_DOCKER_IMAGE"
TARGET_PATH=""
FORCE_SWIFT=false
REBUILD_BUILD_SERVER=false

#===============================================================================
# Parse arguments
#===============================================================================
while [[ "$#" -gt 0 ]]; do
  case "$1" in
  -v | --volume)
    if [ -n "$2" ]; then
      ADDITIONAL_VOLUMES+=" -v $2"
      shift
    else
      echo "Error: --volume requires an argument."
      exit 1
    fi
    ;;
  -i | --image)
    if [ -n "$2" ]; then
      DOCKER_IMAGE="$2"
      shift
    else
      echo "Error: --image requires an argument."
      exit 1
    fi
    ;;
  -c | --cmd)
    if [ -n "$2" ]; then
      RUN_COMMAND="$2"
      shift
    else
      echo "Error: --cmd requires an argument (command in quotes)."
      exit 1
    fi
    ;;
  --swift)
    FORCE_SWIFT=true
    ;;
  --rebuild-build-server)
    REBUILD_BUILD_SERVER=true
    ;;
  -h | --help)
    echo "Usage: $0 [OPTIONS] [PATH]"
    echo ""
    echo "Options:"
    echo "  -v, --volume PATH           Additional volume mount (format: host:container)"
    echo "  -i, --image NAME            Docker image to use (default: nvim-main)"
    echo "  -c, --cmd COMMAND           Command to run inside container (default: nvim)"
    echo "  --swift                     Force start Swift LSP server (auto-detected for Swift projects)"
    echo "  --rebuild-build-server      Force regenerate buildServer.json for Xcode projects"
    echo "  -h, --help                  Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                                        # Open Neovim in current directory"
    echo "  $0 ~/MySwiftApp                           # Open Swift project (LSP auto-started)"
    echo "  $0 --swift ~/MyProject                    # Force Swift LSP for any project"
    echo "  $0 --rebuild-build-server ~/MySwiftApp    # Regenerate buildServer.json"
    echo "  $0 -v /data:/mnt ~/MyProject              # Mount additional volume"
    exit 0
    ;;
    *)
      # If argument is not recognized as an option, treat it as path to file/folder
      if [ -z "$TARGET_PATH" ]; then
        TARGET_PATH="$1"
      else
        echo "Error: Unknown argument or multiple paths: $1"
        echo "Use --help for usage information"
        exit 1
      fi
      ;;
  esac
  shift
done

#===============================================================================
# Determine mount paths
#===============================================================================
if [ -n "$TARGET_PATH" ]; then
  # Convert to absolute path
  TARGET_PATH="$(realpath "$TARGET_PATH")"

  if [ -d "$TARGET_PATH" ]; then
    # Argument is a directory
    HOST_MOUNT_PATH="$TARGET_PATH"

    # For macOS Swift projects: mount at same path as on host
    # This is necessary for sourcekit-lsp running on host to see
    # files at the same paths as Neovim inside container
    #
    # Security:
    # - macOS only (check $OSTYPE)
    # - Path must be inside $HOME (not system directories like /etc, /var)
    # - macOS uses /Users/, Linux container uses /home/ → no conflicts
    if [[ "$OSTYPE" == "darwin"* ]] && [[ "$TARGET_PATH" == "$HOME"* ]]; then
      WORKSPACE_DIR="$TARGET_PATH"
      CONTAINER_DIR_NAME="$(basename "$TARGET_PATH")"
    else
      # For Linux or paths outside $HOME: use /w_ prefix
      CONTAINER_DIR_NAME="w_$(basename "$TARGET_PATH")"
      WORKSPACE_DIR="/$CONTAINER_DIR_NAME"
    fi

    WORKSPACE_VOLUME="-v \"$HOST_MOUNT_PATH:$WORKSPACE_DIR\""
    NVIM_TARGET=""
  elif [ -f "$TARGET_PATH" ]; then
    # Argument is a file
    HOST_FILE_PATH="$TARGET_PATH"
    FILE_NAME="$(basename "$TARGET_PATH")"
    WORKSPACE_DIR="/w_workspace"
    WORKSPACE_VOLUME="-v \"$HOST_FILE_PATH:$WORKSPACE_DIR/$FILE_NAME\""
    NVIM_TARGET="$FILE_NAME"
  else
    echo "Error: path does not exist: $TARGET_PATH"
    exit 1
  fi
else
  # No argument - mount current directory
  HOST_MOUNT_PATH="$(pwd)"

  # Apply same path matching logic for macOS
  if [[ "$OSTYPE" == "darwin"* ]] && [[ "$HOST_MOUNT_PATH" == "$HOME"* ]]; then
    WORKSPACE_DIR="$HOST_MOUNT_PATH"
    CONTAINER_DIR_NAME="$(basename "$HOST_MOUNT_PATH")"
  else
    CONTAINER_DIR_NAME="w_$(basename "$HOST_MOUNT_PATH")"
    WORKSPACE_DIR="/$CONTAINER_DIR_NAME"
  fi

  WORKSPACE_VOLUME="-v \"$HOST_MOUNT_PATH:$WORKSPACE_DIR\""
  NVIM_TARGET=""
fi

#===============================================================================
# Setup git volumes (read-only)
#===============================================================================
GIT_VOLUMES=""
if [ -d "$HOST_MOUNT_PATH" ]; then
  # Main .git directory
  if [ -d "$HOST_MOUNT_PATH/.git" ]; then
    # Remount .git as read-only over main mount
    GIT_VOLUMES+=" -v \"$HOST_MOUNT_PATH/.git:$WORKSPACE_DIR/.git:ro\""
  fi

  # Submodules: find .git files (links to gitdir) in subdirectories
  if [ -f "$HOST_MOUNT_PATH/.gitmodules" ]; then
    while IFS= read -r submodule_path; do
      submodule_git="$HOST_MOUNT_PATH/$submodule_path/.git"
      if [ -e "$submodule_git" ]; then
        GIT_VOLUMES+=" -v \"$submodule_git:$WORKSPACE_DIR/$submodule_path/.git:ro\""
      fi
    done < <(git -C "$HOST_MOUNT_PATH" config --file .gitmodules --get-regexp path 2>/dev/null | awk '{print $2}')
  fi
fi

#===============================================================================
# Setup command to run
#===============================================================================
if [ -z "$RUN_COMMAND" ]; then
  if [ -n "$NVIM_TARGET" ]; then
    RUN_COMMAND="$DEFAULT_PROCESS $NVIM_TARGET"
  else
    RUN_COMMAND="$DEFAULT_PROCESS"
  fi
fi

#===============================================================================
# Create necessary directories
#===============================================================================

mkdir -p $HOME/config/nvim
mkdir -p $HOME/.nvim-docker/{share,state}/nvim
mkdir -p $HOME/.nvim-docker/share/swiftly
mkdir -p $HOME/.nvim-docker/state/lazygit
mkdir -p $HOME/.nvim-docker/lazygit
mkdir -p $HOME/.nvim-docker/rust/cargo-registry
mkdir -p $HOME/.nvim-docker/rust/cargo-git
touch $HOME/.nvim-docker/rust/.global-cache
touch $HOME/.nvim-docker/rust/.package-cache
touch $HOME/.nvim-docker/rust/.package-cache-mutate
mkdir -p $HOME/.claude

MAIN_VOLUMES="-v $HOME/config/nvim:/home/dev/.config/nvim \
  -v $HOME/.nvim-docker/share/nvim:/home/dev/.local/share/nvim \
  -v $HOME/.nvim-docker/share/swiftly:/home/dev/.local/share/swiftly \
  -v $HOME/.nvim-docker/state/nvim:/home/dev/.local/state/nvim \
  -v $HOME/.nvim-docker/state/lazygit:/home/dev/.local/state/lazygit \
  -v $HOME/.llm:/home/dev/.llm \
  -v $HOME/config/lazygit:/home/dev/.config/lazygit \
  -v $HOME/.config/mcphub:/home/dev/.config/mcphub \
  -v $HOME/.claude:/home/dev/.claude \
  -v $HOME/.claude.json:/home/dev/.claude.json \
  -v $HOME/.codecompanion:/home/dev/.codecompanion \
  -v $HOME/.common:/home/dev/.common:ro \
  -v $HOME/.nvim-docker/rust/cargo-registry:/home/dev/.cargo/registry \
  -v $HOME/.nvim-docker/rust/cargo-git:/home/dev/.cargo/git \
  -v $HOME/.nvim-docker/rust/.global-cache:/home/dev/.cargo/.global-cache \
  -v $HOME/.nvim-docker/rust/.package-cache:/home/dev/.cargo/.package-cache \
  -v $HOME/.nvim-docker/rust/.package-cache-mutate:/home/dev/.cargo/.package-cache-mutate \
  -v $HOME/.gitignore_global:/home/dev/.gitignore_global:ro \
  -v $HOME/.nvim-docker/.gitconfig:/home/dev/.gitconfig \
  -v /etc/localtime:/etc/localtime:ro"

#===============================================================================
# Swift/iOS development (macOS only) - Remote LSP via TCP
#===============================================================================

SOURCEKIT_PORT=9000
SOURCEKIT_PID_FILE="$HOME/.nvim-docker/sourcekit-lsp.pid"

# Determine if Swift LSP is needed
NEED_SWIFT_LSP=false

if [[ "$OSTYPE" == "darwin"* ]]; then
  # Check --swift flag
  if [ "$FORCE_SWIFT" = true ]; then
    NEED_SWIFT_LSP=true
    echo "Swift LSP: forced by --swift flag"
  # Or auto-detect Swift project
  elif [ -d "$HOST_MOUNT_PATH" ] && is_swift_project "$HOST_MOUNT_PATH"; then
    NEED_SWIFT_LSP=true
    echo "Swift LSP: detected Swift project"
  fi

  # Generate buildServer.json if Swift LSP is needed
  if [ "$NEED_SWIFT_LSP" = true ] && [ -d "$HOST_MOUNT_PATH" ]; then
    generate_build_server_json "$HOST_MOUNT_PATH" "$REBUILD_BUILD_SERVER"
  fi

  # Start server if needed
  if [ "$NEED_SWIFT_LSP" = true ]; then
    # Check if port is already in use (server running)
    if lsof -Pi :$SOURCEKIT_PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
      echo "sourcekit-lsp server already running on port $SOURCEKIT_PORT"
    else
      # Port not in use, start the server
      if [ -f "$HOME/config/nvim/scripts/sourcekit-lsp-server.sh" ]; then
        echo "Starting sourcekit-lsp TCP server on port $SOURCEKIT_PORT..."
        nohup "$HOME/config/nvim/scripts/sourcekit-lsp-server.sh" > "$HOME/.nvim-docker/sourcekit-lsp.log" 2>&1 &
        SERVER_PID=$!
        echo $SERVER_PID > "$SOURCEKIT_PID_FILE"
        echo "sourcekit-lsp server started (PID: $SERVER_PID)"
        echo "Server binds to 0.0.0.0:$SOURCEKIT_PORT (accessible via host.docker.internal)"
        # Give it a moment to start listening
        sleep 1
        # Verify port is listening
        if ! lsof -Pi :$SOURCEKIT_PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
          echo "Warning: Server not listening on port $SOURCEKIT_PORT. Check logs: tail -f ~/.nvim-docker/sourcekit-lsp.log"
        fi
      fi
    fi
  fi
fi

#===============================================================================
# Launch container
#===============================================================================

DOCKER_CMD="docker run -it --rm --env-file ~/.llm.env \
   --network ide-net \
   $MAIN_VOLUMES \
   $ADDITIONAL_VOLUMES \
   $WORKSPACE_VOLUME \
   $GIT_VOLUMES \
  -w \"$WORKSPACE_DIR\" \
  $DOCKER_IMAGE $RUN_COMMAND"

eval "$DOCKER_CMD"
