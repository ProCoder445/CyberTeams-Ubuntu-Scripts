#!/bin/bash
set -euo pipefail;

echo "Starting Script";

extensions=("mp3" "csv");


echo "Saving Current Directory"
current_dir="$(pwd)";

cd /home;

for extension in "${extensions[@]}"; do
	echo "Searching for .${extension} files";

	locate "*.${extension}";
done

cd "${current_dir}";
