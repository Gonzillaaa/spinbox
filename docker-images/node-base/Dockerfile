# Optimized Node.js Development Base for Spinbox
# Pre-built image: gonzillaaa/spinbox-node-base:latest
# Based on node:20-alpine with essential development tools

FROM node:20-alpine

WORKDIR /app

# Install essential system dependencies and development tools
RUN apk add --no-cache \
    git \
    zsh \
    curl \
    shadow \
    util-linux \
    nano \
    tree \
    jq \
    htop

# Install Oh My Zsh and Powerlevel10k
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended \
    && git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/custom/themes/powerlevel10k

# Install useful Zsh plugins
RUN git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions \
    && git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting

# Configure Zsh
RUN sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/g' ~/.zshrc \
    && sed -i 's/plugins=(git)/plugins=(git docker npm node zsh-autosuggestions zsh-syntax-highlighting)/g' ~/.zshrc \
    && echo 'POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true' >> ~/.zshrc

# Add essential development aliases
RUN echo '# Development aliases' >> ~/.zshrc \
    && echo 'alias ll="ls -la"' >> ~/.zshrc \
    && echo 'alias la="ls -A"' >> ~/.zshrc \
    && echo 'alias l="ls -CF"' >> ~/.zshrc \
    && echo 'alias ..="cd .."' >> ~/.zshrc \
    && echo 'alias ...="cd ../.."' >> ~/.zshrc \
    && echo 'alias cls="clear"' >> ~/.zshrc \
    && echo 'alias tree="tree -C"' >> ~/.zshrc \
    && echo 'alias install-deps="npm install"' >> ~/.zshrc

EXPOSE 3000

# Set Zsh as default shell
SHELL ["/bin/zsh", "-c"]

# Keep container running for development
CMD ["zsh", "-c", "while sleep 1000; do :; done"]

# Image metadata
LABEL maintainer="Spinbox CLI (gonzillaaa)" \
      description="Optimized Node.js development base for Spinbox projects" \
      version="2.0.0" \
      node.version="20" \
      approach="base+packagemanager"