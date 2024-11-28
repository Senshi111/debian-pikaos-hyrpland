#!/usr/bin/env bash
#|---/ /+--------------------------------------+---/ /|#
#|--/ /-| Script to apply post-install configs |--/ /-|#
#|-/ /--| Adapted for multiple package managers |-/ /--|#
#|/ /---+--------------------------------------+/ /---|#

scrDir=$(dirname "$(realpath "$0")")
source "${scrDir}/global_fn.sh"
if [ $? -ne 0 ]; then
    echo "Error: unable to source global_fn.sh..."
    exit 1
fi

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
if pkg_installed sddm; then
    echo -e "\033[0;32m[DISPLAYMANAGER]\033[0m detected // sddm"
    if [ ! -d /etc/sddm.conf.d ]; then
        sudo mkdir -p /etc/sddm.conf.d
    fi

    if [ ! -f /etc/sddm.conf.d/kde_settings.t2.bkp ]; then
        echo -e "\033[0;32m[DISPLAYMANAGER]\033[0m configuring sddm..."
        echo -e "Select SDDM theme:\n[1] Candy\n[2] Corners"
        read -p " :: Enter option number: " sddmopt

        case $sddmopt in
        1) sddmtheme="Candy" ;;
        *) sddmtheme="Corners" ;;
        esac

        sudo tar -xzf "${cloneDir}/Source/arcs/Sddm_${sddmtheme}.tar.gz" -C /usr/share/sddm/themes/
        sudo cp /etc/sddm.conf.d/kde_settings.conf /etc/sddm.conf.d/kde_settings.t2.bkp 2>/dev/null || sudo touch /etc/sddm.conf.d/kde_settings.conf
        sudo cp /usr/share/sddm/themes/${sddmtheme}/kde_settings.conf /etc/sddm.conf.d/
    else
        echo -e "\033[0;33m[SKIP]\033[0m SDDM is already configured..."
    fi

    if [ ! -f /usr/share/sddm/faces/${USER}.face.icon ] && [ -f ${cloneDir}/Source/misc/${USER}.face.icon ]; then
        sudo cp "${cloneDir}/Source/misc/${USER}.face.icon" /usr/share/sddm/faces/
        echo -e "\033[0;32m[DISPLAYMANAGER]\033[0m Avatar set for ${USER}..."
    fi
else
    echo -e "\033[0;33m[WARNING]\033[0m SDDM is not installed..."
fi

# Dolphin Configuration
if pkg_installed dolphin && pkg_installed xdg-utils; then
    echo -e "\033[0;32m[FILEMANAGER]\033[0m detected // dolphin"
    xdg-mime default org.kde.dolphin.desktop inode/directory
    echo -e "\033[0;32m[FILEMANAGER]\033[0m Setting " `xdg-mime query default "inode/directory"` "as default file explorer..."
else
    echo -e "\033[0;33m[WARNING]\033[0m Dolphin is not installed..."
fi

# Restore Shell Settings
"${scrDir}/restore_shl.sh"

# Flatpak Configuration
if ! pkg_installed flatpak; then
    echo -e "\033[0;32m[FLATPAK]\033[0m Flatpak application list:"
    awk -F '#' '$1 != "" {print "["++count"]", $1}' "${scrDir}/.extra/custom_flat.lst"
    read -t 60 -p "Install these Flatpaks? [Y/n]: " fpkopt
    fpkopt=${fpkopt,,}

    if [ "${fpkopt}" = "y" ]; then
        echo -e "\033[0;32m[FLATPAK]\033[0m Installing Flatpaks..."
        "${scrDir}/.extra/install_fpk.sh"
    else
        echo -e "\033[0;33m[SKIP]\033[0m Installing Flatpaks..."
    fi
else
    echo -e "\033[0;33m[SKIP]\033[0m Flatpak is already installed..."
fi
