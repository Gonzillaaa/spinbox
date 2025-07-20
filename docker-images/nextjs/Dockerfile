# Optimized Next.js Development Environment for Spinbox
# Pre-built image: gonzillaaa/spinbox-nextjs:latest
# Based on node:20-alpine with common Next.js development tools

FROM node:20-alpine

WORKDIR /app

# Install system dependencies including Zsh
RUN apk add --no-cache \
    git \
    zsh \
    curl \
    shadow \
    util-linux

# Install Oh My Zsh and Powerlevel10k
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended \
    && git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/custom/themes/powerlevel10k

# Install Zsh plugins
RUN git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions \
    && git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting

# Configure Zsh
RUN sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/g' ~/.zshrc \
    && sed -i 's/plugins=(git)/plugins=(git docker npm node zsh-autosuggestions zsh-syntax-highlighting)/g' ~/.zshrc \
    && echo 'POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true' >> ~/.zshrc

# Pre-install common Next.js dependencies for faster project setup
RUN npm install -g \
    next@latest \
    react@latest \
    react-dom@latest \
    typescript@latest \
    @types/node@latest \
    @types/react@latest \
    @types/react-dom@latest \
    eslint@latest \
    eslint-config-next@latest \
    tailwindcss@latest \
    autoprefixer@latest \
    postcss@latest \
    axios@latest

# Add development aliases
RUN echo '# Development aliases' >> ~/.zshrc \
    && echo 'alias dev="npm run dev"' >> ~/.zshrc \
    && echo 'alias build="npm run build"' >> ~/.zshrc \
    && echo 'alias lint="npm run lint"' >> ~/.zshrc \
    && echo 'alias test="npm test"' >> ~/.zshrc \
    && echo 'alias format="npm run format"' >> ~/.zshrc \
    && echo 'alias install-deps="npm install"' >> ~/.zshrc

EXPOSE 3000

# Set Zsh as default shell
SHELL ["/bin/zsh", "-c"]

# Keep container running for development
CMD ["zsh", "-c", "while sleep 1000; do :; done"]

# Image metadata
LABEL maintainer="Spinbox CLI (gonzillaaa)" \
      description="Optimized Next.js development environment for Spinbox projects" \
      version="1.0.0" \
      node.version="20" \
      nextjs.version="latest"