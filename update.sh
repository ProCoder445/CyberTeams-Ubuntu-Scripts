#!/usr/bin/env bash


source ./MacOS-sudo-replace.sh

sudo apt update -y &&  sudo apt dist-upgrade -y;

echo "If you're on Mint, have you run the \"Reset Config Files\" (In the Update Manager)";

exit 0;
