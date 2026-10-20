#!/usr/bin/env bash
set -euo pipefail

cargo install --locked --root "$HOME/.local" --git https://codeberg.org/explosion-mental/wallust --tag "$1" wallust \
    || cargo install --locked --root "$HOME/.local" --version "$1" wallust
