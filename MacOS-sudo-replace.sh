#!/bin/bash

if [[ "${OSTYPE}" == darwin* ]]; then 
    sudo() {
	echo "[FAKE SUDO]: $@"
	return 0
    }
fi
