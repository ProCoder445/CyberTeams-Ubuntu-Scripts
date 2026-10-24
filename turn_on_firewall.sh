#!/usr/bin/env bash

source ./MacOS-sudo-replace.sh

ufw enable || sudo apt install ufw && ufw enable;
