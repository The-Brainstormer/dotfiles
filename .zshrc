[ -f /etc/profile.d/ona-secrets.sh ] && source /etc/profile.d/ona-secrets.sh
export CLAUDE_CODE_OAUTH_TOKEN="${CLAUDE_CODE_OAUTH_TOKEN:-$DEV_CLAUDE_CODE_OAUTH_TOKEN}"

export ZSH="${HOME}/.oh-my-zsh"

# theme
ZSH_THEME="linuxonly"

# aliases
source $ZSH/oh-my-zsh.sh
source $HOME/.aliases
