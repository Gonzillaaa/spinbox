# Optimized Python Development Environment for Spinbox
# Pre-built image: gonzillaaa/spinbox-python-dev:latest
# Based on python:3.11-slim with essential Python development tools

FROM python:3.11-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    build-essential \
    zsh \
    && rm -rf /var/lib/apt/lists/*

# Install UV for fast Python package management
RUN pip install --no-cache-dir uv

# Install Oh My Zsh and Powerlevel10k
RUN sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended \
    && git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/custom/themes/powerlevel10k

# Pre-install common Python development tools
RUN pip install --no-cache-dir \
    pytest>=7.4.0 \
    pytest-cov>=4.1.0 \
    black>=23.0.0 \
    isort>=5.12.0 \
    mypy>=1.5.0 \
    python-dotenv>=1.0.0 \
    requests>=2.31.0 \
    ipython>=8.0.0 \
    notebook>=7.0.0

# Set up Zsh configuration
RUN echo 'ZSH_THEME="powerlevel10k/powerlevel10k"' >> ~/.zshrc \
    && echo 'POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true' >> ~/.zshrc \
    && echo 'source ~/.oh-my-zsh/oh-my-zsh.sh' >> ~/.zshrc \
    && echo 'plugins=(git python pip)' >> ~/.zshrc

# Add development aliases
RUN echo '# Development aliases' >> ~/.zshrc \
    && echo 'alias test="pytest"' >> ~/.zshrc \
    && echo 'alias format="black . && isort ."' >> ~/.zshrc \
    && echo 'alias lint="mypy . && black --check . && isort --check-only ."' >> ~/.zshrc \
    && echo 'alias venv="python -m venv venv && source venv/bin/activate"' >> ~/.zshrc \
    && echo 'alias activate="source venv/bin/activate"' >> ~/.zshrc \
    && echo 'alias uvinstall="uv pip install -r requirements.txt"' >> ~/.zshrc

# Set Zsh as default shell
RUN chsh -s /bin/zsh
ENV SHELL=/bin/zsh

# Create workspace directory
WORKDIR /workspace

# Keep container running for development
CMD ["zsh", "-c", "while sleep 1000; do :; done"]

# Image metadata
LABEL maintainer="Spinbox CLI (gonzillaaa)" \
      description="Optimized Python development environment for Spinbox projects" \
      version="1.0.0" \
      python.version="3.11"