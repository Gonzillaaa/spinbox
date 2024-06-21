#!/bin/bash

# Update and upgrade system
sudo apt-get update
sudo apt-get upgrade -y

# Install nodejs
curl -sL https://deb.nodesource.com/setup_20.x | sudo bash -
sudo apt-get install nodejs

# Install zsh
sudo apt-get install -y zsh

# Set zsh as the default shell
# chsh -s $(which zsh)
sudo usermod -s /bin/zsh $USER

# Create .zshrc and .zprofile
touch ~/.zshrc
touch ~/.zprofile

# Install zinit
bash -c "$(curl --fail --show-error --silent --location https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh)"

# Add zinit plugins to .zshrc
cat <<EOF >>~/.zshrc
# zsh packages
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-history-substring-search
zinit light zdharma-continuum/fast-syntax-highlighting

# Oh My Zsh features
zinit snippet OMZ::lib/completion.zsh
zinit snippet OMZ::lib/history.zsh
zinit snippet OMZ::lib/key-bindings.zsh
zinit snippet OMZ::lib/theme-and-appearance.zsh

# Key binding
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
bindkey ',' autosuggest-accept

# Others
zinit load djui/alias-tips

# Powerlevel10k theme
zinit ice depth=1; zinit light romkatv/powerlevel10k
EOF

# Install dependencies for pyenv
sudo apt-get install -y --no-install-recommends make build-essential libssl-dev zlib1g-dev libbz2-dev \
libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev \
libffi-dev liblzma-dev

# Install pyenv
git clone https://github.com/pyenv/pyenv.git ~/.pyenv

# Add pyenv to .zshrc
echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.zshrc
echo 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.zshrc
echo 'eval "$(pyenv init -)"' >> ~/.zshrc

# Install Poetry
curl -sSL https://install.python-poetry.org | python3 -

# Add Poetry to PATH in .zshrc
echo 'export PATH="$PATH:$HOME/.local/bin"' >> ~/.zshrc

# Set Poetry to create virtual environments inside projects
poetry config virtualenvs.in-project true

# Source .zshrc to apply changes
source ~/.zshrc

echo "Setup complete! Please restart your shell for all changes to take effect."