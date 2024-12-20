#!/bin/bash
#|---/ /+------------------+---/ /|#
#|--/ /-| Global functions |--/ /-|#
#|-/ /--| Prasanth Rangan  |-/ /--|#
#|/ /---+------------------+/ /---|#

set -e

scrDir="$(dirname "$(realpath "$0")")"
cloneDir="$(dirname "${scrDir}")"
confDir="${XDG_CONFIG_HOME:-$HOME/.config}"
cacheDir="$HOME/.cache/hyde"
aurList=(yay paru)  # Unused for Debian/Fedora but kept for reference
shlList=(zsh fish)

# Check if a package is installed
pkg_installed() {
    local PkgIn=$1

    if command -v apt &>/dev/null; then
        dpkg -l | grep -qw "${PkgIn}"
    elif command -v dnf &>/dev/null; then
        rpm -q "${PkgIn}" &>/dev/null
    else
        echo "Unsupported package manager. Install apt or dnf."
        return 1
    fi
}

# Check a list of packages and return the first one installed
chk_list() {
    vrType="$1"
    local inList=("${@:2}")
    for pkg in "${inList[@]}"; do
        if pkg_installed "${pkg}"; then
            printf -v "${vrType}" "%s" "${pkg}"
            export "${vrType}"
            return 0
        fi
    done
    return 1
}

# Check if a package is available for installation
pkg_available() {
    local PkgIn=$1

    if command -v apt &>/dev/null; then
        apt-cache show "${PkgIn}" &>/dev/null
    elif command -v dnf &>/dev/null; then
        dnf list "${PkgIn}" &>/dev/null
    else
        echo "Unsupported package manager. Install apt or dnf."
        return 1
    fi
}

# NVIDIA GPU detection
nvidia_detect() {
    # Detect NVIDIA GPUs
    readarray -t dGPU < <(lspci -k | grep -E "(VGA|3D)" | awk -F ': ' '{print $NF}')

    # Verbose output option
    if [ "${1}" == "--verbose" ]; then
        for indx in "${!dGPU[@]}"; do
            echo -e "\033[0;32m[gpu$indx]\033[0m detected // ${dGPU[indx]}"
        done
        return 0
    fi

    # Drivers option
    if [ "${1}" == "--drivers" ]; then
        # Identify the distribution
        if command -v apt >/dev/null; then
            pkg_manager="Debian-based"
            pkg_name="nvidia-driver"
        elif command -v dnf >/dev/null; then
            pkg_manager="Fedora"
            pkg_name="akmod-nvidia"
        else
            echo "Unsupported distribution."
            return 1
        fi

        echo "Drivers for detected NVIDIA GPUs should be installed using ${pkg_manager}'s package manager."
        echo "Recommended package: ${pkg_name}"
        return 0
    fi

    # Check if NVIDIA GPU is present
    if grep -iq nvidia <<< "${dGPU[@]}"; then
        return 0
    else
        return 1
    fi
}

# Prompt with a timer
prompt_timer() {
    set +e
    unset promptIn
    local timsec=$1
    local msg=$2
    while [[ ${timsec} -ge 0 ]]; do
        echo -ne "\r :: ${msg} (${timsec}s) : "
        read -t 1 -n 1 promptIn
        [ $? -eq 0 ] && break
        ((timsec--))
    done
    export promptIn
    echo ""
    set -e
}
# Detect package manager
detect_package_manager() {
    if command -v apt &> /dev/null; then
        export PKG_MANAGER="apt"
        export PKG_INSTALL_CMD="sudo apt install -y"
        export PKG_UPDATE_CMD="sudo apt update -y"
    elif command -v dnf &> /dev/null; then
        export PKG_MANAGER="dnf"
        export PKG_INSTALL_CMD="sudo dnf install -y"
        export PKG_UPDATE_CMD="sudo dnf update -y"
    elif command -v pacman &> /dev/null; then
        export PKG_MANAGER="pacman"
        export PKG_INSTALL_CMD="sudo pacman -S --noconfirm"
        export PKG_UPDATE_CMD="sudo pacman -Syu --noconfirm"
    else
        echo "Unsupported package manager. Exiting..."
        exit 1
    fi
}