set -g fish_greeting
starship init fish | source

function fastfetch
    set -l imgs ~/dotfiles/logo/img/*.png ~/dotfiles/logo/img/*.jpg ~/dotfiles/logo/img/*.jpeg ~/dotfiles/logo/img/*.webp
    if set -q imgs[1]
        ln -sfn $imgs[(random 1 (count $imgs))] ~/.cache/fastfetch_cover
    end
    command fastfetch $argv
end

fastfetch
