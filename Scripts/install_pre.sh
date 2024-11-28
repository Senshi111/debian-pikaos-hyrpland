#!/bin/bash
#|---/ /+-------------------------------------+---/ /|#
#|--/ /-| Script to apply pre-install configs |--/ /-|#
#|-/ /--| Adapted for Debian and Fedora       |-/ /--|#
#|/ /---+-------------------------------------+/ /---|#

scrDir=$(dirname "$(realpath "$0")")
source "${scrDir}/global_fn.sh"
if [ $? -ne 0 ]; then
    echo "Error: unable to source global_fn.sh..."
    exit 1
fi

# Detect package manager
detect_package_manager() {
    if command -v apt &>/dev/null; then
        export PKG_MANAGER="apt"
        export GRUB_CMD="update-grub"
    elif command -v dnf &>/dev/null; then
        export PKG_MANAGER="dnf"
        export GRUB_CMD="grub2-mkconfig -o /boot/grub2/grub.cfg"
    else
        echo "Unsupported package manager. Exiting..."
        exit 1
    fi
}

detect_package_manager

# GRUB configuration
if pkg_installed grub && [ -f /boot/grub/grub.cfg ]; then
    echo -e "\033[0;32m[BOOTLOADER]\033[0m detected // grub"

    if [ ! -f /etc/default/grub.t2.bkp ] && [ ! -f /boot/grub/grub.t2.bkp ]; then
        echo -e "\033[0;32m[BOOTLOADER]\033[0m configuring grub..."
        sudo cp /etc/default/grub /etc/default/grub.t2.bkp
        sudo cp /boot/grub/grub.cfg /boot/grub/grub.t2.bkp

        if nvidia_detect; then
            echo -e "\033[0;32m[BOOTLOADER]\033[0m nvidia detected, adding nvidia_drm.modeset=1 to boot option..."
            gcld=$(grep "^GRUB_CMDLINE_LINUX_DEFAULT=" "/etc/default/grub" | cut -d'"' -f2 | sed 's/\b nvidia_drm.modeset=.\b//g')
            sudo sed -i "/^GRUB_CMDLINE_LINUX_DEFAULT=/c\GRUB_CMDLINE_LINUX_DEFAULT=\"${gcld} nvidia_drm.modeset=1\"" /etc/default/grub
        fi

        echo -e "Select grub theme:\n[1] Retroboot (dark)\n[2] Pochita (light)"
        read -p " :: Press enter to skip grub theme <or> Enter option number : " grubopt
        case ${grubopt} in
            1) grubtheme="Retroboot" ;;
            2) grubtheme="Pochita" ;;
            *) grubtheme="None" ;;
        esac

        if [ "${grubtheme}" == "None" ]; then
            echo -e "\033[0;32m[BOOTLOADER]\033[0m Skipping grub theme..."
            sudo sed -i "s/^GRUB_THEME=/#GRUB_THEME=/g" /etc/default/grub
        else
            echo -e "\033[0;32m[BOOTLOADER]\033[0m Setting grub theme // ${grubtheme}"
            sudo tar -xzf "${cloneDir}/Source/arcs/Grub_${grubtheme}.tar.gz" -C /usr/share/grub/themes/
            sudo sed -i "/^GRUB_DEFAULT=/c\GRUB_DEFAULT=saved
            /^GRUB_GFXMODE=/c\GRUB_GFXMODE=1280x1024x32,auto
            /^GRUB_THEME=/c\GRUB_THEME=\"/usr/share/grub/themes/${grubtheme}/theme.txt\"
            /^#GRUB_THEME=/c\GRUB_THEME=\"/usr/share/grub/themes/${grubtheme}/theme.txt\"
            /^#GRUB_SAVEDEFAULT=true/c\GRUB_SAVEDEFAULT=true" /etc/default/grub
        fi

        sudo ${GRUB_CMD}  # Update grub configuration
    else
        echo -e "\033[0;33m[SKIP]\033[0m grub is already configured..."
    fi
fi

# Package manager configurations
if [ "${PKG_MANAGER}" == "apt" ]; then
    echo -e "\033[0;32m[APT]\033[0m Configuring apt..."
    sudo cp /etc/apt/apt.conf.d/99custom /etc/apt/apt.conf.d/99custom.t2.bkp 2>/dev/null || true
    echo -e "APT::Color \"1\";\nAPT::Install-Recommends \"false\";\nAPT::Install-Suggests \"false\";" | sudo tee /etc/apt/apt.conf.d/99custom
    sudo apt update
    sudo apt upgrade -y
elif [ "${PKG_MANAGER}" == "dnf" ]; then
    echo -e "\033[0;32m[DNF]\033[0m Configuring dnf..."
    sudo cp /etc/dnf/dnf.conf /etc/dnf/dnf.conf.t2.bkp
    sudo sed -i "/^#color/c\color=true" /etc/dnf/dnf.conf
    sudo sed -i "/^#fastestmirror/c\fastestmirror=true" /etc/dnf/dnf.conf
    sudo sed -i "/^#max_parallel_downloads=/c\max_parallel_downloads=10" /etc/dnf/dnf.conf
    sudo dnf upgrade --refresh -y
else
    echo "Error: Unsupported package manager."
    exit 1
fi
