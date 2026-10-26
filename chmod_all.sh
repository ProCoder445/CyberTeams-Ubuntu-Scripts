#!/usr/bin/env bash

for file in ./*; do
    chmod u+x "${file}" || echo "Unable to chmod file: ${file}";
done

echo "Done!"
exit 0;
