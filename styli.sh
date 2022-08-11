#!/usr/bin/env bash
# shellcheck disable=SC2120,SC2154,SC1090,SC2034

# SC2120: foo references arguments, but none are ever passed.
# SC1090: Can't follow non-constant source. Use a directive to specify location.
# SC2154: var is referenced but not assigned.
# SC2034: foo appears unused. Verify it or export it.

# ┏━┳┓╋╋╋╋┏┳━┳┓
# ┃━┫┗┳┳┳┓┣┫━┫┗┓
# ┣━┃┏┫┃┃┗┫┣━┃┃┃
# ┗━┻━╋┓┣━┻┻━┻┻┛
# ╋╋╋╋┗━┛━━┛
# sourced from https://github.com/mfgbhatti/styli.sh
#

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

CONFIG_FILE="$CONFDIR/stylish.conf"

source_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        source "$CONFIG_FILE"
    else
        die "There is no config file."
    fi
}

test() {
    # For testing purposes
    # de_check
    source_config
    printf "This is a test\n"
    exit 0
}

gnome_cmd() {
    if ! gsettings set org.gnome.desktop.background picture-uri "$FILE"; then
        die "no-gsettings"
    fi
    if ! gsettings set org.gnome.desktop.background picture-uri-dark "$FILE"; then
        die "no-gsettings"
    fi
}

kde_cmd() {
    qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "var allDesktops = desktops();print (allDesktops);for (i=0;i<allDesktops.length;i++) {d = allDesktops[i];d.wallpaperPlugin = \"org.kde.image\";d.currentConfigGroup = Array(\"Wallpaper\", \"org.kde.image\", \"General\");d.writeConfig(\"Image\", \"file:$WALLPAPER\")}"
}

mate_cmd() {
    gsettings set org.mate.background show-desktop-icons false
    sleep 1
    gsettings set org.mate.background show-desktop-icons true
    if ! gsettings set org.mate.background picture-filename "$WALLPAPER"; then
        die "no-gsettings"
    fi
}

cinnamon_cmd () {
    if ! gsettings set org.cinnamon.desktop.background picture-uri "$FILE"; then
        die "no-gsettings"
    fi
}

lxde_cmd() {
    pcmanfm --wallpaper-mode=fit --set-wallpaper="$WALLPAPER"
}

xfce_cmd() {
    readarray -t PROP_ARR < "$(xfconf-query --channel xfce4-desktop --property /backdrop -l | grep -E "screen.*/monitor.*image-path$" -e "screen.*/monitor.*/last-image$")"
       for PROP in "${PROP_ARR[@]}"; do
        xfconf-query --channel xfce4-desktop --property "$PROP" --create --type string --set "$WALLPAPER"
        xfconf-query --channel xfce4-desktop --property "$PROP" --set "$WALLPAPER"
    done 
}

nitrogen_cmd() {
    nitrogen --set-auto --save --file "$WALLPAPER"
}

feh_cmd() {
    feh --bg-fill "$WALLPAPER"
}

sway_cmd() {
    swaybg set "$WALLPAPER"
}

paywal_cmd() {
    paywal -i "$WALLPAPER"
}

select_de() {
    PS3="Please enter your option: "
    select DE in "${SELECT_DE[@]}"; do
        case $DE in
        "gnome")
            gnome_cmd
            break
            ;;
        "kde")
            kde_cmd
            break
            ;;
        "mate")
            mate_cmd
            break
            ;;
        "cinnamon")
            cinnamon_cmd
            break
            ;;
        "lxde")
            lxde_cmd
            break
            ;;
        "xfce")
            xfce_cmd
            break
            ;;
        "nitrogen")
            nitrogen_cmd
            break
            ;;
        "feh")
            feh_cmd
            break
            ;;
        "sway")
            sway_cmd
            break
            ;;
        "paywal")
            paywal_cmd
            break
            ;;
        "none")
            die "This is not supported yet."
            break
            ;;
        *)  
            die "unexpect"
            break
            ;;
        esac
    done
    printf "Stylish updated your wallpaper!\n"
}

