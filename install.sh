#!/usr/bin/env bash
# 
# ┏━┳┓╋╋╋╋┏┳━┳┓
# ┃━┫┗┳┳┳┓┣┫━┫┗┓
# ┣━┃┏┫┃┃┗┫┣━┃┃┃
# ┗━┻━╋┓┣━┻┻━┻┻┛
# ╋╋╋╋┗━┛━━┛
#
# sourced from https://github.com/mfgbhatti/styli.sh
#
if [[ -z ${XDG_CONFIG_HOME} ]]; then
    XDG_CONFIG_HOME="$HOME/.config"
fi

CONFDIR="${XDG_CONFIG_HOME}/styli.sh"
if [[ ! -d "$CONFDIR" ]]; then
    mkdir -p "$CONFDIR"
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
MAIN_SCRIPT="$SCRIPT_DIR/styli.sh"
CONFIG="$SCRIPT_DIR/stylish.conf"
DEST="/usr/bin/styli.sh"
CONFIG_FILE="${XDG_CONFIG_HOME}/styli.sh/stylish.conf"
SUBS="${XDG_CONFIG_HOME}/styli.sh/subreddits"

write_subs() {
    cat <<EOT >"$SUBS"
EarthPorn
CityPorn
SkyPorn
WeatherPorn
BotanicalPorn
LakePorn
VillagePorn
BeachPorn
WaterPorn
SpacePorn
EOT
}

copy_files() {
    if [[ -f "$CONFIG_FILE" ]]; then
        read -r -p "Config already exist, do you want it to remove [y/N]: " OPT
        case "$OPT" in
            y | Y | yes | YES)
            rm -rf "$CONFIG_FILE"
            if ! cp "$CONFIG" "$CONFIG_FILE"; then
                printf "%s cannot be copied" "$CONFIG"
            fi
            ;;
            n | N | no | No)
            printf "Skipping\n"
            ;;
            *) printf "Unknown option\n";exit 0;;
        esac
    else
        if ! cp "$CONFIG" "$CONFIG_FILE"; then
            printf "%s cannot be copied" "$CONFIG"
        fi
    fi
    write_subs
    chmod +x "$MAIN_SCRIPT"
    printf "install.sh needs to move styli.sh to /usr/bin/styli.sh\n"
    printf "or you can move it yourself to your /usr/bin or /usr/local/bin\n"
    if ! sudo cp "$MAIN_SCRIPT" "$DEST"; then
        printf "ERROR! Stylish must be installed using root privileges!\n"
        printf "install.sh needs to move styli.sh to /usr/bin/styli.sh\n"
        printf "Please run install.sh with sudo.\n"
        printf "Exiting...\n"
        exit 0
    fi
    printf "Stylish installed successfully!\n"    
}

copy_files