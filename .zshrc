# ~/.zshrc file for zsh interactive shells.
# see /usr/share/doc/zsh/examples/zshrc for examples

# ===== Load ZSH Plugins FIRST =====
# Load async plugin if exists



if [[ ! -f ~/.zsh/plugins/async/async.zsh ]]; then
  curl -s -# -o ~/.zsh/plugins/async/async.zsh  https://raw.githubusercontent.com/mafredri/zsh-async/master/async.zsh
  source ~/.zsh/plugins/async/async.zsh
  async_init
else
  source ~/.zsh/plugins/async/async.zsh
  async_init
fi

# Load zsh hooks if not already loaded
autoload -Uz add-zsh-hook

# enable auto-suggestions based on the history
if [ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
  source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
  # change suggestion color
  ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#999'
fi

# enable command-not-found if installed
if [ -f /etc/zsh_command_not_found ]; then
  source /etc/zsh_command_not_found
fi

[[ -f ~/.zsh/prompt/prompt.zsh ]] && source ~/.zsh/prompt/prompt.zsh

# Load all functions
for file in ~/.zsh/functions/*.zsh; do
  [ -f "$file" ] && source "$file"
done

[[ -f ~/.zsh/aliases/aliases.zsh ]] && source ~/.zsh/aliases/aliases.zsh

setopt autocd              # change directory just by typing its name
#setopt correct            # auto correct mistakes
setopt interactivecomments # allow comments in interactive mode
setopt magicequalsubst     # enable filename expansion for arguments of the form ‘anything=expression’
setopt nonomatch           # hide error message if there is no match for the pattern
setopt notify              # report the status of background jobs immediately
setopt numericglobsort     # sort filenames numerically when it makes sense
setopt promptsubst         # enable command substitution in prompt

setopt EXTENDED_HISTORY        # Add timestamp and duration
setopt HIST_EXPIRE_DUPS_FIRST  # Expire duplicates first
setopt HIST_IGNORE_DUPS        # Don't store duplicates
setopt HIST_IGNORE_SPACE       # Ignore commands starting with space
setopt HIST_VERIFY             # Show before executing history expansions
setopt SHARE_HISTORY           # Share history between sessions
setopt HIST_FCNTL_LOCK         # Better locking mechanism

WORDCHARS=${WORDCHARS//\/} # Don't consider certain characters part of the word

# hide EOL sign ('%')
PROMPT_EOL_MARK=""

# configure key keybindings

# Enable better word selection
autoload -Uz select-word-style
select-word-style bash

# Visual selection tracking
function zle-keymap-select {
  if [[ $KEYMAP == vicmd ]] || [[ $WIDGET == *select* ]]; then
    echo -ne '\e[2 q'  # block cursor
  else
    echo -ne '\e[4 q'  # underline cursor
  fi
}
zle -N zle-keymap-select

# Selection functions
start-selection() {
  zle set-mark-command
  zle -K vicmd
}

end-selection() {
  zle -K main
}

copy-selection() {
  local save_reg=$REGION_ACTIVE
  REGION_ACTIVE=1
  zle copy-region-as-kill
  print -rn -- $CUTBUFFER | xclip -selection clipboard -in 2>/dev/null
  REGION_ACTIVE=$save_reg
  zle end-selection
  zle reset-prompt
}
zle -N copy-selection
zle -N start-selection
zle -N end-selection

# Bind keys (ADAPT THESE TO YOUR QTERMINAL'S ACTUAL SEQUENCES)
bindkey -e  # use emacs keymap as base

# Shift+Arrow - character selection
bindkey -M emacs '^[[1;2A' start-selection      # Shift+Up
bindkey -M emacs '^[[1;2B' start-selection      # Shift+Down
bindkey -M emacs '^[[1;2C' start-selection      # Shift+Right
bindkey -M emacs '^[[1;2D' start-selection      # Shift+Left

# Ctrl+Shift+Arrow - word selection
bindkey -M emacs '^[[1;6A' vi-backward-blank-word
bindkey -M emacs '^[[1;6B' vi-forward-blank-word
bindkey -M emacs '^[[1;6C' vi-forward-blank-word
bindkey -M emacs '^[[1;6D' vi-backward-blank-word

# Ctrl+Shift+C to copy
bindkey -M emacs '^[[1;6C' copy-selection  # Verify actual sequence!

# Exit selection mode on normal keys
bindkey -M vicmd ' ' end-selection

bindkey -e
bindkey ' ' magic-space                           # do history expansion on space
bindkey '^U' backward-kill-line                   # ctrl + U
bindkey '^[[3;5~' kill-word                       # ctrl + Supr
bindkey '^[[3~' delete-char                       # delete
bindkey '^[[1;5C' forward-word                    # ctrl + ->
bindkey '^[[1;5D' backward-word                   # ctrl + <-
bindkey '^[[5~' beginning-of-buffer-or-history    # page up
bindkey '^[[6~' end-of-buffer-or-history          # page down
bindkey '^[[H' beginning-of-line                  # home
bindkey '^[[F' end-of-line                        # end
bindkey '^[[Z' undo                               # shift + tab undo last action


# enable completion features

autoload -Uz compinit


() {  # Anonymous function for local scope
local zcd=${ZDOTDIR:-$HOME}/.zcompdump
local zcdc="$zcd.zwc"

  # Compile if needed or if older than 24 hours
  if [[ -f "$zcd"(#qN.m+1) ]]; then
    compinit -i -d "$zcd"
    { rm -f "$zcdc" && zcompile "$zcd" } &!
    else
      compinit -C -d "$zcd"
  fi
}
# Add to fpath BEFORE compinit
fpath=( ~/.zsh/functions $fpath )

autoload -Uz _gf  # Loads the '_gf' function from '_gfau' file
compdef _gf gf     # Map it to 'gf' command

zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.cache/zsh/zcompcache
zstyle ':completion:*:*:*:*:*' menu select
zstyle ':completion:*' auto-description 'specify: %d'
zstyle ':completion:*' completer _expand _complete
zstyle ':completion:*' format 'Completing %d'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' list-colors ''
zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' rehash true
zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
zstyle ':completion:*' use-compctl false
zstyle ':completion:*' verbose true
zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'

# History configurations
HISTFILE=~/.zsh_history
HISTSIZE=2000000
SAVEHIST=2000000

# configure `time` format
TIMEFMT=$'\nreal\t%E\nuser\t%U\nsys\t%S\ncpu\t%P'

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# enable color support of ls, less and man, and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
  test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
  export LS_COLORS="$LS_COLORS:ow=30;44:" # fix ls color for folders with 777 permissions

  [[ -f ~/.zsh/aliases/auto_color_aliases.zsh ]] && source ~/.zsh/aliases/auto_color_aliases.zsh

  export LESS_TERMCAP_mb=$'\E[1;31m'     # begin blink
  export LESS_TERMCAP_md=$'\E[1;36m'     # begin bold
  export LESS_TERMCAP_me=$'\E[0m'        # reset bold/blink
  export LESS_TERMCAP_so=$'\E[01;33m'    # begin reverse video
  export LESS_TERMCAP_se=$'\E[0m'        # reset reverse video
  export LESS_TERMCAP_us=$'\E[1;32m'     # begin underline
  export LESS_TERMCAP_ue=$'\E[0m'        # reset underline

  # Take advantage of $LS_COLORS for completion as well
  zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
  zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'

fi


### Exports (for env) ###
# Default editor
export EDITOR='/usr/local/bin/vim'
export VISUAL='/usr/local/bin/vim'

# Path to .local/bin to for excecuting my own scripts
export PATH=$PATH:$HOME/.local/bin
export PATH=$PATH:$HOME/.cargo/bin
export PATH=$PATH:$HOME/go/bin

typeset -U PATH

export REAL_NAME="Arshia Mashhoor"


# storing some common viseted paths as alias using absoulte not reletive paths
export src=$HOME/Documents/programming/source_codes
export c_src=$HOME/Documents/programming/source_codes/2-c
export web_src=$HOME/Documents/programming/source_codes/7-web-applications
export py_src=$HOME/Documents/programming/source_codes/3-python
export shell_src=$HOME/Documents/programming/source_codes/8-shell-scripting
export go_src=$HOME/Documents/programming/source_codes/9-Golang
export bug_bunt_targets=$HOME/Documents/penetration_testing/bug_bounty-hunting/targets/web_applications
export pen_test=$HOME/Documents/penetration_testing
export payloads=$HOME/Documents/penetration_testing/payloads

