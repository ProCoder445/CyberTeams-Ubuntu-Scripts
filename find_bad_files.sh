#!/bin/bash

# Define an array of file extensions to check for
extensions=(".mp3" ".mp4" ".csv" ".sh")
bad_files=()

# Function to recursively find files
set_files() {
    local dir="$1"
    cd "$dir" || return

    for file in $(ls); do
        if [[ -d "$file" ]]; then
            set_files "$file"
        elif [[ -f "$file" ]]; then
            files+=("$file")
        else
            echo "File not found: $file"
        fi
    done

    cd .. || return
}

# Main script execution
set_files "."

# Check for bad files with specified extensions
for extension in "${extensions[@]}"; do
    for file in "${files[@]}"; do
        if [[ "$file" == *"$extension" ]]; then
            bad_files+=("$file")
        fi
    done
done

# Output bad files
if ((${#bad_files[@]})); then
    echo "Found the following bad files:"
    printf '%s\n' "${bad_files[@]}"
else
    echo "No bad files found."
fi
