# ==============================================================================
# Neovim Docker Development Environment
# Ubuntu 24.04 with Neovim, LSP, Python, Rust, Node.js
# ==============================================================================
FROM ubuntu:24.04

LABEL description="Fully-configured Neovim development environment with multi-language support"
LABEL version="1.0"

# ==============================================================================
# Build Arguments
# ==============================================================================
ARG ARCH
ARG RG_ARCH
ARG HOST_UID=1001
ARG HOST_GID=1001

# ==============================================================================
# Environment Variables - System
# ==============================================================================
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    TERM=screen-256color \
    TMPDIR=/tmp

# ==============================================================================
# System Packages & Tools
# ==============================================================================
RUN apt-get update && \
  apt-get install -y \
    # Version control
    git \
    # Download tools
    curl \
    wget \
    # Build tools
    build-essential \
    # Python
    python3 \
    python3-pip \
    python3.12-venv \
    # Utilities
    unzip \
    socat \
    locales \
    fd-find \
    jq \
    # Development libraries
    gnupg2 \
    libcurl4-openssl-dev \
    libxml2-dev \
    libncurses-dev \
    libz3-dev \
    pkg-config \
  && apt-get -y autoclean \
  && rm -rf /var/lib/apt/lists/* \
  # Use bash as default shell
  && rm /bin/sh && ln -s /bin/bash /bin/sh \
  # Generate locales
  && locale-gen en_US.UTF-8

# ==============================================================================
# CLI Tools - FZF & Ripgrep
# ==============================================================================

# FZF - Fuzzy finder
ENV FZF_VERSION=0.66.0
RUN wget -O fzf.tar.gz \
    "https://github.com/junegunn/fzf/releases/download/v${FZF_VERSION}/fzf-${FZF_VERSION}-linux_${ARCH}.tar.gz" \
  && tar xf fzf.tar.gz fzf \
  && mv fzf /usr/local/bin/ \
  && rm -rf fzf*

# Ripgrep - Fast grep alternative
ENV RIPGREP_VERSION=14.1.1
RUN LIBC_TYPE=$( [ "${RG_ARCH}" = "x86_64" ] && echo "musl" || echo "gnu" ) \
  && wget -O rg.tar.gz \
    "https://github.com/BurntSushi/ripgrep/releases/download/${RIPGREP_VERSION}/ripgrep-${RIPGREP_VERSION}-${RG_ARCH}-unknown-linux-${LIBC_TYPE}.tar.gz" \
  && tar xf rg.tar.gz \
  && mv ripgrep-${RIPGREP_VERSION}-${RG_ARCH}-unknown-linux-${LIBC_TYPE}/rg /usr/local/bin/ \
  && rm -rf ripgrep-${RIPGREP_VERSION}-${RG_ARCH}-unknown-linux-${LIBC_TYPE} rg.tar.gz

# ==============================================================================
# Node.js via NVM
# ==============================================================================
ENV NVM_VERSION=0.40.3 \
    NODE_VERSION=22.21.0 \
    NVM_DIR=/usr/local/nvm

RUN mkdir -p ${NVM_DIR} \
  && curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_VERSION}/install.sh" | bash \
  && . $NVM_DIR/nvm.sh \
  && nvm install $NODE_VERSION \
  && nvm alias default $NODE_VERSION \
  && nvm use default

ENV NODE_PATH="$NVM_DIR/v$NODE_VERSION/lib/node_modules" \
    PATH="$NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH"

# ==============================================================================
# Neovim (Latest)
# ==============================================================================
RUN curl -sSL -o /tmp/nvim.tar.gz \
    "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-$([ "$ARCH" = "arm64" ] && echo "arm64" || echo "x86_64").tar.gz" \
  && rm -rf /opt/nvim \
  && tar -C /opt -xzf /tmp/nvim.tar.gz \
  && rm /tmp/nvim.tar.gz

ENV PATH="/opt/nvim-linux-${ARCH}/bin:$PATH"

# ==============================================================================
# Development Tools
# ==============================================================================

# Lazygit - Terminal UI for git
ENV LAZYGIT_VERSION=0.58.0
RUN wget -O lazygit.tar.gz \
    "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_$([ "$ARCH" = "arm64" ] && echo "arm64" || echo "x86_64").tar.gz" \
  && tar xf lazygit.tar.gz lazygit \
  && install lazygit /usr/local/bin \
  && rm -rf lazygit.tar.gz lazygit

# UV - Python package installer (faster pip alternative)
ENV UV_VERSION=0.9.22
RUN curl -LsSf "https://astral.sh/uv/${UV_VERSION}/install.sh" | sh \
  && mv /root/.local/bin/uv /usr/local/bin/uv

# ==============================================================================
# User Setup
# ==============================================================================
RUN groupadd -g ${HOST_GID} dev \
  && useradd -u ${HOST_UID} -g dev -s /bin/bash -m dev \
  && mkdir -p /home/dev/{.local/share,.local/state,.config}

WORKDIR /app
USER dev

# ==============================================================================
# Rust Toolchain (as user)
# ==============================================================================
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y \
  && . "$HOME/.cargo/env" \
  && rustup component add rust-analyzer

# ==============================================================================
# Environment Variables - User Paths
# ==============================================================================
ENV PATH="/home/dev/.cargo/bin:/home/dev/.local/bin:/home/dev/.local/share/swiftly/bin:${PATH}"

# ==============================================================================
# User Configuration
# ==============================================================================
COPY --chown=dev:dev ./.bashrc /home/dev/.bashrc

# ==============================================================================
# Node.js Global Packages
# ==============================================================================
RUN npm install -g --no-cache \
  @anthropic-ai/claude-code \
  @zed-industries/claude-code-acp \
  repomix \
  mcp-hub@latest \
  pnpm \
  prettier

# ==============================================================================
# Container Entry Point
# ==============================================================================
CMD ["nvim"]
