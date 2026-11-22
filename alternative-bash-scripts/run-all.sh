#!/usr/bin/env bash

for file in ./*; do
    if [[ "${file}" == *.sh ]]; then
	bash "${file}" || echo "File unable to be run: ${file}";
    fi
done
