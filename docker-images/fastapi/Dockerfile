# Optimized FastAPI Development Environment for Spinbox
# Pre-built image: gonzillaaa/spinbox-fastapi:latest
# Based on python:3.11-slim with common FastAPI development tools

FROM python:3.11-slim

WORKDIR /workspace

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    build-essential \
    zsh \
    && rm -rf /var/lib/apt/lists/*

# Install Oh My Zsh and Powerlevel10k
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended \
    && git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/custom/themes/powerlevel10k

# Configure Zsh
RUN sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/g' ~/.zshrc \
    && sed -i 's/plugins=(git)/plugins=(git docker docker-compose python pip)/g' ~/.zshrc \
    && echo 'POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true' >> ~/.zshrc

# Install UV for fast Python package management
RUN pip install --no-cache-dir uv

# Pre-install common FastAPI dependencies for faster project setup
RUN pip install --no-cache-dir \
    fastapi>=0.103.0 \
    uvicorn[standard]>=0.23.0 \
    sqlalchemy>=2.0.0 \
    alembic>=1.12.0 \
    psycopg2-binary>=2.9.7 \
    redis>=5.0.0 \
    pydantic>=2.4.0 \
    pydantic-settings>=2.0.0 \
    python-dotenv>=1.0.0 \
    httpx>=0.24.1 \
    pytest>=7.4.0 \
    pytest-asyncio>=0.21.0 \
    pytest-cov>=4.1.0 \
    black>=23.0.0 \
    isort>=5.12.0 \
    mypy>=1.5.0

# Set up virtual environment path
ENV PATH="/workspace/venv/bin:$PATH"

# Add development aliases
RUN echo '# Development aliases' >> ~/.zshrc \
    && echo 'alias rs="uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload"' >> ~/.zshrc \
    && echo 'alias test="pytest"' >> ~/.zshrc \
    && echo 'alias uvinstall="uv pip install -r requirements.txt"' >> ~/.zshrc \
    && echo 'alias migrate="alembic upgrade head"' >> ~/.zshrc \
    && echo 'alias format="black . && isort ."' >> ~/.zshrc \
    && echo 'alias lint="mypy . && black --check . && isort --check-only ."' >> ~/.zshrc

EXPOSE 8000

# Activate virtual environment on shell start
RUN echo 'if [[ -f /workspace/venv/bin/activate ]]; then source /workspace/venv/bin/activate; fi' >> ~/.zshrc

# Set Zsh as default shell
SHELL ["/bin/zsh", "-c"]

# Keep container running for development
CMD ["zsh", "-c", "while sleep 1000; do :; done"]

# Image metadata
LABEL maintainer="Spinbox CLI (gonzillaaa)" \
      description="Optimized FastAPI development environment for Spinbox projects" \
      version="1.0.0" \
      python.version="3.11" \
      fastapi.version="0.103.0+"