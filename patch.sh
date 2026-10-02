#!/bin/bash
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Gather all date directories into an array
shopt -s nullglob
dirs=("$SCRIPT_DIR"/20*/)
shopt -u nullglob

# If there are fewer than 2 directories, there's nothing to patch
if [ ${#dirs[@]} -lt 2 ]; then
  echo "Not enough backup directories to create patches."
  exit 0
fi

# Loop up to the SECOND-TO-LAST directory.
for (( i=0; i<${#dirs[@]}-1; i++ )); do
  current_dir="${dirs[$i]}"
  next_dir="${dirs[$i+1]}"
  
  # Extract just the folder names
  current_date=$(basename "$current_dir")
  next_date=$(basename "$next_dir")
  
  patch_file="$SCRIPT_DIR/$current_date.patch"
  if [ ! -f "$patch_file" ]; then
    echo "Creating patch for $current_date to $next_date"
    # Create the patch file
    ( cd "$SCRIPT_DIR" && diff -u0rN "$current_date" "$next_date"
    ) > "$patch_file" || true
    # restore later with
    # cp -a $next_date $current_date
    # cd $current_date && patch -p1 -R --dry-run < ../$current_date.patch
  else
    echo "Patch file $patch_file already exists, skipping"
  fi
  
  # 3. Only delete the original directory if the patch file was successfully created
  if [ -f "$patch_file" ]; then
    echo "Cleaning up old directory: $current_date"
    rm -rf "$SCRIPT_DIR/$current_date"
  fi
done