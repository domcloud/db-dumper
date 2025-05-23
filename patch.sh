#!/bin/bash
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Loop through all directories with dates (YYYY-MM-DD format)
for dir in $(ls -d $SCRIPT_DIR/20*/ | sort); do
  # Extract the date from the folder name
  current_date=$(basename "$dir")
  
  # Get the next date by incrementing the current date
  next_date=$(date -d "$current_date + 1 day" +%Y-%m-%d)
  
  # Check if the next date directory exists
  if [ -d "$SCRIPT_DIR/$next_date" ]; then
    # Check if the patch file already exists
    patch_file="$SCRIPT_DIR/$current_date.patch"
    if [ ! -f "$patch_file" ]; then
      # Create the patch file if it doesn't exist
      echo "Creating patch for $current_date to $next_date"
      ( cd $SCRIPT_DIR && diff -u0rN "$current_date" "$next_date"
      ) > "$patch_file" || true
      # restore later with
      # cp -a $next_date $current_date
      # patch -p0 -R --dry-run < $current_date.patch
    else
      echo "Patch file $patch_file already exists, skipping"
    fi
    if [ -f "$patch_file" ]; then
      rm -rf "$SCRIPT_DIR/$current_date"
    fi
  else
      echo "Can't patch $current_date as $next_date not exist"
  fi
done
