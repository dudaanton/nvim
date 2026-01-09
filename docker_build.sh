#!/bin/bash

# Auto-detect ARCH if not set by user
if [ -z "$ARCH" ]; then
  DETECTED_ARCH=$(uname -m)
  # Normalize architecture names
  case "$DETECTED_ARCH" in
    aarch64)
      ARCH="arm64"
      ;;
    x86_64)
      ARCH="x86_64"
      ;;
    i386|i686)
      ARCH="x86_64"
      ;;
    *)
      echo "Warning: Unknown architecture $DETECTED_ARCH, defaulting to x86_64"
      ARCH="x86_64"
      ;;
  esac
  echo "Auto-detected ARCH: $ARCH"
else
  echo "Using user-provided ARCH: $ARCH"
fi

# Auto-detect RG_ARCH from ARCH if not set by user
if [ -z "$RG_ARCH" ]; then
  case "$ARCH" in
    arm64)
      RG_ARCH="aarch64"
      ;;
    x86_64)
      RG_ARCH="x86_64"
      ;;
    *)
      echo "Warning: Unknown ARCH $ARCH for RG_ARCH mapping, defaulting to x86_64"
      RG_ARCH="x86_64"
      ;;
  esac
  echo "Auto-detected RG_ARCH: $RG_ARCH"
else
  echo "Using user-provided RG_ARCH: $RG_ARCH"
fi

docker build \
  --build-arg ARCH="$ARCH" \
  --build-arg RG_ARCH="$RG_ARCH" \
  -t nvim-main .
