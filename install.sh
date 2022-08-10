#!/usr/bin/env bash

if [[ -z ${XDG_CONFIG_HOME} ]]; then
    XDG_CONFIG_HOME="$HOME/.config"
fi

CONFDIR="${XDG_CONFIG_HOME}/styli.sh"
if [[ ! -d "$CONFDIR" ]]; then
    mkdir -p "$CONFDIR"
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
MAIN_SCRIPT="$SCRIPT_DIR/stylish.sh"
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
        printf "%s already exists! Skipping\n" "$CONFIG_FILE"
    else
        if ! cp "$CONFIG" "$CONFIG_FILE"; then
            printf "%s cannot be copied" "$CONFIG"
        fi
    fi
    write_subs
    chmod +x "$MAIN_SCRIPT"
    printf "install.sh needs to move styli.sh to /usr/bin/styli.sh\n"
    if ! sudo cp "$MAIN_SCRIPT" "$DEST"; then
        printf "ERROR! Stylish must be installed using root privileges!\n"
        printf "install.sh needs to move styli.sh to /usr/bin/styli.sh\n"
        printf "Please run install.sh as root or with sudo.\n"
        printf "Exiting...\n"
        exit 0
    fi
    
}

copy_files