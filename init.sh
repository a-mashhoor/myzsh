#!/usr/bin/env bash

set -e

main() {
  if [ $EUID -ne 0 ]; then
    echo "be root" 1>&2
    exit 100
  fi

  quiet=0
  global=0
  user=0

  while getopts "qug" opt; do
    case $opt in
    q) quiet=1 ;;
    u) user=1 ;;
    g) global=1 ;;
    *) usage ;;
    esac
  done
  shift $((OPTIND - 1))

  if [ $user -eq 0 ] && [ $global -eq 0 ]; then
    echo "err: either -u or -g" >&2
    usage
  elif [ $user -eq 1 ] && [ $global -eq 1 ]; then
    echo "err: use olny one of -u or -g" >&2
    usage
  fi
  installing
}

log() {
  if [[ $quiet -eq 0 ]]; then
    echo "$@"
  fi
}

usage() {
  echo "Usage: $0 [-q] (-u | -g)"
  echo "Options:"
  echo "  -q: quiet"
  echo "  -u: user installation"
  echo "  -g: global installation"
  exit 3
}

installing() {
  log "Updating packages..."
  sudo apt update && sudo apt install -y git procps lm-sensors zsh

  if [ $user -eq 1 ]; then
    log "Installing config for user: $USER"

    mkdir -p ~/.zsh-config/

    git clone https://github.com/a-mashhoor/myzsh.git ~/.zsh-config

    rm -rf ~/.zsh-config/.zsh/plugins/async
    git clone https://github.com/mafredri/zsh-async \
      ~/.zsh-config/.zsh/plugins/async

    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
      ~/.zsh-config/.zsh/plugins/zsh-syntax-highlighting

    git clone https://github.com/zsh-users/zsh-autosuggestions \
      ~/.zsh-config/.zsh/plugins/zsh-autosuggestions

    mkdir -p ~/.fonts && cd ~/.fonts || {
      echo "dir err"
      exit 1
    }

    wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/FiraCode.zip
    unzip FiraCode.zip && fc-cache -fv

    if [ -f ~/.zshrc ]; then
      cp ~/.zshrc ~/.zshrc.bak
      rm -f ~/.zshrc
    fi
    ln -s ~/.zsh-config/.zshrc ~/.zshrc

    mkdir -p ~/.zsh
    for dir in aliases functions plugins prompt; do
      ln -s ~/.zsh-config/.zsh/"$dir" ~/.zsh/"$dir"
    done
    sudo chsh -s "$(which zsh)" "$USER"

  else
    log "installing global configuration..."

    sudo apt install -y zsh-syntax-highlighting zsh-autosuggestions
    sudo git clone https://github.com/a-mashhoor/myzsh.git /etc/zsh-config

    sudo rm -rf /etc/zsh-config/.zsh/plugins/async
    sudo git clone https://github.com/mafredri/zsh-async /etc/zsh-config/.zsh/plugins/async

    [ -f /etc/zsh/zshrc ] && sudo mv /etc/zsh/zshrc /etc/zsh/zshrc.bak

    sudo ln -s /etc/zsh-config/.zshrc /etc/zsh/zshrc
    sudo mkdir -p /etc/zsh
    for dir in aliases functions plugins prompt; do
      sudo ln -s /etc/zsh-config/.zsh/"$dir" /etc/zsh/"$dir"
    done

    if command -v zsh >/dev/null; then
      zsh_path=$(command -v zsh)
      sudo sed -i "s|/bin/bash|$zsh_path|g" /etc/passwd
    else
      echo "Error: zsh not found!" >&2
      exit 1
    fi
  fi
}

main "${@}"
