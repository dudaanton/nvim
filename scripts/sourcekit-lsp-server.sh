#!/bin/bash
# Remote sourcekit-lsp TCP server for Docker container
# Runs on macOS host, listens on TCP port 9000
#
# Security note: Binds to 0.0.0.0 (not 127.0.0.1) for Docker Desktop connectivity.
# This is required because host.docker.internal cannot reach 127.0.0.1 services.
# While this exposes the port to localhost and local network, LSP protocol itself
# limits operations to reading source code - no shell execution or file writes.

set -euo pipefail

PORT="${SOURCEKIT_LSP_PORT:-9000}"
SOURCEKIT_LSP="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/sourcekit-lsp"

# Check if sourcekit-lsp exists
if [ ! -x "$SOURCEKIT_LSP" ]; then
  echo "Error: sourcekit-lsp not found at $SOURCEKIT_LSP" >&2
  echo "Please ensure Xcode is installed" >&2
  exit 1
fi

# Check if socat is available
if ! command -v socat &> /dev/null; then
  echo "Error: socat is required but not installed" >&2
  echo "Install with: brew install socat" >&2
  exit 1
fi

# Check if port is already in use
if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
  echo "sourcekit-lsp server already running on port $PORT"
  exit 0
fi

echo "Starting sourcekit-lsp TCP server..."
echo "sourcekit-lsp: $SOURCEKIT_LSP"
echo "Listening: 0.0.0.0:$PORT (accessible from Docker via host.docker.internal)"
echo ""
echo "Security notes:"
echo "  - Accessible from: localhost, local network, Docker containers"
echo "  - LSP protocol: Read-only access to source code"
echo "  - No shell execution or direct file writes through LSP"
echo "  - Vulnerable to: Browser-based JavaScript attacks on localhost"
echo ""
echo "Press Ctrl+C to stop"
echo ""

# Start socat with TCP server
# IMPORTANT: bind=0.0.0.0 is required for host.docker.internal to connect
# Using 127.0.0.1 will cause "Connection refused" from Docker
# NOTE: DO NOT use 'pty' option - it causes echo which breaks LSP JSON-RPC protocol
exec socat -v \
  "TCP-LISTEN:$PORT,bind=0.0.0.0,reuseaddr,fork" \
  "EXEC:$SOURCEKIT_LSP,stderr"
