#!/bin/bash

# Check if two branches are provided
if [ $# -ne 3 ]; then
    echo "Usage: $0 <branch1> <branch2> <output.csv>"
    exit 1
fi

branch1=$1
branch2=$2
output_file=$3

# Write the CSV header
echo "No,File Path,Extension,Date,Size" > "$output_file"

# Initialize row counter
counter=1

# Process the diff for added and modified files only
git diff --name-status --diff-filter=AM "$branch1" "$branch2" | while read status file; do
    if [ -f "$file" ]; then
        # Get size from the working directory
        size_bytes=$(stat -f "%z" "$file" 2>/dev/null || echo 0)

        # Get the last modification date
        mod_date=$(stat -f "%Sm" -t "%d-%b-%y" "$file" 2>/dev/null || echo "N/A")
    else
        # Get size from Git if the file doesn't exist locally
        size_bytes=$(git show "$branch2:$file" 2>/dev/null | wc -c || echo 0)

        # Get the last modification date from Git
        mod_date=$(git log -1 --format="%ad" --date=format:"%d-%b-%y" "$branch2" -- "$file" 2>/dev/null || echo "N/A")
    fi

    # Determine file extension
    extension="${file##*.}"

    # Convert bytes to KB or display in bytes if less than 1 KB
    if [ "$size_bytes" -gt 0 ]; then
        size_kb=$((size_bytes / 1024))
        if [ "$size_kb" -gt 0 ]; then
            size_display="${size_kb} KB"
        else
            size_display="${size_bytes} bytes"
        fi
    else
        size_display="${size_bytes} bytes"
    fi

    # Append the result to the CSV file with row number
    echo "$counter,\"$file\",\"$extension\",\"$mod_date\",\"$size_display\"" >> "$output_file"

    # Increment the counter
    counter=$((counter + 1))
done