de_check() {
    DE_LIST=("gnome" "kde" "mate" "cinnamon" "lxde" "xfce")
    PAT="gnome|kde|mate|cinnamon|lxde|xfce"
    PS_DE=$(pgrep -l "$PAT" | tail -1 | cut -d ' ' -f 2 | sed -E 's/(.*)-.*/\1/')
    SELECT_DE=("gnome" "kde" "mate" "cinnamon" "lxde" "xfce" "nitrogen" "feh" "sway" "pywal" "none")
    if [[ "${DE_LIST[*]}" =~  $PS_DE ]]; then
        "$PS_DE"_cmd
    elif [[ "${XDG_CURRENT_DESKTOP,,}" == "$DESKTOP_SESSION" ]]; then
        CURRENT_DE="${XDG_CURRENT_DESKTOP,,}"
        if [[ "${DE_LIST[*]}" =~ $CURRENT_DE ]]; then
            "$CURRENT_DE"_cmd
        else
            select_de
        fi
    else
        select_de
    fi
}

type_check() {
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

do_download() {
    find "$(dirname "$2")" -name "$(basename "$2")" -mmin +120 -exec rm {} \; 2>/dev/null
    if [ ! -f "$2" ]; then
        wget --timeout="$TIMEOUT" --user-agent="$USERAGENT" --no-check-certificate --quiet --output-document="$2" "$1"
    fi
}

putup_wallpaer() {
    wget --timeout="$TIMEOUT" --user-agent="$USERAGENT" --no-check-certificate --quiet --output-document="$TEMP_WALL" "$TARGET_URL"
    type_check
    de_check
}

save_cmd() {
    WALLPAPER=$(gsettings get org.gnome.desktop.background picture-uri | sed "s/file:\/\///;s/'//g")
    if [[ -f "$WALLPAPER" ]]; then
        if [[ -d "$DEST" ]]; then
            if [[ -w "$DEST" ]]; then
                if [[ ! -f "$DEST/$(basename "$SAVED_WALLPAPER")" ]]; then
                    cp "$WALLPAPER" "$SAVED_WALLPAPER"
                    printf "Stylish saved current wallpaper to %s.\n" "$SAVED_WALLPAPER"
                else
                    die "Already exists"
                fi
            else
                die "You do not have write permissions."
            fi
        else
            die "Stylish is unable to locate."
        fi
    else
        die "Wallpaper is not found."
    fi
}

unsplash() {
    SEARCH="${SEARCH// /_}"
    if [[ -n "$HEIGHT" || -n "$WIDTH" ]]; then
        # keeping {} for $LINK value
        TARGET_URL="${UNSPLASH}$WIDTHx$HEIGHT"
    else
        TARGET_URL="${UNSPLASH}1920x1080"
    fi

    if [[ -n "$SEARCH" ]]; then
        TARGET_URL="${UNSPLASH}/?$SEARCH"
    fi
    putup_wallpaer
}

bing_daily() {
    do_download "$BING_URL" "$BING_CACHE"
    if [[ -z "$1" ]]; then
        URL=$(jq '.images[0].url' <"$BING_CACHE" | sed -e 's/^"//' -e 's/"$//')
    else
        mapfile -t URLS <<<"$(jq '.images[].url'  <"$BING_CACHE" | sed -E 's/^"//;s/"$//')"
        mapfile -t DATES <<<"$(jq '.images[].startdate'  <"$BING_CACHE" | sed -E 's/^"//;s/"$//')"
        while [ "$EXEC_TIME" -le "${#URLS[@]}" ]; do #8
            if [[ "$EXEC_TIME" -eq "1" ]]; then
                set_option "BING_DATE" "${DATES[$EXEC_TIME]}"
                URL="${URLS[$EXEC_TIME]}"
                EXEC_TIME=$((EXEC_TIME + 1))
                set_option "EXEC_TIME" "$EXEC_TIME"
                break
            elif [[ "$EXEC_TIME" -gt "1" && "$EXEC_TIME" -lt "8" ]]; then
                NEW_DATE=$((BING_DATE - 1))
                set_option "BING_DATE" "$NEW_DATE"
                EXEC_TIME=$((EXEC_TIME + 1))
                set_option "EXEC_TIME" "$EXEC_TIME"
                URL="${URLS[$EXEC_TIME]}"
                break
            elif [[ "$EXEC_TIME" -eq "8" ]]; then
                set_option "BING_DATE" "${DATES[1]}"
                set_option "EXEC_TIME" "1"
                URL="${URLS[1]}"
                break
            fi
        done
    fi
    TARGET_URL="http://www.bing.com"${URL}
    putup_wallpaer
}

daily_picsum() {
    do_download "$PICSUM_URL" "$PICSUM_CACHE"
    mapfile -t URLS <<<"$(jq '.[] | .download_url' <"$PICSUM_CACHE" | sed 's/\"//g')"
    wait # prevent spawning too many processes
    SIZE=${#URLS[@]}
    if [[ "$SIZE" -eq 0 ]]; then
        die "not-valid"
    fi
    IDX=$((RANDOM % SIZE))
    TARGET_URL=${URLS[$IDX]}
    putup_wallpaer
}

select_random_wallpaper() {
    do_wallpaper() {
        WALLPAPER="$(find "$DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.svg" -o -iname "*.gif" \) -print | shuf -n 1)"
        if [[ -f "$WALLPAPER" ]]; then
            de_check
        else
            die "No wallpaper found"
        fi
    }

    if [[ "$DIR" =~ ^/ ]]; then
        if [[ -d "$DIR" ]]; then
            if [[ -w "$DIR" ]]; then
                do_wallpaper
            else
                die "You don't have permissions"
            fi
        else
            die "Invalid directory"
        fi
    else
        read -r -p "Is $DIR in your home directory? [y/N] " RESPONSE
        case $RESPONSE in
        y | Y | yes | YES)
            DIR="$HOME/$DIR"
            do_wallpaper
            ;;
        n | N | no | NO)
            read -r -p "Please enter a full or absolute path.\n" OPTS
            DIR="$OPTS"
            do_wallpaper
            ;;
        *)
            die "unexpect"
            ;;
        esac
    fi
}

