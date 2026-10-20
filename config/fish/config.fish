set -g fish_greeting
set -q DOTFILES; or set -gx DOTFILES ~/dotfiles
fish_add_path -g ~/.local/bin ~/.opencode/bin

status is-interactive; or exit

command -q starship; and starship init fish | source

function fastfetch
    set -l pack (jq -r '.pack // ""' ~/.local/state/quickshell/settings.json 2>/dev/null)
    set -l img (find "$DOTFILES/local/stickers/$pack" -type f -not -path '*/logo/*' -iregex '.*\.\(png\|jpe?g\|webp\|gif\)' 2>/dev/null | shuf -n1)
    test -n "$img"; and ln -sf $img ~/.cache/fastfetch_cover
    command fastfetch $argv
end

fastfetch
