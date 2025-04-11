# ===== Git Operations =====

function gignore() {
  [[ ! -f .gitignore ]] && touch .gitignore
  echo "$1" >> .gitignore
}

function gacp() {
  [[ -z "$1" ]] && { echo "Usage: gacp <message>"; return 1 }
  git add . && git commit -am "$1" && git push -u origin main
}

function gsquash() {
  [[ -z "$1" ]] && { echo "Usage: gsquash <num-commits>"; return 1 }
  git rebase -i HEAD~"$1"
}

function gcleanup-merged()
{
  git checkout main || git checkout master
  git pull
  git branch --merged | grep -v "^\*" | grep -v "main" | grep -v "master" | xargs git branch -d
}

function grename() {
  [[ -z "$1" ]] && { echo "Usage: grename <new-name>"; return 1 }
  git branch -m "$1"
}

function gswitch-main()
{
  if git show-ref --verify --quiet refs/heads/main; then
    git checkout main
  elif git show-ref --verify --quiet refs/heads/master; then
    git checkout master
  else
    echo "Neither 'main' nor 'master' branch exists."
  fi
}

function grebase-fixup()
{
  [[ -z "$1" ]] && { echo "Usage: grebase-fixup <base-commit>"; return 1 }
  git rebase -i --autosquash "$1"
}

function grebase-abort() { git rebase --abort }

function grebase-continue() { git rebase --continue }

function gstash() {
  [[ -z "$1" ]] && { echo "Usage: gstash <message>"; return 1 }
  git stash push -m "$1"
}

function gstash-apply()
{
  local stashes=$(git stash list)
  [[ -z "$stashes" ]] && { echo "No stashes found."; return 1 }
  echo "$stashes"; read "stash_index?Enter stash index (e.g., @{0}): "
  git stash apply "$stash_index"
}

function glog-depth()
{
  [[ -z "$1" ]] && { echo "Usage: glog-depth <num-commits>"; return 1 }
  git log --oneline --graph --decorate --all -n "$1"
}

function glog-between()
{
  [[ -z "$1" || -z "$2" ]] && { echo "Usage: glog-between <commit1> <commit2>"; return 1 }
  git log --oneline "$1".."$2"
}

function gsync-upstream()
{
  git fetch upstream
  git checkout main || git checkout master
  git merge upstream/main || git merge upstream/master
  git push -u origin main || git push -u origin master
}

function gpush-safe() { git push --force-with-lease }

function gbisect-auto()
{
  git bisect start
  git bisect bad
  git bisect good "$1"
  while true; do
    read "response?Is this commit good? (y/n/q): "
    case "$response" in
      y) git bisect good ;;
      n) git bisect bad ;;
      q) break ;;
      *) echo "Invalid input. Use y, n, or q to quit." ;;
    esac
  done
  git bisect reset
}

function glarge-files()
{
  {git rev-list --objects --all \
    | git cat-file --batch-check='%(objecttype) %(objectname) %(size) %(rest)' \
    | awk '$1 == "blob" && $3 > 1024 { print $3, $4 }' \
    | sort -n;
  }
}


function gnew-push()
{
  [[ -z "$1" ]] && { echo "Usage: gnew-push <branch-name>"; return 1 }
  git checkout -b "$1" && git push -u origin "$1"
}


function ggsync-exploits()
{
  git pull https://github.com/offensive-security/exploitdb.git
  git log --since="1 week ago" --oneline
}


function gvuln-note()
{
  [[ -z "$1" ]] && { echo "Usage: gvuln-note <vuln-name>"; return 1 }
  git checkout -b "vuln/$1" && git push -u origin "vuln/$1"
}


function gupdate-report()
{
  local report_file="report.md"
  [[ ! -f "$report_file" ]] && echo "# Security Report" > "$report_file"
  echo "## Update: $(date)" >> "$report_file"
  git add "$report_file" && git commit -m "Update report: $(date)" && git push
}


function gcount-tool()
{
  [[ -z "$1" ]] && { echo "Usage: gcount-tool <tool-name>"; return 1 }
  git log --grep="$1" --oneline | wc -l
}


function gclone-pentest()
{
  [[ -z "$1" ]] && { echo "Usage: gclone-pentest <repo-url>"; return 1 }
  local repo_name=$(basename "$1" .git)
  mkdir -p ~/Applications/clones/pentest-tools/$repo_name
  git clone "$1" ~/Applications/clones/pentest-tools/$repo_name
}
