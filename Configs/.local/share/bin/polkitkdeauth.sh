#!/usr/bin/env sh

# Use different directory on NixOS
if [ -d /run/current-system/sw/libexec ]; then
    libDir=/run/current-system/sw/libexec
else
    libDir=/usr/lib
fi

${libDir}/x86_64-linux-gnu/libexec/polkit-kde-authentication-agent-1 &
