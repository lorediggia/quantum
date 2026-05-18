set -g fish_greeting
starship init fish | source

function fastfetch
    set -l imgs ~/dotfiles/logo/img/*.{png,jpg,jpeg,webp}
    test -n "$imgs[1]"; and ln -sfn $imgs[(random 1 (count $imgs))] ~/.cache/fastfetch_cover
    command fastfetch $argv
end

fastfetch
