#!/usr/bin/env bash
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
    [ -b  | --bing <bing daily wallpaper>]
    [ -d  | --directory ]
    [ -g  | --gnome ]
    [ -h  | --help ]
    [ -l  | --link <source> ]
    [ -r  | --subreddit <subreddit> <sort(top,hot)> ]
    [ -s  | --search <string> ]
    [ -sa | --save <Save current image to pictures directory> ]
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

gnome_cmd() {
    gsettings set org.gnome.desktop.background picture-uri "file://$WALLPAPER"
    gsettings set org.gnome.desktop.background picture-uri-dark "file://$WALLPAPER"
    printf "Stylish updated your wallpaper!\n"
}

putup_wallpaer() {
    type_check
    gnome_cmd
}

save_cmd() {
    SAVED_WALLPAPER="$HOME/Pictures/wallpapers/stylish-$RANDOM.jpg"
    if [[ -f "$WALLPAPER" ]]; then
        if [[ -d "$HOME/Pictures" ]]; then
            if [[ ! -f "$HOME/Pictures/wallpapers/$(basename "$SAVED_WALLPAPER")" ]]; then
                cp "$WALLPAPER" "$SAVED_WALLPAPER"
                printf "Stylish saved current wallpaper to %s.\n" "$SAVED_WALLPAPER"
            else
                printf "%s already exists in $HOME/Pictures\n" "$(basename "$SAVED_WALLPAPER")"
            fi
        else
            printf "Pictures directory is not found. Please create it in %s.\n" "$HOME"
        fi
    else
        printf "%s is not found.\n" "$WALLPAPER"
    fi
}

unsplash() {
    SEARCH="${SEARCH// /_}"
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
    putup_wallpaer
}

bing_daily() {
    JSON=$(curl --silent "http://www.bing.com/HPImageArchive.aspx?format=js&idx=0&n=1")
    URL=$(echo "$JSON" | jq '.images[0].url' | sed -e 's/^"//'  -e 's/"$//')
    IMAGE_URL="http://www.bing.com"${URL}
    wget --quiet --output-document="$TEMP_WALL" "$IMAGE_URL"
    putup_wallpaer
}

select_random_wallpaper() {
    WALLPAPER="$(find "$DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.svg" -o -iname "*.gif" \) -print | shuf -n 1)"
    #check if file is present
    if [[ -f "$WALLPAPER" ]]; then
        gnome_cmd
        printf "Stylish set %s.\n" "$(basename "$WALLPAPER")"
    else
        printf "No wallpaper found in %s\n" "$DIR"
        exit 1
    fi
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
    putup_wallpaer
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
    putup_wallpaer
}

# SC2034
PARSED_ARGUMENTS=$(getopt -a -n "$0" -o a:d:l:r:s:bhsa --long artist:,directory:,link:,subreddit:,search:,bing,gnome,help,save -- "$@")

VALID_ARGUMENTS=$?
if [[ "$VALID_ARGUMENTS" != "0" ]]; then
    usage
    exit
fi
while true; do
    case "$1" in
    -a | --artist)
        OPT=1
        ARTIST="$2"
        shift 2
        ;;
    -b | --bing)
        OPT=2
        shift
        ;;
    -d | --directory)
        OPT=3
        DIR="$2"
        shift 2
        ;;
    -g | --gnome)
        OPT=4
        shift
        ;;
    -h | --help)
        usage
        exit
        ;;
    -l | --link) # not implemented yet
        OPT=5
        LINK="$2"
        shift 2
        ;;
    -r | --subreddit)
        OPT=6
        SUB="$2"
        shift 2
        ;;
    -s | --search)
        OPT=7
        SEARCH="$2"
        shift 2
        ;;
    -sa | --save)
        OPT=8
        SAVE=1
        shift
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
    case $OPT in
    1)
        deviantart "$ARTIST"
        ;;
    2)
        bing_daily
        ;;
    3)
        select_random_wallpaper
        ;;
    4)
        gnome_cmd
        ;;
    5)
        printf "Not implemented yet.\n"
        ;;
    6)
        reddit "$SUB"
        ;;
    7)
        unsplash
        ;;
    8)
        save_cmd
        ;;
    *)
        die "unexpect"
        ;;
    esac
}


if wget --quiet --spider http://google.com; then
    #echo "Online"
    run_stylish
else
    die "internet"
fi