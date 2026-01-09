#!/bin/bash

docker build \
  --build-arg ARCH=$(arch) \
  --build-arg RG_ARCH=aarch64 \
  -t nvim-main .
