#!/bin/bash

remove=("netcat" "telnet" "john" "ophcrack" "nc" "nmap" "wireshark" "netbus" "keylog" "VNC" "Cryptcat" "crack" "hydra" "telnet")

unsafe_remove=("web" "nc" "cat" "")

for app in ${remove[@]}; do
	sudo apt remove ${app,,} -y
done

echo "Do you want to activate unsafe remove?: "
read -r unsafe_rm

if [[${unsafe_rm,,} == "yes"]]; then
	for app in ${unsafe_remove[@]}; do
		sudo apt remove ${app,,} -y
	done
fi
