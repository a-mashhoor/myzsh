
#================ Prompt Components ====================

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
  debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
  xterm-color|*-256color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
  if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
    # We have color support; assume it's compliant with Ecma-48
    # (ISO/IEC-6429). (Lack of such support is extremely rare, and such
    # a case would tend to support setf rather than setaf.)
    color_prompt=yes
  else
    color_prompt=
  fi
fi

# ===== System Monitoring Functions =====
function ram_usage() {
  # Read memory info in a single operation
  local meminfo=(${(f)"$(</proc/meminfo)"})

  # Extract values (remove units and convert to integers)
  local total=${${meminfo[(r)MemTotal:*]}#MemTotal:}
  total=${total% kB}
  local free=${${meminfo[(r)MemFree:*]}#MemFree:}
  free=${free% kB}
  local buffers=${${meminfo[(r)Buffers:*]}#Buffers:}
  buffers=${buffers% kB}
  local cached=${${meminfo[(r)Cached:*]}#Cached:}
  cached=${cached% kB}

  # Calculate usage
  local used=$((total - free - buffers - cached))
  local available=$((free + cached))  # Actual free memory available
  local percent=$((total ? (used * 100) / total : 0))
  local available_mb=$((available / 1024))  # Convert to MB

  # Color coding based on usage percentage
  if (( percent > 90 )); then
    echo "%F{red}${percent}%%%f(%F{cyan}free:${available_mb}M%f)"
  elif (( percent > 75 )); then
    echo "%F{yellow}${percent}%%%f(%F{cyan}free:${available_mb}M%f)"
  else
    echo "%F{green}${percent}%%%f(%F{cyan}free:${available_mb}M%f)"
  fi
}

function cpu_temp() {
  if command -v sensors &> /dev/null; then
    local temp=$(sensors | awk '/Package id 0:/ {print $4; exit}')
    temp=${temp//[^0-9.]/}

    if (( ${temp%.*} > 85 )); then
      echo "%F{red}CPU:${temp}°C%f"
    elif (( ${temp%.*} > 70 )); then
      echo "%F{yellow}CPU:${temp}°C%f"
    else
      echo "%F{green}CPU:${temp}°C%f"
    fi
  fi
}

function handling_exit_code() {
  local msg
  case $1 in
    2)    msg="? $1 Buit-in :(";;
    130)  msg="✘ $1 SIGINT :(" ;;
    127)  msg="⌁ $1 CMD NF :(" ;;
    100)  msg="! $1 problem :(" ;;
    126)  msg="⛔$1 Perms :(" ;;
    137)  msg="☠ $1 SIGKILL :(" ;;
    139)  msg="💥$1 SegFault :(" ;;
    143)  msg="⚰ $1 SIGTERM :(" ;;
    255)  msg="↑ $1 INVALID :(";;
    *)    msg="Fucked Up:$1 :'(" ;;
  esac
  echo "%F{red}$msg%f"
}

function date_display() {
  local datestr=$(date "+[%Y/%m(%B)/%d %a (%T)]")
  echo "%F{blue}${datestr}%f"
}

function virtualenv_display() {
  if [[ -n $VIRTUAL_ENV ]]; then
    echo "%F{magenta}($(basename $VIRTUAL_ENV))%f"
  fi
}

function debian_chroot_display() {
  if [[ -n $debian_chroot ]]; then
    echo "%F{cyan}(${debian_chroot})%f"
  fi
}


# ===== Load Async Library =====
autoload -Uz async && async

# ===== Async Git Prompt Setup =====
function _git_prompt_worker() {
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    return
  fi

  local git_status=$(git status --porcelain -b 2>/dev/null)
  local branch=${${git_status[(f)1]}[(w)2]##}
  [[ -z $branch ]] && branch=$(git rev-parse --short HEAD 2>/dev/null)

  local repo_name=$(basename "$(git rev-parse --show-toplevel 2>/dev/null)")

  # Parse changes
  local ahead=0 behind=0 untracked=0 not_staged=0
  while IFS= read -r line; do
    case $line in
      \#\#*)
        [[ $line =~ 'ahead ([0-9]+)' ]] && ahead=$match[1]
              [[ $line =~ 'behind ([0-9]+)' ]] && behind=$match[1]
              ;;
            \?\?*) ((untracked++)) ;;
            *) ((not_staged++)) ;;
          esac
        done <<< "$git_status"

  # Build output
  local output="%F{green}R:$repo_name%f %F{blue}B:($branch)%f"
  if ((ahead || behind)); then
    output+=" %F{yellow}["
    ((ahead)) && output+="↑$ahead"
    ((behind)) && output+="↓$behind"
    output+="]%f"
  fi
  if ((not_staged)); then
    output+=" %F{red}{NS:$not_staged}%f"
  fi
  if ((untracked)); then
    output+=" %F{magenta}{U:$untracked}%f"
  fi

  echo -n "($output)"
}

