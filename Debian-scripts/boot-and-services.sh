#!/usr/bin/env bash

source ../MacOS-sudo-replace.sh;

#GRUB2 cfg
#TODO: Set the make sure GRUB2 is installed if not currently on the system.
grub-mkpasswd-pbkdf2 | tail -n 1 | awk '{print $NF}'