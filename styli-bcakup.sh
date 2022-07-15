#!/usr/bin/env bash
# shellcheck disable=SC2120,SC2154,SC1090,SC2034
LINK="https://source.unsplash.com/random/"

die() {
    case $1 in
    "no-sub")
        MSG="Please install the subreddits file in $CONFDIR"
        ;;
    "mime")
        MSG="MIME-Type missmatch. Downloaded file is not an image!"
        ;;
    "unexpect")
        MSG="Unexpected option: $1 this should not happen."
        ;;
    "internet")
        MSG="No internet connection, exiting stylish."
        ;;
    "not-valid")
        MSG="The current subreddit is not valid."
        ;;
    *)
        MSG="Unknown error."
        ;;
    esac

    printf "ERR: %s\n" "$MSG" >&2
    exit 0
}

if [[ -z ${XDG_CONFIG_HOME} ]]; then
    XDG_CONFIG_HOME="$HOME/.config"
fi

if [[ -z ${XDG_CACHE_HOME} ]]; then
    XDG_CACHE_HOME="$HOME/.cache"
fi

CONFDIR="${XDG_CONFIG_HOME}/styli.sh"
if [[ ! -d "$CONFDIR" ]]; then
    mkdir -p "$CONFDIR"
fi

CACHEDIR="${XDG_CACHE_HOME}/styli.sh"
if [[ ! -d "$CACHEDIR" ]]; then
    mkdir -p "$CACHEDIR"
fi

WALLPAPER="$CACHEDIR/wallpaper.jpg"
TEMP_WALL="$CACHEDIR/temp"

usage() {
    echo -ne "Usage:
    styli.sh option <string>
    Following options can be used

    [ -a  | --artist <deviant artist> ]
    [ -b  | --fehbg <feh bg opt> ]
    [ -bi | --bing <bing daily wallpaper>]
    [ -c  | --fehopt <feh opt> ]
    [ -d  | --directory ]
    [ -g  | --gnome ]
    [ -h  | --height <height> ]
    [ -k  | --kde ]
    [ -l  | --link <source> ]
    [ -m  | --monitors <monitor count (nitrogen)> ]
    [ -n  | --nitrogen ]
    [ -r  | --subreddit <subreddit> <sort(top,hot)> < ]
    [ -s  | --search <string> ]
    [ -sa | --save <Save current image to pictures directory> ]
    [ -w  | --width <width> ]
    [ -x  | --xfce ] 
    \n"
    exit 0
}

type_check() {
    MIME_TYPES=("image/bmp" "image/jpeg" "image/gif" "image/png" "image/heic")
    PROCEED=0
    for REQUIREDTYPE in "${MIME_TYPES[@]}"; do
        IMAGETYPE=$(file --mime-type "$TEMP_WALL" | awk '{print $2}')
        if [[ "$IMAGETYPE" =~ $REQUIREDTYPE ]]; then
            PROCEED=1
            break
        fi
    done
    if [[ "$PROCEED" -eq 0 ]]; then
        die "mime"
        exit 0
    else
        cp "$TEMP_WALL" "$WALLPAPER"
    fi
}

save_cmd() {
    SAVED_WALLPAPER="$HOME/Pictures/wallpapers/stylish-$RANDOM.jpg"
    # SAVED_WALLPAPER="$HOME/Pictures/wallpapers/stylish-2478.jpg"
    # check if wallpaper is present
    if [[ -f "$WALLPAPER" ]]; then
        # check if pictures directory is present
        if [[ -d "$HOME/Pictures" ]]; then
            # check if file is not already present
            if [[ ! -f "$HOME/Pictures/wallpapers/$(basename "$SAVED_WALLPAPER")" ]]; then
                cp "$WALLPAPER" "$SAVED_WALLPAPER"
                exit 0
            else
                printf "%s already exists in $HOME/Pictures\n" "$(basename "$SAVED_WALLPAPER")"
                exit 1
            fi
        else
            printf "Pictures directory is not found. Please create it in %s.\n" "$HOME"
            exit 1
        fi
    else
        printf "%s is not found.\n" "$WALLPAPER"
        exit 1
    fi
}

