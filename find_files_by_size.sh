#!/bin/bash

# Function to find files by size
find_files_by_size() {
    local directory="$1"
    local target_size="$2"
    
    # Use find to search for files with the specified size
    find "$directory" -type f -size "${target_size}c" 2>/dev/null
}

# Main script
read -p "Enter the directory to search: " directory
read -p "Enter the file size to search for (in bytes): " target_size

# Validate if target size is a number
if ! [[ "$target_size" =~ ^[0-9]+$ ]]; then
    echo "Please enter a valid integer for the file size."
    exit 1
fi

# Find and display matching files
matching_files=$(find_files_by_size "$directory" "$target_size")

if [[ -n "$matching_files" ]]; then
    echo "Files of size $target_size bytes found:"
    echo "$matching_files"
else
    echo "No files of size $target_size bytes found in the specified directory."
fi
