# Neovim Docker Development Environment

A fully-configured Neovim development environment running in Docker with extensive plugin support and LSP integration.

## Quick Start

```bash
# Build the Docker image (auto-detects architecture)
./docker_build.sh

# Or with custom architecture
ARCH=x86_64 ./docker_build.sh

# Launch Neovim in current directory
./nvim.sh

# Open a specific project
./nvim.sh ~/Projects/MyApp

# Open a specific file
./nvim.sh ~/Projects/MyApp/main.py
```

## Features

- **Modern Neovim**: Latest version with lazy.nvim plugin manager
- **36+ plugins**: Including CodeCompanion, LSP, Treesitter, fuzzy finding
- **Multi-language support**: Python, Lua, Rust, Swift/iOS (macOS only)
- **Docker isolation**: Development environment completely isolated from host
- **Persistent configuration**: Config and state mounted from host
- **Git integration**: Read-only .git mounts for safety

## Language Support

### JavaScript/TypeScript/Vue
- LSP support via Mason (ts_ls, volar)
- Full Vue 3 composition API support

### Python
- Built-in python3, pip, venv support
- LSP via Mason (pyright, ruff)

### Lua
- Pre-configured lua-language-server
- Full Neovim API support

### Rust
- rustup, cargo, rust-analyzer built into image
- Persistent cargo cache between sessions

### Swift/iOS (macOS only)
- Auto-detected Swift project support
- sourcekit-lsp via TCP (runs on host)
- Xcode project integration
- See [Swift Setup](#swift-setup) below

## Project Structure

```
/w_nvim/
├── nvim.sh              # Launcher script
├── Dockerfile           # Container definition
├── init.lua             # Neovim entry point
├── lua/
│   ├── config/          # Core settings, keymaps, options
│   └── plugins/         # Plugin configurations (36 files)
├── lsp/                 # LSP server configs
└── snippets/            # Custom snippets
```

## Usage

### Basic Commands

```bash
# Launch in current directory
./nvim.sh

# Mount additional volumes
./nvim.sh -v /data:/mnt ~/MyProject

# Use different Docker image
./nvim.sh -i my-custom-nvim

# Run custom command
./nvim.sh -c "bash"

# Show help
./nvim.sh --help
```

### Key Bindings

- **Leader key**: `Space`
- **LocalLeader**: `\`
- See `lua/config/keymaps.lua` for full list

### Plugin Management

```vim
:Lazy                    " Plugin manager UI
:Mason                   " LSP/tool installer
:checkhealth             " Diagnostics
```

## Swift Setup

### Requirements (macOS only)

1. Install dependencies:
```bash
brew install socat xcode-build-server
```

2. Make scripts executable:
```bash
chmod +x ~/config/nvim/scripts/sourcekit-lsp-server.sh
chmod +x ~/config/nvim/scripts/stop-sourcekit-lsp.sh
```

### Usage

Swift projects are **auto-detected** and sourcekit-lsp server starts automatically:

```bash
# Just open your Swift project
./nvim.sh ~/MySwiftApp

# Force Swift LSP for any project
./nvim.sh --swift ~/MyProject

# Regenerate buildServer.json for Xcode projects
./nvim.sh --rebuild-build-server ~/MySwiftApp
```

### How It Works

- Neovim runs in Linux container
- sourcekit-lsp runs natively on macOS host (requires Xcode SDK)
- Communication via TCP on port 9000
- macOS projects auto-mount at same path as host (required for LSP)

### Stopping Swift LSP

```bash
~/config/nvim/scripts/stop-sourcekit-lsp.sh
```

## Configuration

### Adding Plugins

Create `lua/plugins/plugin-name.lua`:

```lua
return {
  "author/plugin-name",
  ft = "filetype",  -- lazy load by filetype
  opts = {
    -- plugin options
  }
}
```

### Adding LSP Support

1. Add language to `lua/plugins/mason-lspconfig.lua`
2. Optional: Create custom config in `lsp/[server-name].lua`
3. Run `:Mason` in Neovim to install

### Dockerfile Changes

After modifying Dockerfile, rebuild using the build script:

```bash
# Auto-detects architecture (arm64/x86_64) and ripgrep variant
./docker_build.sh

# Override architecture if needed
ARCH=x86_64 ./docker_build.sh

# Override both if needed (advanced)
ARCH=arm64 RG_ARCH=aarch64 ./docker_build.sh

./nvim.sh
```

Architecture mapping:
- `ARCH=arm64` → `RG_ARCH=aarch64` (auto)
- `ARCH=x86_64` → `RG_ARCH=x86_64` (auto)

## Customization

### Environment

Create `~/.llm.env` for environment variables:

```bash
ANTHROPIC_API_KEY=your_key
OPENAI_API_KEY=your_key
```

### Git Config

Edit `~/.nvim-docker/.gitconfig` for container git settings.

### Volume Mounts

Default volumes are in `~/.nvim-docker/`:
- `share/nvim` - Plugins, Mason packages
- `state/nvim` - Swap files, undo history
- `rust/cargo-*` - Rust cargo cache

## Troubleshooting

### LSP Not Working

```vim
:LspInfo              " Check LSP status
:checkhealth          " Run diagnostics
```

### Plugin Issues

```vim
:Lazy update          " Update plugins
:Lazy clean           " Remove unused plugins
```

### Swift LSP Issues

```bash
# Check if server is running
lsof -Pi :9000 -sTCP:LISTEN

# View logs
tail -f ~/.nvim-docker/sourcekit-lsp.log
```

## Dependencies

### Host System

- Docker
- socat (for Swift LSP on macOS)
- xcode-build-server (for Xcode projects on macOS)

### Container

- Ubuntu 24.04
- Neovim (latest)
- Git, ripgrep, fd-find
- Python3, Rust toolchain
- Node.js (for some LSPs)

## License

See individual plugin licenses. This configuration is provided as-is.

## Contributing

This is a personal development environment. Feel free to fork and customize for your needs.