unsplash() {
    local SEARCH="${SEARCH// /_}"
    if [[ -n "$HEIGHT" || -n "$WIDTH" ]]; then
        # keeping {} for $LINK value
        LINK="${LINK}$WIDTHx$HEIGHT"
    else
        LINK="${LINK}1920x1080"
    fi

    if [[ -n "$SEARCH" ]]; then
        LINK="${LINK}/?$SEARCH"
    fi
    wget --quiet --output-document="$TEMP_WALL" "$LINK"
}

bing_daily() {
    JSON=$(curl --silent "http://www.bing.com/HPImageArchive.aspx?format=js&idx=0&n=1")
    URL=$(echo "$JSON" | jq '.images[0].url' | sed -e 's/^"//'  -e 's/"$//')
    IMAGE_URL="http://www.bing.com"${URL}
    wget --quiet --output-document="$TEMP_WALL" "$IMAGE_URL"
}

select_random_wallpaper() {
    WALLPAPER="$(find "$DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.svg" -o -iname "*.gif" \) -print | shuf -n 1)"
    #check if file is present
    if [[ -f "$WALLPAPER" ]]; then
        OPT=1
        # gnome_cmd # needed to be called here
    else
        printf "No wallpaper found in %s\n" "$DIR"
        exit 1
    fi
}

# https://github.com/egeesin/alacritty-color-export
# SC2120
alacritty_change() {
    DEFAULT_MACOS_CONFIG="$HOME"/.config/alacritty/alacritty.yml

    # Wal generates a shell script that defines color0..color15
    SRC="$HOME"/.cache/wal/colors.sh

    [[ -e "$SRC" ]] || die "Wal colors not found, exiting script. Have you executed Wal before?"
    printf "Colors found, source ready.\n"

    READLINK=$( command -v greadlink || command -v readlink )

    # Get config file
    if [[ -n "$1" ]]; then
        [[ -e "$1" ]] || die "Selected config doesn't exist, exiting script."
        printf "Config found, destination ready.\n"
        CFG=$1
        [[ -L "$1" ]] && {
            printf "Following symlink to config...\n"
            CFG=$($READLINK -f "$1")
        }
    else
        # Default config path in Mac systems
        [[ -e "$DEFAULT_MACOS_CONFIG" ]] || die "Alacritty config not found, exiting script."

        CFG="$DEFAULT_MACOS_CONFIG"
        [[ -L "$DEFAULT_MACOS_CONFIG" ]] && {
            printf "Following symlink to config...\n"
            CFG=$($READLINK -f "$DEFAULT_MACOS_CONFIG")
        }
    fi

    # Get hex colors from Wal cache
    # No need for shellcheck to check this, it comes from pywal
    . "$SRC" # SC1090

    # Create temp file for sed results
    tempfile=$(mktemp)
    trap 'rm $tempfile' INT TERM EXIT

    # Delete existing color declarations generated by this script
    # If begin comment exists
    if grep -q '^# BEGIN ACE' "$CFG"; then
        # And if end comment exists
        if grep -q '^# END ACE' "$CFG"; then
            # Delete contents of the block
            printf "Existing generated colors found, replacing new colors...\n"
            sed '/^# BEGIN ACE/,/^# END ACE/ {
        /^# BEGIN ACE/! { /^# END ACE/!d; }
            }' "$CFG" > "$tempfile" \
            && cat "$tempfile" > "$CFG"
            # If no end comment, don't do anything
        else
            die "No '# END ACE' comment found, please ensure it is present."
        fi
        # If no begin comment found
    else
        # Don't do anything and notify user if there's an end comment in the file
        ! grep -q '^# END ACE' "$CFG" || die "Found '# END ACE' comment, but no '# BEGIN ACE' comment found. Please ensure it is present."
        printf "There's no existing 'generated' colors, adding comments...\n";
        printf '# BEGIN ACE\n# END ACE' >> "$CFG";
    fi

    # Write new color definitions
    # We know $colorX is unset, we set it by sourcing above
    { sed "/^# BEGIN ACE/ r /dev/stdin" "$CFG" > "$tempfile" <<EOP
colors:
  primary:
    background: '$color0' #SC2154
    foreground: '$color7'
  cursor:
    text:       '$color0'
    cursor:     '$color7'
  normal:
    black:      '$color0'
    red:        '$color1'
    green:      '$color2'
    yellow:     '$color3'
    blue:       '$color4'
    magenta:    '$color5'
    cyan:       '$color6'
    white:      '$color7'
  bright:
    black:      '$color8'
    red:        '$color9'
    green:      '$color10'
    yellow:     '$color11'
    blue:       '$color12'
    magenta:    '$color13'
    cyan:       '$color14'
    white:      '$color15'
EOP
} && cat "$tempfile" > "$CFG" \
&& rm "$tempfile"
trap - INT TERM EXIT
printf "'%s' exported to '%s'\n" "$SRC" "$CFG"
}


