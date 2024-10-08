#!/bin/bash

# Define an array of packages to install (one per line)
packages=(
fzf
	zsh
	tmux
	stow
    nnn
    ncdu
    tree
    htop
    rsync
    neovim
)

# Check if sudo is installed
check_and_install_sudo() {
    if ! command -v sudo &> /dev/null; then
        echo "sudo is not installed. Attempting to install..."

        # Switch to root and install sudo
        echo "Please enter the root password to switch to root and install sudo."
        su -c 'if [ -f /etc/debian_version ]; then
                apt update && apt install -y sudo;
              elif [ -f /etc/arch-release ]; then
                pacman -Syu --noconfirm sudo;
              else
                echo "Unsupported OS. Please install sudo manually.";
                exit 1;
              fi'

        if ! command -v sudo &> /dev/null; then
            echo "Failed to install sudo. Exiting."
            exit 1
        fi
    fi

    # Check if the user is already in the sudoers file
    if ! sudo -l | grep -q "(ALL) ALL"; then
        echo "Adding $USER to the sudoers file..."
        
        # Directly append to /etc/sudoers (use visudo for safety in real usage)
        su -c "echo '$USER ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers"
        
        echo "$USER has been added to sudoers. Please log out and log back in to apply group changes."
        exit 0
    else
        echo "$USER is already in the sudoers file."
    fi
}

# Function to install necessary packages
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

# Prompt the user for Powerlevel10k installation
#!/bin/bash

# Prompt the user about installing Powerlevel10k
echo "Do you want to install Powerlevel10k (p10k) on this machine? (yes/no)"
read -r install_p10k

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
            
            # Ensure that mason and mason-lspconfig are installed and set up
            nvim --headless -c 'lua << EOF
                local mason_exists, mason = pcall(require, "mason")
                local mason_lsp_exists, mason_lspconfig = pcall(require, "mason-lspconfig")
                
                if mason_exists then
                    mason.setup()
                end
                
                if mason_lsp_exists then
                    mason_lspconfig.setup {
                        ensure_installed = { "'${LSP_TO_INSTALL[*]}'" }
                    }
                else
                    print("mason-lspconfig not installed. Please check your Neovim setup.")
                end
            EOF' -c "q"
            echo "LSP installation complete."
        fi
    else
        echo "Skipping Neovim LSP installation."
    fi
}


# Main script execution
install_packages
stow_configs
install_nvim_lsps
echo "sourcing .zshrc"
chsh -s /bin/zsh
source $HOME/.zshrc
echo "Installation complete."

