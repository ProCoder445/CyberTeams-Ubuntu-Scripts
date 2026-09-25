#!/bin/bash

for file in "$(ls)"; do
    chmod u+x "${file}" || echo "Unable to chmod file: ${file}";
done
