#!/usr/bin/env bash

for file in ./*; do
    if [[ "$file" == *.sh ]]; then
        chmod u+x "${file}" || echo "Unable to chmod file: ${file}";
    fi
done

echo "Done!"
exit 0;
