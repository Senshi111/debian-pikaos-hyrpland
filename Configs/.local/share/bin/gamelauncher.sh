#!/bin/bash

# set variables
MODE=${1:-5}
scrDir=$(dirname "$(realpath "$0")")
source "$scrDir/globalcontrol.sh"
ThemeSet="${confDir}/hypr/themes/theme.conf"
RofiConf="${confDir}/rofi/steam/gamelauncher_${MODE}.rasi"

# set rofi override
elem_border=$(( hypr_border * 2 ))
icon_border=$(( elem_border - 3 ))
r_override="element{border-radius:${elem_border}px;} element-icon{border-radius:${icon_border}px;}"

fn_steam() {
    # check steam mount paths
    if [ ! -f "$SteamLib" ]; then
        notify-send -a "t1" "Steam library file not found: $SteamLib"
        exit 1
    fi

    SteamPaths=$(grep '"path"' "$SteamLib" | awk -F '"' '{print $4}')
    if [ -z "$SteamPaths" ]; then
        notify-send -a "t1" "No Steam paths found in library file."
        exit 1
    fi

    ManifestList=$(find $SteamPaths/steamapps/ -type f -name "appmanifest_*.acf" 2>/dev/null)
    if [ -z "$ManifestList" ]; then
        notify-send -a "t1" "No appmanifest files found in Steam paths."
        exit 1
    fi

    # read installed games
    GameList=$(echo "$ManifestList" | while read -r acf; do
        appid=$(grep '"appid"' "$acf" | cut -d '"' -f 4)
        if [ -f "${SteamThumb}/${appid}_library_600x900.jpg" ]; then
            game=$(grep '"name"' "$acf" | cut -d '"' -f 4)
            echo "$game|$appid"
        fi
    done | sort)

    if [ -z "$GameList" ]; then
        notify-send -a "t1" "No installed games with thumbnails found."
        exit 1
    fi

    # launch rofi menu
    RofiSel=$(echo "$GameList" | while read -r line; do
        appid=$(echo "$line" | cut -d '|' -f 2)
        game=$(echo "$line" | cut -d '|' -f 1)
        echo -en "$game\x00icon\x1f${SteamThumb}/${appid}_library_600x900.jpg\n"
    done | rofi -dmenu -theme-str "${r_override}" -config "$RofiConf")

    # launch game
    if [ -n "$RofiSel" ]; then
        launchid=$(echo "$GameList" | grep "$RofiSel" | cut -d '|' -f 2)
        ${steamlaunch} -applaunch "$launchid" &
        notify-send -a "t1" -i "${SteamThumb}/${launchid}_header.jpg" "Launching $RofiSel..."
    else
        notify-send -a "t1" "No game selected."
    fi
}

fn_lutris() {
[ ! -e "${icon_path}" ] && icon_path="${HOME}/.local/share/lutris/coverart"
[ ! -e "${icon_path}" ] && icon_path="${HOME}/.cache/lutris/coverart"
meta_data="/tmp/hyprdots-$(id -u)-lutrisgames.json"

# Retrieve the list of games from Lutris in JSON format
#TODO Only call this if new apps are installed...
 # [ ! -s "${meta_data}" ] &&
notify-send -a "t1" "Please wait... " -t 4000

eval "${run_lutris}" -j -l 2> /dev/null| jq --arg icons "$icon_path/" --arg prefix ".jpg" '.[] |= . + {"select": (.name + "\u0000icon\u001f" + $icons + .slug + $prefix)}' > "${meta_data}"

[ ! -s "${meta_data}" ] && notify-send -a "t1" "Cannot Fetch Lutris Games!" && exit 1


CHOICE=$(jq -r '.[].select' "${meta_data}" | rofi -dmenu -p Lutris  -theme-str "${r_override}" -config "${RofiConf}" )
[ -z "$CHOICE" ] && exit 0
	SLUG=$(jq -r --arg choice "$CHOICE" '.[] | select(.name == $choice).slug' "${meta_data}"  )
    notify-send -a "t1" -i "${icon_path}/${SLUG}.jpg" "Launching ${CHOICE}..."
	exec xdg-open "lutris:rungame/${SLUG}"
}

# Main logic for handling Steam and Lutris
if [ -z "$run_lutris" ] || echo "$*" | grep -q "steam"; then
    # set steam library paths
    if pkg_installed steam; then
        SteamLib="${XDG_DATA_HOME:-$HOME/.local/share}/Steam/config/libraryfolders.vdf"
        SteamThumb="${XDG_DATA_HOME:-$HOME/.local/share}/Steam/appcache/librarycache"
        steamlaunch="steam"
    else
        SteamLib="$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam/config/libraryfolders.vdf"
        SteamThumb="$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam/appcache/librarycache"
        steamlaunch="flatpak run com.valvesoftware.Steam"
    fi

    if [ ! -f "$SteamLib" ] || [ ! -d "$SteamThumb" ]; then
        notify-send -a "t1" "Steam library or thumbnails not found!"
        exit 1
    fi
    fn_steam
else
    fn_lutris
fi
