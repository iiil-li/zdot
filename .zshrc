
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
export PATH="$PATH:/opt/nvim-linux64/bin"
export PATH=$PATH:~/.npm-global/bin
alias snvim='sudo env "PATH=$PATH" nvim -u $HOME/.config/nvim/init.lua'

#set zinit plugin dir

ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

export PATH=~/.npm-global/bin:$PATH

# download if needed

if [ ! -d "$ZINIT_HOME" ]; then
	mkdir -p "$(dirname $ZINIT_HOME)"
	git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

export PATH="$PATH:/opt/nvim-linux64/bin"

#source/load

source "${ZINIT_HOME}/zinit.zsh"
# Set the window title before a command is executed
preexec() {
  # Check if you're SSH-ed into a remote host
  if [[ -n "$SSH_CONNECTION" ]]; then
    local remote_user_host="$(whoami)@$HOST"
    print -Pn "\e]2;ssh $remote_user_host: $1\a"
  else
    # Locally, display the command without ssh prefix
    print -Pn "\e]2;$(whoami)@$HOST: $1\a"
  fi
}

# Reset the window title after the command is done (show current directory)
precmd() {
  # If you're in an SSH session, prepend SSH info and show current directory
  if [[ -n "$SSH_CONNECTION" ]]; then
    local remote_user_host="$(whoami)@$HOST"
    print -Pn "\e]2;ssh $remote_user_host: %~\a"
  else
    # Locally, display user@hostname and current directory
    print -Pn "\e]2;$(whoami)@$HOST: %~\a"
  fi
}
#add powerlevel10k, if requested

# Powerlevel10k configuration
if [ -d "$ZINIT_HOME" ]; then
    if [ -f ~/.p10k.zsh ]; then
        source ~/.p10k.zsh
    fi
    zinit ice depth=1; zinit light romkatv/powerlevel10k
fi


#add zsh plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions

#load complitions
autoload -U compinit && compinit

# history
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_find_no_dups

zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

alias ls='ls --color'
alias n="nvim"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

eval "$(fzf --zsh)"
# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

#key stuff
bindkey "^[[3~" delete-char
bindkey "^[[H" beginning-of-line
bindkey "^[[F" end-of-line
