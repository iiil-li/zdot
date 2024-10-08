#!/bin/bash

# Define an array of packages to install (one per line, excluding Neovim and fzf which we'll get from GitHub)
packages=(
    stow
    nnn
    ncdu
    tree
    htop
    rsync
    git  # Ensure git is installed to clone repositories
    curl # Ensure curl is installed to download scripts
    build-essential  # Needed to build Neovim from source
    unzip  # Required for fzf installation
)

# Function to install necessary packages (excluding Neovim and fzf)
install_packages() {
    echo "Installing required packages..."

    # Use sudo to install packages based on the OS
    if [ -f /etc/debian_version ]; then
        sudo apt-get update
        for package in "${packages[@]}"; do
            sudo apt-get install -y "$package"
        done
    elif [ -f /etc/arch-release ]; then
        sudo pacman -Syu --noconfirm "${packages[@]}"
    else
        echo "Unsupported OS. Please install packages manually."
    fi
}

# Install the latest version of Neovim from GitHub pre-built binaries
install_neovim() {
    echo "Installing Neovim from GitHub pre-built binaries..."

    # Download the latest release of Neovim (v0.9.2 stable as an example, but you can script the latest version dynamically)
    curl -LO https://github.com/neovim/neovim/releases/download/stable/nvim-linux64.tar.gz
    
    # Extract the tarball
    tar xzf nvim-linux64.tar.gz
    
    # Move the extracted files to /opt/nvim (or anywhere in your PATH)
    sudo mv nvim-linux64 /opt/nvim
    
    # Symlink the nvim binary to /usr/local/bin to make it globally accessible
    sudo ln -s /opt/nvim/bin/nvim /usr/local/bin/nvim
    
    # Clean up the downloaded tarball
    rm nvim-linux64.tar.gz

    echo "Neovim installation complete."
}

# Install fzf from GitHub
install_fzf() {
    echo "Installing fzf from GitHub..."
    
    # Clone the fzf repository
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    
    # Run the fzf install script
    ~/.fzf/install --all
}

# Main script execution
install_packages
install_neovim
install_fzf

# Function to install Powerlevel10k
install_powerlevel10k() {
    echo "Installing Powerlevel10k..."
    
    # Check if zinit is installed and install it if necessary
    ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
    if [ ! -d "$ZINIT_HOME" ]; then
        echo "Installing Zinit..."
        mkdir -p "$(dirname "$ZINIT_HOME")"
        git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
    fi
    
    # Add Perlevel10k to .zshrc
    echo "Adding Powerlevel10k configuration to .zshrc..."
    cat <<EOT >> ~/.zshrc

# Powerlevel10k configuration
if [ -d "\$ZINIT_HOME" ]; then
    source "\$ZINIT_HOME/zinit.zsh"
    zinit ice depth=1; zinit light romkatv/powerlevel10k
    [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
fi
EOT
    
    echo "Powerlevel10k installed. To configure, run 'p10k configure'."
}

# Proceed with Powerlevel10k installation if user selects "yes"
if [ "$install_p10k" = "yes" ]; then
    install_powerlevel10k
else
    echo "Skipping Powerlevel10k installation."
fi

# Prompt for Neovim LSPs to install via Mason and lsp-zero

install_nvim_lsps() {
    echo "Do you want to install Neovim LSPs? (yes/no)"
    read -r install_lsps

    if [ "$install_lsps" = "yes" ]; then
        echo "Available LSPs:"
        echo "1) lua_ls"
        echo "2) ts_ls"
        echo "3) gopls"
        echo "4) html"
        echo "5) cssls"
        echo "6) bashls"
        echo "7) pyright"
        echo "8) ansiblels"
        echo "Enter the numbers corresponding to the LSPs you want to install, separated by spaces (e.g., '1 3 5'):"
        read -r selected_lsps

        # Create an array of LSPs
        LSP_ARRAY=("lua_ls" "ts_ls" "gopls" "html" "cssls" "bashls" "pyright" "ansiblels")
        LSP_TO_INSTALL=()

        for number in $selected_lsps; do
            if [ $number -ge 1 ] && [ $number -le 8 ]; then
                LSP_TO_INSTALL+=("${LSP_ARRAY[$((number - 1))]}")
            fi
        done

        if [ ${#LSP_TO_INSTALL[@]} -eq 0 ]; then
            echo "No LSPs selected."
        else
            echo "Installing the selected LSPs: ${LSP_TO_INSTALL[*]}..."

            # Pass LSPs as a comma-separated list to Mason and install them
            nvim --headless -c "lua require('mason').setup(); require('mason-lspconfig').setup { ensure_installed = { '${LSP_TO_INSTALL[*]// /,}' } }" -c "q"

            echo "LSP installation complete."
        fi
    else
        echo "Skipping Neovim LSP installation."
    fi
}

# Main script execution
install_packages
install_nvim_lsps
stow .
echo "sourcing .zshrc"
chsh -s /bin/zsh
source $HOME/.zshrc
echo "Installation complete."

