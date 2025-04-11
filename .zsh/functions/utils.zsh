autoload -Uz add-zsh-hook
autoload -Uz compinit && compinit
autoload -Uz compdef

# ===== System Utilities =====

function track-time() {
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

#------- Text Manipulation --------------
function grepipv6() {
  grep -Eo '(([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:))' "$@"
}

# autocompletion for gf
compdef _gf gf
function _gf {
  _arguments "1: :($(gf -list))"
}

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
