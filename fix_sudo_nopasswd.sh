#!/bin/bash

if [[ -f /etc/sudoers ]]; then
	(grep /etc/sudoers "Default !authenticate";
	grep /etc/sudoers "<user || ALL> ALL=(ALL) NOPASSWD: ALL") || (
	echo "No unauthentication scripts found in usual places, RESEARCH MORE PLACES"
)


