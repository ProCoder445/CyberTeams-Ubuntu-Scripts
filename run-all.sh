#!/usr/bin/env bash

for file in ./*; do
    if [[ "${file}" == *.sh ]]; then
	./"${file}" || echo "File unable to be run: ${file}";
    fi
done