reddit() {
    if [[ -n "$1" ]]; then
        SUB="$1"
    else
        if [[ ! -f "$SUBS" ]]; then
            write_subs
        fi
        readarray SUBREDDITS <"$SUBS"
        a=${#SUBREDDITS[@]}
        b=$((RANDOM % a))
        SUB=${SUBREDDITS[$b]}
        SUB="$(echo -e "$SUB" | tr -d '[:space:]')"
    fi

    SORT="$2"
    TOP_TIME="$3"
    if [[ -z "$SORT" ]]; then
        SORT="hot"
    fi
    URL="https://www.reddit.com/r/$SUB/$SORT.json?raw_json=1&t=$TOP_TIME"
    CONTENT=$(wget --timeout="$TIMEOUT" --user-agent="$USERAGENT" --quiet -O - "$REDDIT_URL")
    if [[ -z "$TOP_TIME" ]]; then
        TOP_TIME=""
    fi

    mapfile -t URLS <<<"$(echo -n "$CONTENT" | jq -r '.data.children[]|select(.data.post_hint|test("image")?) | .data.preview.images[0].source.url')"
    wait # prevent spawning too many processes
    SIZE=${#URLS[@]}
    if [[ "$SIZE" -eq 0 ]]; then
        die "not-valid"
    fi
    IDX=$((RANDOM % SIZE))
    TARGET_URL=${URLS[$IDX]}
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
    mapfile -t URLS <<<"$(echo -n "$CONTENT" | jq -r '.results[].content.src')"
    wait # prevent spawning too many processes
    SIZE=${#URLS[@]}
    if [[ "$SIZE" -eq 0 ]]; then
        die "not-valid"
    fi
    IDX=$((RANDOM % SIZE))
    TARGET_URL=${URLS[$IDX]}
    putup_wallpaer
}

help() {
    echo -ne "
    NAME
        styli.sh - A simple bash script to manage your desktop background wallpaper.
    SYNOPSIS
        styli.sh <operation>
        styli.sh <operation> [options]
    DESCRIPTION
        Styli.sh is a Bash script that aims to automate the tedious process of finding 
        new wallpapers, downloading and switching them via the configs. Styli.sh can 
        search for specific wallpapers from unsplash or download a random image from 
        bing, picsum, deviantart and the specified subreddits.
    OPERATIONS    
        Following operations can be used with/without options
    -h, --help
        Print this help message
    -v, --version
        Print the version of styli.sh
    -a, --artist [ARTIST]
        Set the artist to search for wallpaper on deviantart
    -b, --bing
        Set the daily bing wallpaper
    -d, --directory [PATH]
        Set wallpaper randomly from the directory
    -l, --link [URL]
        Set the wallpaper from the given url
    -p, --picsum
        Set the wallpaper from the picsum api
    -pb, --pre-bing
        Set the wallpaper cycling through the bing wallpapers
    -r, --reddit [SUBREDDIT]
        Set the wallpaper from the given subreddit
    -s, --search [QUERY]
        Set the wallpaper from the given query from unsplash
    -sa, --save
        Save the current wallpaper to ~/Pictures/wallpapers
    -t, --test
        It is development option, to try out different commands in script

    CONFIGURATION
        styli.sh config file is located at ~/.config/styli.sh/stylish.conf
        for subreddits use file at ~/.config/styli.sh/subreddits

    \n"
    exit 0
}

usage() {
    echo -ne "
    USAGE
        styli.sh <operation>
        styli.sh <operation> [options]
    -a, --artist [ARTIST]
        Set the artist to search for wallpaper on deviantart
    -b, --bing
        Set the daily bing wallpaper
    -d, --directory [PATH]
        Set wallpaper randomly from the directory
    -l, --link [URL]
        Set the wallpaper from the given url
    -p, --picsum
        Set the wallpaper from the picsum api
    -pb, --pre-bing
        Set the wallpaper cycling through the bing wallpapers
    -r, --reddit [SUBREDDIT]
        Set the wallpaper from the given subreddit
    -s, --search [QUERY]
        Set the wallpaper from the given query from unsplash
    -sa, --save
        Save the current wallpaper to ~/Pictures/wallpapers
    \n"
}

version() {
    VERSION="0.0.10"
    printf "styli.sh is at %s version\n" "$VERSION"
}

# SC2034
PARSED_ARGUMENTS=$(getopt -a -n "$0" -o a:d:l:r:s:u:bhppbsatv --long artist:,directory:,url:,reddit:,search:,bing,help,pre-bing,picsum,save,test,version -- "$@")

VALID_ARGUMENTS=$?
if [[ "$VALID_ARGUMENTS" != "0" ]]; then
    usage
    exit
fi
while true; do
    case "$1" in
    -a | --artist)
        OPT=artist
        ARTIST="$2"
        shift 2
        ;;
    -b | --bing)
        OPT=bing
        shift
        ;;
    -d | --directory)
        OPT=directory
        DIR="$2"
        shift 2
        ;;
    -h | --help)
        help | less
        exit
        ;;
    -u | --url) # not implemented yet
        OPT=url
        LINK="$2"
        shift 2
        ;;
    -p | --picsum)
        OPT=picsum
        shift
        ;;
    -pb | --pre-bing)
        OPT=prebing
        shift
        ;;
    -r | --subreddit)
        OPT=subreddit
        SUB="$2"
        shift 2
        ;;
    -s | --search)
        OPT=search
        SEARCH="$2"
        shift 2
        ;;
    -sa | --save)
        OPT=save
        SAVE=1
        shift
        ;;
    -t | --test)
        test
        ;;
    -v | --version)
        version
        break
        ;;
    -- | '')
        shift
        break
        ;;
    *)
        usage
        ;;
    esac
done

run_stylish() {
    case $OPT in
    artist)
        deviantart "$ARTIST"
        ;;
    bing)
        bing_daily
        ;;
    directory)
        select_random_wallpaper "$DIR"
        ;;
    url)
        if [[ "$LINK" =~ subreddit ]]; then
            reddit
        else
            deviantart
        fi
        ;;
    prebing)
        bing_daily "pre"
        ;;
    picsum)
        daily_picsum
        ;;
    subreddit)
        reddit "$SUB"
        ;;
    search)
        unsplash "$SEARCH"
        ;;
    save)
        save_cmd
        ;;
    *)
        die "unexpect"
        ;;
    esac
}

root_check() {
    if [[ "$(id -u)" == "0" ]]; then
        echo -ne "ERROR: Stylish must not be run under the 'root' user!\n"
        exit 1
    fi
}

source_config
if wget --quiet --spider http://google.com; then
    #echo "Online"
    if root_check; then
        run_stylish
    fi
else
    die "internet"
fi
