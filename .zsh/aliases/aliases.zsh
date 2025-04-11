# testing all of this aliases using:
# alias | grep '^g' | cut -d'=' -f1 | xargs -I{} zsh -c 'whence -v {}' | grep "not found"

#================= General Aliases ========================

# ----System and Navigation----

#force zsh to show the complete history
#alias history="history 0"
alias c='clear'
#alias current_dir="$(printf '%q\n' "${PWD##*/}")"
#alias current_dir="$(printf '%s\n' "${PWD##*/}")"
alias current_dir='echo ${PWD##*/}'
alias fstab="sudo -E vim /etc/fstab"

alias inst="apt install -y"
alias s-update="sudo apt update  && sudo apt full-upgrade -y && apt autoremove && apt autoclean && apt-get clean"

# login manager aliases it may differ based on the DE
alias lock-sleep='loginctl lock-session && systemctl suspend -i'
alias lock='loginctl lock-session'

alias now="jdate  +'%D %B %T %A' "

alias proc='ps --no-headers -aeo pid,lstart,etime,command | more'
alias q='bye'
alias rem='nocorrect rm -rfvi'
# sudo with an space makes possible to run alias commands as sudo
alias sudo='sudo '
alias sudo_E='sudo -E '

#alias most_used_commands="history 0 | awk '{a[$2]++}END{for(i in a){print a[i] " " i}}' | sort -rn | head -50 "

# ----File Operations----

alias la='ls --color=auto -A'
alias lla='ls --color=auto -lhA'
alias ll='ls --color=auto -lh'
alias l='ls --color=auto -CF'
alias vdir='vdir --color=auto'
alias v='vim'

# SystemD services & Service Managment

alias disable_sys='sudo systemctl disable '
alias edit_sys='sudo systemctl edit '
alias enable_sys='sudo systemctl enable '
alias is_act_sys='systemctl is-active '
alias restart_sys='sudo systemctl restart '
alias running='systemctl list-units --state=running'
alias servs='service --status-all | grep +'
alias start_sys='sudo systemctl start '
alias status_sys='systemctl status '
alias stop_sys='sudo systemctl stop '

# ==================Networking, Seucrity & PenTest=================

# system networking
alias internet_route4='ip -o route get 8/8 | grep --color=always "dev [^ ]*"'
alias internet_route6='ip -o route get 2000::/3 | grep --color=always "dev [^ ]*"'

# netstat
# ss

# curl
alias cors-check='curl -H "Origin: louie.com" -I'

alias ip='ip --color=auto'

# MSF
alias msf-start="msfdb reinit && msfconsole"

# burp suit
alias curl-burp="curl --proxy http://127.0.0.1:8080"

# Nmap

alias nfast="nmap -T4 -F"
alias nfull="nmap -T4 -p-"
alias nscript="nmap --script=vuln"
alias nssl="nmap -p 443 --script=ssl-enum-ciphers"

# =================== Text Proccesing ===================

# grep and grep-like

alias grepipv4="grep --color=auto -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}'"
alias grep_email="grep --color=auto -oE '([a-zA-Z0-9_.]+@[a-zA-Z0-9_.]+)'"
if command -v rg &>/dev/null; then
	alias hl='rg --passthru'
fi

# jq
# jy

# ============== Development ==============

alias py='python3'

# =============== Note taking and reports ===========

alias add-note='echo "$(date): $1" >> report.md'

# ===========git group of aliases===============
alias g='git'

# Branch managment

alias gb='git branch'                                                             # List branches
alias gbd='git branch -d'                                                         # Delete branch (safe)
alias gbdm='git branch -D' 2>/dev/null || echo "Use 'gbdm-all' for mass deletion" # Force delete branch
alias gba='git branch -a'                                                         # List all branches (including remotes)
alias gbr='git branch -r'                                                         # List remote branches
alias gsu='git switch -'                                                          # Switch to last branch (like `cd -`)
alias gbdm-all='git branch | grep -v "main\|master" | xargs git branch -D'        # Delete all non-main branches
alias gbm='git branch -m'                                                         # Rename branch
alias gcb='git checkout -b'                                                       # Create and switch to new branch
alias gco='git checkout'                                                          # Switch branch
alias gcleanup='git branch --merged | grep -v "*" | xargs git branch -d'          # Clean merged branches
alias gup='git branch --set-upstream-to=origin/$(git branch --show-current)'      # Set upstream
alias gcpd='git cherry-pick --ff'                                                 # Fast-forward cherry-pick

# Commiting

alias gc='git commit'                        # Standard commit
alias gcm='git commit -m'                    # Commit with message
alias gcam='git commit -am'                  # Add all and commit with message
alias gca='git commit --amend'               # Amend last commit
alias gcn='git commit --no-verify'           # Skip pre-commit hooks
alias gcaa='git commit -a --amend'           # Amend all changes
alias gfixup='git commit --fixup'            # Create fixup commit
alias gundo-commit='git reset --soft HEAD~1' # Undo last commit (keep changes)

