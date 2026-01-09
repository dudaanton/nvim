#!/bin/bash
# Stop sourcekit-lsp TCP server

set -euo pipefail

SOURCEKIT_PORT=9000
SOURCEKIT_PID_FILE="$HOME/.nvim-docker/sourcekit-lsp.pid"

# Check if PID file exists
if [ -f "$SOURCEKIT_PID_FILE" ]; then
  PID=$(cat "$SOURCEKIT_PID_FILE")
  if ps -p "$PID" > /dev/null 2>&1; then
    echo "Stopping sourcekit-lsp server (PID: $PID)..."
    kill "$PID" 2>/dev/null || true
    sleep 1
  fi
  rm "$SOURCEKIT_PID_FILE"
fi

# Also find by process name (socat listening on TCP port)
PIDS=$(pgrep -f "socat.*TCP-LISTEN:$SOURCEKIT_PORT" 2>/dev/null || true)

if [ -n "$PIDS" ]; then
  echo "Stopping remaining socat processes on port $SOURCEKIT_PORT..."
  for PID in $PIDS; do
    echo "Killing process $PID"
    kill "$PID" 2>/dev/null || true
  done
fi

# Verify port is no longer in use
if lsof -Pi :$SOURCEKIT_PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
  echo "Warning: Port $SOURCEKIT_PORT still in use after stopping"
else
  echo "sourcekit-lsp server stopped (port $SOURCEKIT_PORT released)"
fi
