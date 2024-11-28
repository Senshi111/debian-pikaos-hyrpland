#!/bin/bash
#|---/ /+---------------------------+---/ /|#
#|--/ /-| Script to configure shell |--/ /-|#
#|-/ /--| Adapted for Debian & Fedora |-/ /--|#
#|/ /---+---------------------------+/ /---|#

scrDir=$(dirname "$(realpath "$0")")
source "${scrDir}/global_fn.sh"
if [ $? -ne 0 ]; then
    echo "Error: unable to source global_fn.sh..."
    exit 1
fi

# Ensure zsh and oh-my-zsh are installed
install_zsh() {
    echo "Installing zsh..."
    $INSTALL_CMD zsh
    if [ $? -ne 0 ]; then
        echo "[ERROR] Failed to install zsh."
        exit 1
    fi
}

install_oh_my_zsh() {
    echo "Installing oh-my-zsh..."
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    if [ $? -ne 0 ]; then
        echo "[ERROR] Failed to install oh-my-zsh."
        exit 1
    fi
}

# Check and install zsh
if ! command -v zsh &>/dev/null; then
    echo "[INFO] zsh not found."
    install_zsh
else
    echo "[INFO] zsh is already installed."
fi

# Check and install oh-my-zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "[INFO] oh-my-zsh not found."
    install_oh_my_zsh
else
    echo "[INFO] oh-my-zsh is already installed."
fi


