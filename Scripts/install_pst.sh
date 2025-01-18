#!/bin/bash
#|---/ /+--------------------------------------+---/ /|#
#|--/ /-| Script to apply post install configs |--/ /-|#
#|-/ /--| Prasanth Rangan                      |-/ /--|#
#|/ /---+--------------------------------------+/ /---|#

scrDir=$(dirname "$(realpath "$0")")
# shellcheck disable=SC1091
if ! source "${scrDir}/global_fn.sh"; then
    echo "Error: unable to source global_fn.sh..."
    exit 1
fi

cloneDir="${cloneDir:-$CLONE_DIR}"
# Detect Package Manager
if command -v apt >/dev/null; then
    PKG_MANAGER="apt"
    INSTALL_CMD="sudo apt install -y"
    UPDATE_CMD="sudo apt update"
    PKG_CHECK_CMD="dpkg -l"
elif command -v dnf >/dev/null; then
    PKG_MANAGER="dnf"
    INSTALL_CMD="sudo dnf install -y"
    UPDATE_CMD="sudo dnf check-update"
    PKG_CHECK_CMD="rpm -q"
elif command -v pacman >/dev/null; then
    PKG_MANAGER="pacman"
    INSTALL_CMD="sudo pacman -S --noconfirm"
    UPDATE_CMD="sudo pacman -Syu --noconfirm"
    PKG_CHECK_CMD="pacman -Q"
else
    echo "Unsupported package manager!"
    exit 1
fi

# Function: Check if a package is installed
pkg_installed() {
    case $PKG_MANAGER in
        apt) $PKG_CHECK_CMD | grep -qw "$1" ;;
        dnf) $PKG_CHECK_CMD "$1" &>/dev/null ;;
        pacman) $PKG_CHECK_CMD "$1" &>/dev/null ;;
        *) echo "Unsupported package manager!"; exit 1 ;;
    esac
}

# SDDM Configuration

# sddm
if pkg_installed sddm; then
    print_log -c "[DISPLAYMANAGER] " -b "detected :: " "sddm"
    if [ ! -d /etc/sddm.conf.d ]; then
        sudo mkdir -p /etc/sddm.conf.d
    fi

    if [ ! -f /etc/sddm.conf.d/kde_settings.hyde.bkp ]; then
        print_log -g "[DISPLAYMANAGER] " -b " :: " "configuring sddm..."
        print_log -g "[DISPLAYMANAGER] " -b " :: " "Select sddm theme:" -r "\n[1]" -b " Candy" -r "\n[2]" -b " Corners"
        read -p " :: Enter option number : " -r sddmopt

        case $sddmopt in
        1) sddmtheme="Candy" ;;
        *) sddmtheme="Corners" ;;
        esac

        sudo tar -xzf "${cloneDir}/Source/arcs/Sddm_${sddmtheme}.tar.gz" -C /usr/share/sddm/themes/
        sudo touch /etc/sddm.conf.d/kde_settings.conf
        sudo cp /etc/sddm.conf.d/kde_settings.conf /etc/sddm.conf.d/kde_settings.hyde.bkp
        sudo cp /usr/share/sddm/themes/${sddmtheme}/kde_settings.conf /etc/sddm.conf.d/
    else
        print_log -y "[DISPLAYMANAGER] " -b " :: " "sddm is already configured..."
    fi

    if [ ! -f "/usr/share/sddm/faces/${USER}.face.icon" ] && [ -f "${cloneDir}/Source/misc/${USER}.face.icon" ]; then
        sudo cp "${cloneDir}/Source/misc/${USER}.face.icon" /usr/share/sddm/faces/
        print_log -g "[DISPLAYMANAGER] " -b " :: " "avatar set for ${USER}..."
    fi

else
    print_log -y "[DISPLAYMANAGER] " -b " :: " "sddm is not installed..."
fi

# dolphin
if pkg_installed dolphin && pkg_installed xdg-utils; then
    print_log -c "[FILEMANAGER] " -b "detected :: " "dolphin"
    xdg-mime default org.kde.dolphin.desktop inode/directory
    print_log -g "[FILEMANAGER] " -b " :: " "setting $(xdg-mime query default "inode/directory") as default file explorer..."

else
    print_log -y "[FILEMANAGER] " -b " :: " "dolphin is not installed..."
    printt_log -y "[FILEMANAGER] " -b " :: " "Setting $(xdg-mime query default "inode/directory") as default file explorer..."
fi

# shell
"${scrDir}/restore_shl.sh"

# flatpak
if ! pkg_installed flatpak; then
    print_log -r "[FLATPAK]" -b "list :: " "flatpak application"
    awk -F '#' '$1 != "" {print "["++count"]", $1}' "${scrDir}/extra/custom_flat.lst"
    prompt_timer 60 "Install these flatpaks? [Y/n]"
    fpkopt=${PROMPT_INPUT,,}

    if [ "${fpkopt}" = "y" ]; then
        print_log -g "[FLATPAK]" -b "install :: " "flatpaks"
        "${scrDir}/extra/install_fpk.sh"
    else
        print_log -y "[FLATPAK]" -b "skip :: " "flatpak installation"
    fi

else
    print_log -y "[FLATPAK]" -b " :: " "flatpak is already installed"
fi
