autoload -Uz add-zsh-hook
autoload -Uz compinit && compinit
autoload -Uz compdef

# ===== System Utilities =====

function track-time()
{
  local start_time=$(date +%s)
  echo "Press Enter to stop tracking..."
  read
  local end_time=$(date +%s)
  local duration=$((end_time - start_time))
  echo "Time spent: $(($duration / 60)) minutes and $(($duration % 60)) seconds"
}

function pipeEC() {
  echo ${pipestatus[@]}
}


# & run in background and disown !
function vlc_open(){
  set -m; {vlc $1 >& /dev/null } &!
}

function mpv_open(){
  set -m; {mpv $1 &! } >& /dev/null
}
# searching google using firefox

function searchG(){
  if ! command -v firefox-esr &> /dev/null ;then
    echo "Firefox is not insttaled on your system!"
    return 127
  fi
  [[ -z $1 ]] && {echo "Usage: $0 text you want to search " >&2; return 3}
  local query=${1// /+}

  set m; {firejail firefox-esr https://google.com/search\?q=$query &! } &>/dev/null
}

# use firefox-esr to set anything in background!

function firefox-e()
{
  if ! command -v firefox-esr &> /dev/null ;then
    echo "Firefox is not insttaled on your system!"
    return 127
  fi
  [[ -z $1 ]] && {echo "Usage: $0 text you want to search " >&2; return 3}

  set m; {firejail firefox-esr $1 &!} &>/dev/null
}


#------- Text Manipulation --------------
#
function note(){{mousepad >&/dev/null} &!}
zle -N note
bindkey '^N' note

function grepipv6() {
  grep -Eo '(([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:))' "$@"
}

function to_hex(){
  [[ -z $1 ]] && {echo "Usage: $0 string" >&2; return 3}
  printf "%s" "$1" | python -c 'import sys; print("0x"+str(sys.stdin.read().encode("utf-8").hex()).upper())'
}

function links_from_repo()
{
  {find .git/objects/pack -name "*.idx"|
    while read i;do git show-index< "$i"|
      awk '{print $2}';
    done
    find .git/objects/ -type f |
      grep -v '/pack/'|
      awk -F '/' '{print $(NF-1)$NF}';
    } | while read o; do git cat-file -p $o
  done | greplinks| grep -e '^http'
}

# autocompletion for gf
#compdef _gf gf
#function _gf {
#  _arguments "1: :($(gf -list))"
#}


# for virtualenvwrapper
function _defer_initialization() {
  # Load virtualenvwrapper only when needed
  if [[ -f $HOME/.local/bin/virtualenvwrapper.sh ]]; then
    export WORKON_HOME=$HOME/.PythonVirtualEnvs
    [[ ! -d $WORKON_HOME ]] && mkdir -p $WORKON_HOME
    export VIRTUALENVWRAPPER_PYTHON=$(which python3.13)
    source $HOME/.local/bin/virtualenvwrapper.sh
  fi

  # Remove this hook after it runs once
  add-zsh-hook -d precmd _defer_initialization
}
add-zsh-hook precmd _defer_initialization
