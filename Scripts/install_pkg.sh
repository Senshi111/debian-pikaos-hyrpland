#!/bin/bash
#|---/ /+----------------------------------------+---/ /|#
#|--/ /-| Script to install pkgs from input list |--/ /-|#
#|-/ /--| Adapted for Debian and Fedora          |-/ /--|#
#|/ /---+----------------------------------------+/ /---|#

# Get the script directory
scrDir=$(dirname "$(realpath "$0")")
source "${scrDir}/global_fn.sh"
if [ $? -ne 0 ]; then
    echo "Error: unable to source global_fn.sh..."
    exit 1
fi

# Package list input
listPkg="${1:-"${scrDir}/custom_hypr.lst"}"
pkgList=()
processedPackages=()

# Preserve IFS for later restoration
origIFS=$IFS
IFS='|'

# Read and process the package list
while read -r pkg deps; do
    # Trim spaces and skip empty lines or comments
    pkg=$(echo "${pkg}" | xargs)
    if [[ -z "${pkg}" || "${pkg:0:1}" == "#" ]]; then
        continue
    fi

    # Trim and handle dependencies
    deps=$(echo "${deps}" | xargs)
    missingDeps=0
    if [[ -n "${deps}" ]]; then
        for dep in ${deps//,/ }; do
            if ! pkg_installed "${dep}" && ! cut -d '#' -f 1 "${listPkg}" | awk -F '|' -v chk="${dep}" '$1 == chk {exit 1}'; then
                missingDeps=1
                echo -e "\033[0;33m[skip]\033[0m Dependency ${dep} for ${pkg} not satisfied."
                    break
                fi
        done
            fi

    # Skip if dependencies are missing
    if [[ ${missingDeps} -eq 1 ]]; then
            continue
        fi

    # Check if package is already installed
    if pkg_installed "${pkg}"; then
        echo -e "\033[0;33m[skip]\033[0m ${pkg} is already installed..."
    elif pkg_available "${pkg}"; then
        if [[ ! " ${processedPackages[@]} " =~ " ${pkg} " ]]; then
            echo -e "\033[0;32m[repo]\033[0m Queueing ${pkg} from official repository..."
            pkgList+=("${pkg}")
            processedPackages+=("${pkg}")
        fi
    else
        echo -e "\033[0;31m[error]\033[0m Unknown package ${pkg}."
    fi
done < <(cut -d '#' -f 1 "${listPkg}")

# Restore IFS
IFS=${origIFS}

# Install queued packages
if [[ ${#pkgList[@]} -gt 0 ]]; then
    if command -v apt &>/dev/null; then
        sudo apt update
        sudo apt install -y "${pkgList[@]}"
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y "${pkgList[@]}"
    else
        echo "Error: Unsupported package manager."
        exit 1
    fi
else
    echo "No packages to install."
fi
