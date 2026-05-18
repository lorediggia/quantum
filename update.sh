#!/usr/bin/env bash
set -euo pipefail

export DOTFILES="${DOTFILES:-$HOME/dotfiles}"
INSTALLER="$DOTFILES/installer"

cd "$DOTFILES" && git pull

source "$INSTALLER/env.sh"
source "$INSTALLER/links.sh"
finalize