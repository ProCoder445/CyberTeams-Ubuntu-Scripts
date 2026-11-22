#!/usr/bin/env bash

# shellcheck source=/dev/null
source ./MacOS-sudo-replace.sh;

remove=("telnet" "john" "ophcrack" "nmap" "wireshark" "netbus" "keylog" "VNC" "Cryptcat" "crack" "hydra" "telnet")

unsafe_remove=("web" "nc" "cat" "")

for app in "${remove[@]}"; do
	sudo apt remove "${app,,}" -y
done

echo "Do you want to activate unsafe remove? (Y/N): "
read -r unsafe_rm

if [[ "${unsafe_rm,,}" == "y" ]]; then
	for app in "${unsafe_remove[@]}"; do
		sudo apt remove "${app,,}" -y
	done
fi