reddit() {
    if [[ -n "$1" ]]; then
        SUB="$1"
    else
        if [[ ! -f "$CONFDIR/subreddits" ]]; then
            die "no-sub"
        fi
        readarray SUBREDDITS <"$CONFDIR/subreddits"
        a=${#SUBREDDITS[@]}
        b=$((RANDOM % a))
        SUB=${SUBREDDITS[$b]}
        SUB="$(echo -e "$SUB" | tr -d '[:space:]')"
        # echo "$SUB"
    fi

    USERAGENT="Mozilla/5.0 (X11; Arch Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.5005.61 Safari/537.36"
    TIMEOUT=60

    SORT="$2"
    TOP_TIME="$3"
    if [[ -z "$SORT" ]]; then
        SORT="hot"
    fi

    if [[ -z "$TOP_TIME" ]]; then
        TOP_TIME=""
    fi

    URL="https://www.reddit.com/r/$SUB/$SORT.json?raw_json=1&t=$TOP_TIME"
    # echo "$URL"
    CONTENT=$(wget --timeout="$TIMEOUT" --user-agent="$USERAGENT" --quiet -O - "$URL")
    mapfile -t URLS <<< "$(echo -n "$CONTENT" | jq -r '.data.children[]|select(.data.post_hint|test("image")?) | .data.preview.images[0].source.url')"
    wait # prevent spawning too many processes
    SIZE=${#URLS[@]}
    # echo "${URLS[@]}"
    if [[ "$SIZE" -eq 0 ]]; then
        die "not-valid"
    fi
    IDX=$((RANDOM % SIZE))
    TARGET_URL=${URLS[$IDX]}
    wget --timeout=$TIMEOUT --user-agent="$USERAGENT" --no-check-certificate --quiet --directory-prefix=down --output-document="$TEMP_WALL" "$TARGET_URL"
}


deviantart() {
    CLIENT_ID="16531"
    CLIENT_SECRET="68c00f3d0ceab95b0fac638b33a3368e"
    PAYLOAD="grant_type=client_credentials&client_id=$CLIENT_ID&client_secret=$CLIENT_SECRET"
    ACCESS_TOKEN=$(curl --silent -d $PAYLOAD https://www.deviantart.com/oauth2/token | jq -r '.access_token')
    if [[ -n "$1" ]]; then
        ARTIST="$1"
        URL="https://www.deviantart.com/api/v1/oauth2/gallery/?username=$ARTIST&mode=popular&limit=24"
    elif [[ -n "$SEARCH" ]]; then
        [[ "$SEARCH" =~ ^(tag:)(.*)$ ]] && TAG=${BASH_REMATCH[2]}
        if [[ -n "$TAG" ]]; then
            URL="https://www.deviantart.com/api/v1/oauth2/browse/tags?tag=$TAG&offset=${RANDOM:0:2}&limit=24"
        else
            URL="https://www.deviantart.com/api/v1/oauth2/browse/popular?q=$SEARCH&limit=24&timerange=1month"
        fi
    else
        TOPICS=("adoptables" "artisan-crafts" "anthro" "comics" "drawings-and-paintings" "fan-art" "poetry" "stock-images" "sculpture" "science-fiction" "traditional-art" "street-photography" "street-art" "pixel-art" "wallpaper" "digital-art" "photo-manipulation" "science-fiction" "fractal" "game-art" "fantasy" "3d" "drawings-and-paintings" "game-art")
        RAND=$((RANDOM % ${#TOPICS[@]}))
        URL="https://www.deviantart.com/api/v1/oauth2/browse/topic?limit=24&topic=${TOPICS[$RAND]}"
    fi
    CONTENT=$(curl --silent -H "Authorization: Bearer $ACCESS_TOKEN" -H "Accept: application/json" -H "Content-Type: application/json" "$URL")
    mapfile -t URLS <<< "$(echo -n "$CONTENT" | jq -r '.results[].content.src')"
    SIZE=${#URLS[@]}
    IDX=$((RANDOM % SIZE))
    TARGET_URL=${URLS[$IDX]}
    wget --no-check-certificate --quiet --directory-prefix=down --output-document="$TEMP_WALL" "$TARGET_URL"
}

sway_cmd() {
    if [[ -n "$BGTYPE" ]]; then
        if [[ "$BGTYPE" == 'bg-center' ]]; then
            MODE="center"
        fi
        if [[ "$BGTYPE" == 'bg-fill' ]]; then
            MODE="fill"
        fi
        if [[ "$BGTYPE" == 'bg-max' ]]; then
            MODE="fit"
        fi
        if [[ "$BGTYPE" == 'bg-scale' ]]; then
            MODE="stretch"
        fi
        if [[ "$BGTYPE" == 'bg-tile' ]]; then
            MODE="tile"
        fi
    else
        MODE="stretch"
    fi
    swaymsg output "*" bg "$WALLPAPER" "$MODE"

}

nitrogen_cmd() {
    i=0
    while [ "$i" -le "$MONITORS" ]; do
        local NITROGEN_ARR=(nitrogen --save --head="$i")

        if [[ -n "$BGTYPE" ]]; then
            if [[ "$BGTYPE" == 'bg-center' ]]; then
                NITROGEN_ARR+=(--set-centered)
            fi
            if [[ "$BGTYPE" == 'bg-fill' ]]; then
                NITROGEN_ARR+=(--set-zoom-fill)
            fi
            if [[ "$BGTYPE" == 'bg-max' ]]; then
                NITROGEN_ARR+=(--set-zoom)
            fi
            if [[ "$BGTYPE" == 'bg-scale' ]]; then
                NITROGEN_ARR+=(--set-scaled)
            fi
            if [[ "$BGTYPE" == 'bg-tile' ]]; then
                NITROGEN_ARR+=(--set-tiled)
            fi
        else
            NITROGEN_ARR+=(--set-scaled)
        fi

        if [[ -n "$CUSTOM" ]]; then
            NITROGEN_ARR+=("$CUSTOM")
        fi

        NITROGEN_ARR+=("$WALLPAPER")

        "${NITROGEN_ARR[[@]]}"
    done
}

kde_cmd() {
    # cp "$WALLPAPER" "$TEMP_WALL"
    # qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "var allDesktops = desktops();print (allDesktops);for (i=0;i<allDesktops.length;i++) {d = allDesktops[i];d.wallpaperPlugin = \"org.kde.image\";d.currentConfigGroup = Array(\"Wallpaper\", \"org.kde.image\", \"General\");d.writeConfig(\"Image\", \"file:$TEMP_WALL\")}"
    qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "var allDesktops = desktops();print (allDesktops);for (i=0;i<allDesktops.length;i++) {d = allDesktops[i];d.wallpaperPlugin = \"org.kde.image\";d.currentConfigGroup = Array(\"Wallpaper\", \"org.kde.image\", \"General\");d.writeConfig(\"Image\", \"file:$WALLPAPER\")}"
    # sleep 5 && rm "$TEMP_WALL"
}

xfce_cmd() {
    xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/image-path -n -t string -s ~/Pictures/1.jpeg
    xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitorLVDS1/workspace0/last-image -n -t string -s ~/Pictures/1.jpeg

    for i in $(xfconf-query -c xfce4-desktop -p /backdrop -l | grep -E "screen.*/monitor.*image-path$" -e "screen.*/monitor.*/last-image$"); do
        xfconf-query -c xfce4-desktop -p "$i" -n -t string -s "$WALLPAPER"
        xfconf-query -c xfce4-desktop -p "$i"-s "$WALLPAPER"
    done
}

gnome_cmd() {
    gsettings set org.gnome.desktop.background picture-uri "file://$WALLPAPER"
    gsettings set org.gnome.desktop.background picture-uri-dark "file://$WALLPAPER"
}

feh_cmd() {
    local FEH=(feh)
    if [[ -n "$BGTYPE" ]]; then
        if [[ "$BGTYPE" == 'bg-center' ]]; then
            FEH+=(--bg-center)
        fi
        if [[ "$BGTYPE" == 'bg-fill' ]]; then
            FEH+=(--bg-fill)
        fi
        if [[ "$BGTYPE" == 'bg-max' ]]; then
            FEH+=(--bg-max)
        fi
        if [[ "$BGTYPE" == 'bg-scale' ]]; then
            FEH+=(--bg-scale)
        fi
        if [[ "$BGTYPE" == 'bg-tile' ]]; then
            FEH+=(--bg-tile)
        fi
    else
        FEH+=(--bg-scale)
    fi

    if [[ -n "$CUSTOM" ]]; then
        FEH+=("$CUSTOM")
    fi

    FEH+=("$WALLPAPER")

    "${FEH[@]}" >/dev/null 2>&1
}

# 1 is true
# 0 is false
LIGHT=0
MONITORS=1

# SC2034
PARSED_ARGUMENTS=$(getopt -a -n "$0" -o h:w:s:l:b:a:c:d:m:r:pLknxgy:sabi --long search:,height:,width:,fehbg:,bing,fehopt:,artist:,subreddit:,directory:,monitors:,termcolor:,lighwal:,kde,nitrogen,xfce,gnome,sway,save -- "$@")

VALID_ARGUMENTS=$?
if [[ "$VALID_ARGUMENTS" != "0" ]]; then
    usage
    exit
fi
while true; do
    case "$1" in
    -a | --artist)
        ARTIST="$2"
        shift 2
        ;;
    -b | --fehbg)
        BGTYPE="$2"
        shift 2
        ;;
    -bi | --bing)
        BING=1
        shift
        ;;
    -c | --fehopt)
        CUSTOM="$2"
        shift 2
        ;;
    -d | --directory)
        DIR="$2"
        shift 2
        ;;
    -g | --gnome)
        OPT=1
        shift
        ;;
    -h | --height)
        HEIGHT="$2"
        shift 2
        ;;
    -k | --kde)
        OPT=2
        shift
        ;;
    -l | --link)
        LINK="$2"
        shift 2
        ;;
    -m | --monitors)
        MONITORS="$2"
        shift 2
        ;;
    -n | --nitrogen)
        OPT=4
        shift
        ;;
    -r | --subreddit)
        SUB="$2"
        shift 2
        ;;
    -s | --search)
        SEARCH="$2"
        shift 2
        ;;
    -sa | --save)
        SAVE=1
        shift
        ;;
    -x | --xfce)
        OPT=3
        shift
        ;;
    -y | --sway)
        OPT=5
        shift
        ;;
    -w | --width)
        WIDTH="$2"
        shift 2
        ;;
    -- | '')
        shift
        break
        ;;
    *)
        die "unexpect"
        usage
        ;;
    esac
done

run_stylish() {
    if [[ -n "$DIR" ]]; then
        if select_random_wallpaper; then
            printf "Stylish set %s as wallpaper.\n" "$(basename "$WALLPAPER")"
        fi
    elif [[ "$SAVE" -eq "1" ]]; then
        if save_cmd; then
            printf "Stylish saved current wallpaper to %s.\n" "$SAVED_WALLPAPER"
        fi
    else
        [[ "$BING" -eq "1" ]] && bing_daily
        [[ -n "$SEARCH" ]] && unsplash
        [[ -n "$ARTIST" ]] && deviantart "$ARTIST"
        if [[ -n "$SUB" ]]; then 
            reddit "$SUB"
        # else
        #     reddit
        fi
        type_check
        printf "Background is updated.\n"
    fi
    case $OPT in
    1)
        gnome_cmd
        ;;
    2)
        kde_cmd
        ;;
    3)
        xfce_cmd
        ;;
    4)
        nitrogen_cmd
        ;;
    5)
        sway_cmd
        ;;
    *)
        feh_cmd 2>/dev/null
        ;;
    esac
}


if wget --quiet --spider http://google.com; then
    #echo "Online"
    run_stylish
else
    die "internet"
fi