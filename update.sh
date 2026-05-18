#!/usr/bin/env bash
set -euo pipefail

export DOTFILES="${DOTFILES:-$HOME/dotfiles}"
INSTALLER="$DOTFILES/installer"

cd "$DOTFILES"
git fetch --all
git reset --hard origin/$(git branch --show-current)
git clean -fd

source "$INSTALLER/env.sh"
source "$INSTALLER/links.sh"
finalize