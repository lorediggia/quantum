LOG="$HOME/.cache/quantum.log"
mkdir -p "$(dirname "$LOG")"
:> "$LOG"

ITEMS=(
    "HYPR|Core Hyprland"
    "QSH|Quickshell UI"
    "TERM|Terminal Stack"
    "THEME|Wallust"
    "GTK|WhiteSur GTK"
    "CURSOR|Bibata Cursor"
    "FONT|Inter Font"
    "ROFI|Rofi Launcher"
    "HOLO|Holograph TUI"
    "BT|Bluetooth"
    "AUDIO|Audio Stack"
    "BTOP|Btop"
    "FF|Fastfetch"
    "FILES|Nautilus"
)

declare -A SEL
TOTAL=${#ITEMS[@]}
for i in "${!ITEMS[@]}"; do SEL[$i]=1; done
CURRENT=0

menu() {
    tput civis
    while true; do
        clear
        echo "Select components (SPACE to toggle, ENTER to confirm):"
        echo ""
        for i in "${!ITEMS[@]}"; do
            IFS='|' read -r key name <<< "${ITEMS[i]}"
            local box="[ ]"
            [[ ${SEL[$i]} -eq 1 ]] && box="[X]"
            if [[ $i -eq $CURRENT ]]; then
                echo "> $box $name"
            else
                echo "  $box $name"
            fi
        done
        IFS= read -rsn1 key < /dev/tty
        case "$key" in
            $'\x1b')
                read -rsn2 -t 0.05 seq < /dev/tty || true
                case "$seq" in
                    "[A") CURRENT=$(( (CURRENT - 1 + TOTAL) % TOTAL )) ;;
                    "[B") CURRENT=$(( (CURRENT + 1) % TOTAL )) ;;
                esac ;;
            " ") SEL[$CURRENT]=$((1 - SEL[$CURRENT])) ;;
            ""|$'\n') break ;;
        esac
    done
    tput cnorm
}

on() {
    for i in "${!ITEMS[@]}"; do
        IFS='|' read -r key _ <<< "${ITEMS[i]}"
        if [[ "$key" == "$1" ]]; then
            if [[ ${SEL[$i]} -eq 1 ]]; then return 0; else return 1; fi
        fi
    done
    return 1
}

run() {
    echo -n "  $1... "
    shift
    if "$@" >>"$LOG" 2>&1; then
        echo "OK"
    else
        echo "FAILED"
        return 1
    fi
}