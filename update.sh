#!/bin/bash

source ./MacOS-sudo-replace.sh

sudo apt update -y &&  sudo apt dist-upgrade -y;

exit 0;