# Track current Git repo state
typeset -g _GIT_PROMPT_REPO_ROOT=""
typeset -g _GIT_PROMPT_INFO=""
typeset -g _GIT_PROMPT_LAST_DIR=""
typeset -g _GIT_PROMPT_LAST_UPDATE=0
typeset -g _GIT_PROMPT_LAST_MTIME=0
typeset -g _GIT_PROMPT_LAST_CHECK=0


# Initialize async worker (only once)
if (( ! ${+ASYNC_INIT_DONE} )); then
  async_init
  async_start_worker prompt_worker -n
  async_register_callback prompt_worker _handle_async_result
  ASYNC_INIT_DONE=1
fi

function _handle_async_result() {
  local job="$1" return_code="$2" output="$3" exec_time="$4"

  if [[ $job == "[async]" ]]; then
    return  # Initial async setup
  fi

  if [[ $return_code -eq 0 && -n "$output" ]]; then
    _GIT_PROMPT_INFO="$output"
  else
    _GIT_PROMPT_INFO=""
  fi

  # Always reset the prompt
  zle && zle reset-prompt
}

function _update_git_prompt() {

  # Debounce rapid directory changes (100ms)
  local now=$(( EPOCHREALTIME * 1000 ))
  (( now - _GIT_PROMPT_LAST_UPDATE < 100 )) && return
  _GIT_PROMPT_LAST_UPDATE=$now

  # Check if we're in a git repo
  if git rev-parse --is-inside-work-tree &>/dev/null; then
    local current_root=$(git rev-parse --show-toplevel 2>/dev/null)

    # If we changed repos or the info is empty
    if [[ "$current_root" != "$_GIT_PROMPT_REPO_ROOT" || -z "$_GIT_PROMPT_INFO" ]]; then
      _GIT_PROMPT_REPO_ROOT="$current_root"
      _GIT_PROMPT_INFO="%F{yellow}⌛ Loading Git info...%f"

      # Fallback worker check for older async versions
      if (( ! ${+ASYNC_PTYS} )) || [[ ! -n "${ASYNC_PTYS[$prompt_worker]}" ]]; then
        async_stop_worker prompt_worker 2>/dev/null
        async_start_worker prompt_worker -n
        async_register_callback prompt_worker _handle_async_result
      fi

      async_flush_jobs prompt_worker
      async_job prompt_worker _git_prompt_worker
    fi
  else
    # Not in a git repo - reset state
    if [[ -n "$_GIT_PROMPT_INFO" || -n "$_GIT_PROMPT_REPO_ROOT" ]]; then
      _GIT_PROMPT_INFO=""
      _GIT_PROMPT_REPO_ROOT=""
      # Force prompt update when leaving a repo
      zle && zle reset-prompt
    fi
  fi
}

