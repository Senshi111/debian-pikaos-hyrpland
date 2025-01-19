#!/bin/bash

# Set variables
scrDir="$(dirname "$(realpath "$0")")"
confDir="${confDir}/config"

# Source global control script
# shellcheck source=/dev/null
. "${scrDir}/globalcontrol.sh"

# Default rofi style if not set
rofiStyle="${rofiStyle:-1}"

# Check if rofiStyle is a number or not and assign the correct config
if [[ "${rofiStyle}" =~ ^[0-9]+$ ]]; then
    rofi_config="style_${rofiStyle:-1}"
else
    rofi_config="${rofiStyle:-"style_1"}"
fi

# Override with environment variable if set
rofi_config="${ROFI_LAUNCH_STYLE:-$rofi_config}"

# Set scale for the launcher
rofiScale="${ROFI_LAUNCHER_SCALE}"
[[ "${rofiScale}" =~ ^[0-9]+$ ]] || rofiScale=${ROFI_SCALE:-10}

# Rofi action based on first argument
case "${1}" in
    d | --drun) r_mode="drun" ;;
    w | --window) r_mode="window" ;;
    f | --filebrowser) r_mode="filebrowser" ;;
    r | --run) r_mode="run" ;;
    h | --help)
        echo -e "$(basename "${0}") [action]"
        echo "d :  drun mode"
        echo "w :  window mode"
        echo "f :  filebrowser mode"
        exit 0
        ;;
    *) r_mode="drun" ;;
esac

# Set overrides for Hyprland window appearance
hypr_border="${hypr_border:-10}"
hypr_width="${hypr_width:-2}"
wind_border=$((hypr_border * 3))

# Check for fullscreen mode and adjust border settings accordingly
if [[ "$ROFI_LAUNCH_FULLSCREEN" == "true" ]]; then
    hypr_width="0"
    wind_border="0"
fi

# Set element borders based on hypr_border setting
[ "${hypr_border}" -eq 0 ] && elem_border="10" || elem_border=$((hypr_border * 2))

# Override Rofi settings
r_override="window {border: ${hypr_width}px; border-radius: ${wind_border}px;} element {border-radius: ${elem_border}px;}"
r_scale="configuration {font: \"JetBrainsMono Nerd Font ${rofiScale}\";}"
i_override="$(get_hyprConf "ICON_THEME")"
i_override="configuration {icon-theme: \"${i_override}\";}"

# Launch Rofi in the specified mode and with the specified customizations
rofi -show "${r_mode}" \
    -show-icons \
    -config "${rofi_config}" \
    -theme-str "${r_scale}" \
    -theme-str "${i_override}" \
    -theme-str "${r_override}" \
    -theme "${rofi_config}" &
disown

# Detect fullscreen state from the theme and set the appropriate environment variable
rofi_theme_output=$(rofi -show "${r_mode}" \
    -show-icons \
    -config "${rofi_config}" \
    -theme-str "${r_scale}" \
    -theme-str "${i_override}" \
    -theme-str "${r_override}" \
    -theme "${rofi_config}" \
    -dump-theme)

# Check for fullscreen state after rendering the theme
if echo "${rofi_theme_output}" | grep -q "fullscreen.*true"; then
    set_conf "ROFI_LAUNCH_FULLSCREEN" "true"
else
    set_conf "ROFI_LAUNCH_FULLSCREEN" "false"
fi