# Staging

alias ga='git add'             # Add specific files
alias gaa='git add .'          # Add all files
alias gai='git add -i'         # Interactive add
alias gap='git add -p'         # Patch add (interactive chunks)
alias gsa='git stash apply'    # Apply without dropping
alias gsd='git stash drop'     # Drop stash
alias gslp='git stash list -p' # Show stash diffs

# Remote Ops

alias gp='git push'                     # Push to remote
alias gpf='git push --force-with-lease' # Force push (safely)
alias gpl='git pull'                    # Pull from remote
alias gpr='git pull --rebase'           # Pull with rebase
alias gra='git remote add'              # Add remote
alias grm='git remote remove'           # Remove remote
alias grv='git remote -v'               # List remotes
alias gru='git remote update'           # Update remote references
alias gfe='git fetch'                   # Fetch from remote
alias gfea='git fetch --all'            # Fetch all remotes
alias gfeu='git fetch upstream'         # Fetch from upstream

# History and Logging

alias gls='git log --show-signature'                                         # Verify signed commits
alias glf='git log --pretty=fuller'                                          # Detailed commit metadata
alias gl='git log --oneline --graph --decorate --all'                        # Compact log
alias gloga='git log --all --graph --decorate --oneline'                     # All-branch log
alias glogd='git log --date=short --pretty=format:"%C(auto)%h %ad %s (%an)"' # Dated log
alias glogp='git log --pretty=format:"%h %s (%an, %ar)"'                     # Pretty log
alias glog-stats='git shortlog -sn --all --no-merges'                        # Contribution stats
alias gwho='git shortlog -sn'                                                # Contributor counts
alias glg='git log --stat'                                                   # Log with stats
alias glp='git log -p'                                                       # Log with patches
alias glt='git log --graph --since="1 week ago"'                             # Recent timeline

# Diff & Inseption

alias gd='git diff'                                     # Working changes
alias gshow='git show'                                  # Show commit
alias gblame='git blame'                                # Line-by-line history
alias gwt='git worktree'                                # Manage worktrees
alias gcount='git shortlog -sn'                         # Count commits per author
alias gwhat='git whatchanged'                           # Show changed files per commit
alias gconflicts='git diff --name-only --diff-filter=U' # List conflicted files

# Reset & Undo

alias gr='git reset'                    # Mixed reset (default)
alias grh='git reset --hard'            # Hard reset (dangerous)
alias grs='git reset --soft'            # Soft reset
alias gundo='git reset HEAD~1'          # Undo last commit
alias gredo='git reset --hard HEAD@{1}' # Redo last undo

# Stashing

alias gss='git stash save'                      # Create stash
alias gsl='git stash list'                      # List stashes
alias gsp='git stash pop'                       # Apply stash
alias gspf='git stash push --include-untracked' # Stash untracked files

# Rebasing

alias grb='git rebase'             # Start rebase
alias grba='git rebase --abort'    # Abort rebase
alias grbc='git rebase --continue' # Continue rebase
alias grbi='git rebase -i'         # Interactive rebase
alias grbs='git rebase --skip'     # Skip conflict

# Cleaning & maintaine

alias gclean='git clean -fd'           # Remove untracked files
alias gclean-all='git clean -fdx'      # Remove all untracked (including ignored)
alias ggc='git gc'                     # Garbage collection
alias gscrub='git gc --aggressive'     # Deep cleanup
alias grepack='git repack -ad'         # Optimize local repo
alias gprune='git remote prune origin' # Prune stale remote branches
alias gtrim='git gc --prune=now'       # Aggressively prune loose objects

# Bisect & Debugging

alias gbs='git bisect start' # Start bisect
alias gbg='git bisect good'  # Mark good commit
alias gbb='git bisect bad'   # Mark bad commit
alias gbr='git bisect reset' # Reset bisect

#Merging & Conflict Resolution

alias gcp='git cherry-pick'    # Apply commit
alias gresolve='git mergetool' # Resolve conflicts

# Tagging

alias gtag='git tag'     # List tags
alias gtags='git tag -l' # List tags (alternative)
alias gmtag='git tag -a' # Create annotated tag

# Sync & Maintainace

alias gsync='git pull --rebase && git push'                                         # Sync current branch
alias gsync-pr='git checkout main && git pull && git checkout - && git rebase main' # Sync PR branch
alias gsync-exploits='git pull https://github.com/offensive-security/exploitdb.git' # update Exploit DB

# Help & Info

alias gs='git status'     # Current status
alias ghelp='git help -a' # All help commands