# ===== Git Command Hook =====
function _git_command_hook() {
  # Get the full command that was executed
  local full_cmd="$1"

  # Check if we're in a Git repo (skip if not)
  [[ -n "$(git rev-parse --git-dir 2>/dev/null)" ]] || return

  # List of Git commands that should trigger an update
  local git_commands=(
  'add' 'commit' 'push' 'pull' 'checkout' 'merge' 'rebase'
  'reset' 'stash' 'tag' 'branch' 'remote' 'fetch' 'revert'
  'cherry-pick' 'apply' 'am' 'bisect' 'blame' 'clean' 'clone'
  'diff' 'gc' 'grep' 'init' 'mv' 'prune' 'reflog' 'rm' 'show'
  'status' 'submodule' 'switch' 'worktree'
)

  # Cache and recursion tracking
  typeset -A _expansion_cache
  typeset -a _expansion_stack

  # function to expand command (aliases + functions)
  function _expand_command() {
    local cmd="$1"
    local depth=${2:-0}

    # Safety checks
    (( depth > 10 )) && { echo "$cmd"; return }  # Recursion depth limit
    [[ " ${_expansion_stack[@]} " =~ " $cmd " ]] && { echo "$cmd"; return }  # Cycle detection

    # Check cache first
    [[ -n "${_expansion_cache[$cmd]}" ]] && { echo "${_expansion_cache[$cmd]}"; return }

    # Track current expansion
    _expansion_stack+=("$cmd")

    # First try as alias
    local alias_def=$(alias "$cmd" 2>/dev/null)
    if [[ -n "$alias_def" ]]; then
      # alias expansion using parameter expansion
      local expanded=${alias_def#*=}
      expanded=${expanded//\'/}
      expanded=${expanded//\"/}

      # Recursively expand the first word
      local first_word=${${=expanded}[1]}
      local remaining_words=${${=expanded}[2,-1]}
      local first_word_expanded=$(_expand_command "$first_word" $((depth + 1)))

      if [[ -n "$first_word_expanded" && "$first_word_expanded" != "$first_word" ]]; then
        expanded="$first_word_expanded $remaining_words"
      fi

      _expansion_cache[$cmd]="$expanded"
      _expansion_stack=(${_expansion_stack[1,-2]})
      echo "$expanded"
      return
    fi

    # Then try as function
    if typeset -f "$cmd" >/dev/null; then
      # Get function body (safer extraction)
      local func_body=$(typeset -f "$cmd" | tail -n +3 | head -n -1)
      local result=""

      # Check if function contains git commands
      while IFS= read -r line; do
        # Skip comments, empty lines, and declarations
        [[ "$line" =~ ^[[:space:]]*(#|local|export|typeset|function) ]] && continue
        [[ -z "${line// }" ]] && continue

        # Get first meaningful command
        local sub_cmd=$(echo "$line" | awk '{
        for (i=1; i<=NF; i++) {
          if ($i ~ /^(if|then|else|fi|do|done|while|for|case|esac|{|})$/) continue
            if ($i ~ /^[[:alnum:]]/) {print $i; break}
            }
          }')

          if [[ "$sub_cmd" == "git" ]]; then
            local git_subcmd=$(echo "$line" | awk '{
            for (i=1; i<=NF; i++) {
              if ($i == "git" && i < NF) {print $(i+1); break}
              }
            }')
            result="git $git_subcmd"
            break
          elif [[ -n "$sub_cmd" ]]; then
            local sub_expanded=$(_expand_command "$sub_cmd" $((depth + 1)))
            if [[ "$sub_expanded" == git* ]]; then
              result="$sub_expanded"
              break
            fi
              fi
            done <<< "$func_body"

            _expansion_cache[$cmd]="$result"
            _expansion_stack=(${_expansion_stack[1,-2]})
            [[ -n "$result" ]] && echo "$result" || echo "$cmd"
            return
          fi

    # Not an alias or function containing git commands
    _expansion_cache[$cmd]="$cmd"
    _expansion_stack=(${_expansion_stack[1,-2]})
    echo "$cmd"
  }

  # Get the first word of the command
  local first_word="${full_cmd%% *}"
  local expanded_command=$(_expand_command "$first_word")

  # Check if command contains git operations
  for cmd in "${git_commands[@]}"; do
    if [[ "$full_cmd" == *"git $cmd"* ||
      "$full_cmd" == *"git-$cmd"* ||
      "$expanded_command" == *"git $cmd"* ||
      "$expanded_command" == *"git-$cmd"* ]]; then
          # Invalidate cached Git info and force update
          _GIT_PROMPT_INFO=""
          _GIT_PROMPT_REPO_ROOT=""
          async_flush_jobs prompt_worker
          async_job prompt_worker _git_prompt_worker
          break
    fi
  done

  # Clean up
  unset _expansion_cache
  unset _expansion_stack
}

# Add the hook to be called after each command
add-zsh-hook preexec _git_command_hook

function _watch_git_changes() {
  # Only monitor if in a Git repo
  [[ -n "$_GIT_PROMPT_REPO_ROOT" ]] || return

  # Use inotifywait (Linux) to monitor for relevant changes
  if command -v inotifywait &>/dev/null; then
    # Linux: monitor for create/modify/delete events in the work tree
    inotifywait -q -e create,modify,delete,move -r "$_GIT_PROMPT_REPO_ROOT" --exclude '/\.git/' &>/dev/null &
    local watcher_pid=$!

    # When changes are detected, update prompt
    while read -r; do
      async_flush_jobs prompt_worker
      async_job prompt_worker _git_prompt_worker
    done < <(inotifywait -q -e create,modify,delete.move -r "$_GIT_PROMPT_REPO_ROOT" --exclude '/\.git/' 2>/dev/null)

    # Clean up when we leave the directory
    zshexit() { kill $watcher_pid 2>/dev/null }
  fi
}

# Lightweight filesystem check (no async, no prompt modifications)
function _check_git_changes() {
  # Skip if not in a Git repo
  [[ -n "$_GIT_PROMPT_REPO_ROOT" ]] || return

  # Get current directory mtime (cross-platform)
  local current_mtime
  if zmodload -e zsh/stat; then
    current_mtime=$(zstat +mtime "$_GIT_PROMPT_REPO_ROOT" 2>/dev/null || echo 0)
  else
    # Fallback for BSD/macOS
    current_mtime=$(stat -f %m "$_GIT_PROMPT_REPO_ROOT" 2>/dev/null || echo 0)
  fi

  # Force refresh if mtime changed (files were modified/created)
  if (( current_mtime != _GIT_PROMPT_LAST_MTIME )); then
    _GIT_PROMPT_LAST_MTIME=$current_mtime
    _GIT_PROMPT_INFO=""  # Invalidate cache
    _GIT_PROMPT_REPO_ROOT=""  # Force full reload
  fi
}

# ===== Prompt Precmd Hook =====
function prompt_precmd() {
  # Update terminal title
  print -Pn "\e]0;${debian_chroot:+($debian_chroot)}${VIRTUAL_ENV:+($(basename $VIRTUAL_ENV))}%n@%m: %~\a"

  # using simple git check changes based on mtime rather than the
  # complicated wath git changes
  _check_git_changes

  # Start the file watcher
  #_watch_git_changes

  # Start async git info update
  _update_git_prompt

  # Newline before prompt if configured
  if [[ "$NEWLINE_BEFORE_PROMPT" = yes ]]; then
    if [[ -z "$_NEW_LINE_BEFORE_PROMPT" ]]; then
      _NEW_LINE_BEFORE_PROMPT=1
    else
      print ""
    fi
  fi
}

# ===== Main Prompt Function =====
function git_prompt_info() {
  [[ -n "$_GIT_PROMPT_INFO" ]] && echo -n "─$_GIT_PROMPT_INFO"
}

# ===== Prompt Configuration =====
function configure_prompt() {
  prompt_symbol=💀
  [ "$EUID" -eq 0 ] && prompt_symbol=💀

  case "$PROMPT_ALTERNATIVE" in
    twoline)
      PROMPT=$'%F{%(#.blue.green)}┌──${debian_chroot:+($debian_chroot)─}(C/T:$(cpu_temp) $(ram_usage))─$(date_display)${VIRTUAL_ENV:+($(basename $VIRTUAL_ENV))}$(git_prompt_info)\n│──(%B%F{%(#.red.blue)}%n'$prompt_symbol$'%m%b%F{%(#.blue.green)})-[%B%F{reset}%(6~.%-1~/…/%4~.%5~)%b%F{%(#.blue.green)}]\n└───\>%B%(#.%F{red}#.%F{blue}$)%b%F{reset} '

      # Right prompt configuration
      success_indicator=' %F{green}%B🙂%b%F{reset}'
      error_indicator=' %? %F{red}%B$(handling_exit_code $?) %b%F{reset}'
      jobs_indicator='%(1j. %j %F{yellow}%B⚙%b%F{reset}.)'
      RPROMPT="%(?.${success_indicator}.${error_indicator})${jobs_indicator}"
      ;;
    oneline)
      PROMPT=$'${debian_chroot:+($debian_chroot)}${VIRTUAL_ENV:+($(basename $VIRTUAL_ENV))}%B%F{%(#.red.blue)}%n@%m%b%F{reset}:%B%F{%(#.blue.green)}%~%b%F{reset}%(#.#.$) '
      RPROMPT=
      ;;
    backtrack)
      PROMPT=$'${debian_chroot:+($debian_chroot)}${VIRTUAL_ENV:+($(basename $VIRTUAL_ENV))}%B%F{red}%n@%m%b%F{reset}:%B%F{blue}%~%b%F{reset}%(#.#.$) '
      RPROMPT=
      ;;
  esac
  unset prompt_symbol
}

# ===== Set Up Hooks =====
add-zsh-hook precmd prompt_precmd
add-zsh-hook chpwd _update_git_prompt


# ===== Final Setup =====

# The following block is surrounded by two delimiters.
# These delimiters must not be modified. Thanks.
# START KALI CONFIG VARIABLES
PROMPT_ALTERNATIVE=twoline
NEWLINE_BEFORE_PROMPT=yes
# STOP KALI CONFIG VARIABLES

if [ "$color_prompt" = yes ]; then
  # override default virtualenv indicator in prompt
  VIRTUAL_ENV_DISABLE_PROMPT=1

  configure_prompt

    # enable syntax-highlighting
    if [ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
      source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
      ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern)
      ZSH_HIGHLIGHT_STYLES[default]=none
      ZSH_HIGHLIGHT_STYLES[unknown-token]=fg=white,underline
      ZSH_HIGHLIGHT_STYLES[reserved-word]=fg=cyan,bold
      ZSH_HIGHLIGHT_STYLES[suffix-alias]=fg=green,underline
      ZSH_HIGHLIGHT_STYLES[global-alias]=fg=green,bold
      ZSH_HIGHLIGHT_STYLES[precommand]=fg=green,underline
      ZSH_HIGHLIGHT_STYLES[commandseparator]=fg=blue,bold
      ZSH_HIGHLIGHT_STYLES[autodirectory]=fg=green,underline
      ZSH_HIGHLIGHT_STYLES[path]=bold
      ZSH_HIGHLIGHT_STYLES[path_pathseparator]=
      ZSH_HIGHLIGHT_STYLES[path_prefix_pathseparator]=
      ZSH_HIGHLIGHT_STYLES[globbing]=fg=blue,bold
      ZSH_HIGHLIGHT_STYLES[history-expansion]=fg=blue,bold
      ZSH_HIGHLIGHT_STYLES[command-substitution]=none
      ZSH_HIGHLIGHT_STYLES[command-substitution-delimiter]=fg=magenta,bold
      ZSH_HIGHLIGHT_STYLES[process-substitution]=none
      ZSH_HIGHLIGHT_STYLES[process-substitution-delimiter]=fg=magenta,bold
      ZSH_HIGHLIGHT_STYLES[single-hyphen-option]=fg=green
      ZSH_HIGHLIGHT_STYLES[double-hyphen-option]=fg=green
      ZSH_HIGHLIGHT_STYLES[back-quoted-argument]=none
      ZSH_HIGHLIGHT_STYLES[back-quoted-argument-delimiter]=fg=blue,bold
      ZSH_HIGHLIGHT_STYLES[single-quoted-argument]=fg=yellow
      ZSH_HIGHLIGHT_STYLES[double-quoted-argument]=fg=yellow
      ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]=fg=yellow
      ZSH_HIGHLIGHT_STYLES[rc-quote]=fg=magenta
      ZSH_HIGHLIGHT_STYLES[dollar-double-quoted-argument]=fg=magenta,bold
      ZSH_HIGHLIGHT_STYLES[back-double-quoted-argument]=fg=magenta,bold
      ZSH_HIGHLIGHT_STYLES[back-dollar-quoted-argument]=fg=magenta,bold
      ZSH_HIGHLIGHT_STYLES[assign]=none
      ZSH_HIGHLIGHT_STYLES[redirection]=fg=blue,bold
      ZSH_HIGHLIGHT_STYLES[comment]=fg=black,bold
      ZSH_HIGHLIGHT_STYLES[named-fd]=none
      ZSH_HIGHLIGHT_STYLES[numeric-fd]=none
      ZSH_HIGHLIGHT_STYLES[arg0]=fg=cyan
      ZSH_HIGHLIGHT_STYLES[bracket-error]=fg=red,bold
      ZSH_HIGHLIGHT_STYLES[bracket-level-1]=fg=blue,bold
      ZSH_HIGHLIGHT_STYLES[bracket-level-2]=fg=green,bold
      ZSH_HIGHLIGHT_STYLES[bracket-level-3]=fg=magenta,bold
      ZSH_HIGHLIGHT_STYLES[bracket-level-4]=fg=yellow,bold
      ZSH_HIGHLIGHT_STYLES[bracket-level-5]=fg=cyan,bold
      ZSH_HIGHLIGHT_STYLES[cursor-matchingbracket]=standout
    fi
  else
    PROMPT='${debian_chroot:+($debian_chroot)}%n@%m:%~%(#.#.$) '
fi

unset color_prompt force_color_prompt

toggle_oneline_prompt(){
  if [ "$PROMPT_ALTERNATIVE" = oneline ]; then
    PROMPT_ALTERNATIVE=twoline
  else
    PROMPT_ALTERNATIVE=oneline
  fi
  configure_prompt
  zle reset-prompt
}

zle -N toggle_oneline_prompt
bindkey ^P toggle_oneline_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
  xterm*|rxvt*|Eterm|aterm|kterm|gnome*|alacritty)
    TERM_TITLE=$'\e]0;${debian_chroot:+($debian_chroot)}${VIRTUAL_ENV:+($(basename $VIRTUAL_ENV))}%n@%m: %~\a'
    ;;
  *)
    ;;
esac
