# Optimized Python Development Base for Spinbox
# Pre-built image: gonzillaaa/spinbox-python-base:latest
# Based on python:3.11-slim with essential development tools

FROM python:3.11-slim

# Install essential system dependencies and development tools
RUN apt-get update && apt-get install -y \
    git \
    curl \
    zsh \
    nano \
    tree \
    jq \
    iputils-ping \
    htop \
    && rm -rf /var/lib/apt/lists/*

# Install UV for fast Python package management
RUN pip install --no-cache-dir uv

# Install Oh My Zsh and Powerlevel10k
RUN sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended \
    && git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/custom/themes/powerlevel10k

# Set up Zsh configuration
RUN echo 'ZSH_THEME="powerlevel10k/powerlevel10k"' >> ~/.zshrc \
    && echo 'POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true' >> ~/.zshrc \
    && echo 'source ~/.oh-my-zsh/oh-my-zsh.sh' >> ~/.zshrc \
    && echo 'plugins=(git python pip)' >> ~/.zshrc

# Add essential development aliases
RUN echo '# Development aliases' >> ~/.zshrc \
    && echo 'alias ll="ls -la"' >> ~/.zshrc \
    && echo 'alias la="ls -A"' >> ~/.zshrc \
    && echo 'alias l="ls -CF"' >> ~/.zshrc \
    && echo 'alias ..="cd .."' >> ~/.zshrc \
    && echo 'alias ...="cd ../.."' >> ~/.zshrc \
    && echo 'alias cls="clear"' >> ~/.zshrc \
    && echo 'alias grep="grep --color=auto"' >> ~/.zshrc \
    && echo 'alias tree="tree -C"' >> ~/.zshrc

# Set Zsh as default shell
RUN chsh -s /bin/zsh
ENV SHELL=/bin/zsh

# Create workspace directory
WORKDIR /workspace

# Keep container running for development
CMD ["zsh", "-c", "while sleep 1000; do :; done"]

# Image metadata
LABEL maintainer="Spinbox CLI (gonzillaaa)" \
      description="Optimized Python development base for Spinbox projects" \
      version="2.0.0" \
      python.version="3.11" \
      approach="base+packagemanager"