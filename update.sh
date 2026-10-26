#!/usr/bin/env bash
# shellcheck source=/dev/null
source ./MacOS-sudo-replace.sh

echo "Are you on Mint? (Y/N): "
read -r Mint;

if [[ "${Mint,,}" == "y" ]]; then
    echo "Have you clicked the \"Reset Configuration\" button (In the Update Manager) yet (Y/N): "
    read -r reset;
    if [[ "${reset,,}" == "n" ]]; then
        echo "You should do that, then come back and rerun the script."
        exit 1;
    fi

fi

sudo apt update -y &&  sudo apt dist-upgrade -y;


exit 0;
