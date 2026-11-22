#!/usr/bin/env bash

source ../MacOS-sudo-replace.sh;

echo "Checking apt sources..."
if [[ -f /etc/apt/sources.list ]]; then
    echo "/etc/apt/sources.list found!"
    cat << 'EOF' > /etc/apt/sources.list
deb http://deb.debian.org/debian bookworm main contrib non-free-firmware
deb http://deb.debian.org/debian bookworm-updates main contrib non-free-firmware
deb http://security.debian.org/debian-security bookworm-security main contrib non-free-firmware
EOF
elif [[ -f /etc/apt/sources.list.d/debian-sources ]]; then
    echo "/etc/apt/sources.list.d/debian-sources found!"
    cat << 'EOF' > /etc/apt/sources.list.d/debian-sources
deb http://deb.debian.org/debian bookworm main contrib non-free-firmware
deb http://deb.debian.org/debian bookworm-updates main contrib non-free-firmware
deb http://security.debian.org/debian-security bookworm-security main contrib non-free-firmware
EOF
fi
echo "apt sources reset for security"

echo "updating..."

sudo apt update -y && sudo apt upgrade -y

echo "Done!"