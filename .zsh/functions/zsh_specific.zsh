function command_not_found_handler() {
	if [[ -f $1 ]]; then
		${EDITOR:-vim} "$1" # Uses $EDITOR (if set) or falls back to vim
	else
		echo "zsh: command not found: $1" >&2
		return 127
	fi
}

#function open_file_if_exists() {
#  if [[ -f $BUFFER ]]; then
#    ${EDITOR:-vim} "$BUFFER"
#    BUFFER=""
#  fi
#}
#add-zsh-hook preexec open_file_if_exists

#or this

#function _accept-line() {
#  if [[ -f $BUFFER ]]; then
#    ${EDITOR:-vim} "$BUFFER"
#    BUFFER=""
#    zle redisplay  # Prevent command from running
#  else
#    zle .accept-line  # Proceed normally
#  fi
#}
#zle -N accept-line _accept-line
