#!/bin/bash

# Install necessary packages
install_packages() {
    echo "Installing required packages..."
    
    # Detect OS and install packages
    if [ -f /etc/debian_version ]; then
        # Debian/Ubuntu
        sudo apt-get update
        sudo apt-get install -y zsh sudo git stow nnn ncdu tree htop rsync neovim
    elif [ -f /etc/arch-release ]; then
        # Arch Linux
        sudo pacman -Syu --noconfirm stow nnn ncdu tree htop rsync neovim
    else
        echo "Unsupported OS. Please install packages manually."
    fi
}

# Stow the configurations
stow_configs() {
    echo "Stowing configurations..."
    stow -t ~ common
    echo "Stowing complete."
}

# Prompt the user for Powerlevel10k installation
install_powerlevel10k() {
    echo "Do you want to install Powerlevel10k (p10k) on this machine? (yes/no)"
    read -r install_p10k

    if [ "$install_p10k" = "yes" ]; then
        echo "Installing Powerlevel10k..."
        
        # Check if zinit is installed and install it if necessary
        ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
        if [ ! -d "$ZINIT_HOME" ]; then
            echo "Installing Zinit..."
            mkdir -p "$(dirname "$ZINIT_HOME")"
            git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
        fi
        
        # Add Powerlevel10k to .zshrc
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
    else
        echo "Skipping Powerlevel10k installation."
    fi
}

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
            
            # Install the selected LSPs using Mason and lsp-zero
            nvim --headless -c "lua require('mason-lspconfig').setup({ ensure_installed = { '${LSP_TO_INSTALL[*]}' } })" -c "q"
            echo "LSP installation complete."
        fi
    else
        echo "Skipping Neovim LSP installation."
    fi
}

# Main script execution
install_packages
stow_configs
install_powerlevel10k
install_nvim_lsps

echo "Installation complete."

