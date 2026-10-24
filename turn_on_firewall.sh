#!/usr/bin/env bash

# shellcheck source=/dev/null
source ./MacOS-sudo-replace.sh

ufw enable || sudo apt install ufw && ufw enable;
