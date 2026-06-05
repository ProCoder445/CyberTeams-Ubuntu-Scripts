#!/bin/bash

for file in "$(ls)"; do
    if [[ "${file}" == *.sh ]]; then
	./${file} || echo "File unable to be run: ${file}";
    fi
done
