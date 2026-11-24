#!/usr/bin/env bash

source ../MacOS-sudo-replace.sh;

#GRUB2 cfg
GRUB2_passwd=$(grub-mkpasswd-pbkdf2 | tail -n 1 | awk '{print $NF}')