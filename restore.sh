#!/bin/bash
#
# Restores an incremental backup to the state of a specific target date.
#
# Usage: ./restore.sh YYYY-MM-DD
# Example: ./restore.sh 2025-10-10
#
# This script starts from the LATEST full backup directory and applies
# all subsequent patches in REVERSE order until the target date is reached.
# The result is saved in a new directory: db_restored_to_[TARGET_DATE]
#

# --- Configuration and Setup ---
set -e # Exit immediately if a command exits with a non-zero status.

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# 1. Validate Input
if [ -z "$1" ]; then
  echo "❌ Error: No target date specified."
  echo "Usage: $0 YYYY-MM-DD"
  echo "Example: $0 2025-10-10"
  exit 1
fi

TARGET_DATE="$1"
RESTORE_DIR_NAME="restored-$TARGET_DATE"
RESTORE_PATH="$SCRIPT_DIR/$RESTORE_DIR_NAME"

# --- Find Starting Point ---

# 2. Find the latest full backup directory (it's the only one left)
LATEST_DIR_PATH=$(ls -d $SCRIPT_DIR/20*/ | sort -r | head -n 1)

if [ -z "$LATEST_DIR_PATH" ]; then
  echo "❌ Error: No database directories (e.g., 2025-10-10/) found."
  exit 1
fi

LATEST_DATE=$(basename "$LATEST_DIR_PATH")
echo "ℹ️ Found latest full backup: $LATEST_DATE"

# --- Prepare Restore Environment ---

# 3. Clean up old restore (if any) and copy the latest backup to start
if [ -d "$RESTORE_PATH" ]; then
  echo "🗑️ Removing previous restore: $RESTORE_PATH"
  rm -rf "$RESTORE_PATH"
fi

echo "🚀 Starting restore..."
echo "Copying $LATEST_DATE to $RESTORE_DIR_NAME..."
cp -a "$LATEST_DIR_PATH" "$RESTORE_PATH"

# --- Find and Apply Patches ---

# 4. Find all patches that need to be applied in reverse.
# We need patches FROM the target date UP TO the day *before* the latest backup.
# We sort them in reverse order (sort -r) to apply newest first.
PATCHES_TO_APPLY=$(ls $SCRIPT_DIR/20*.patch 2>/dev/null | sort -r | awk -v target="$TARGET_DATE" -v latest="$LATEST_DATE" -F'/' '{
    split($NF, a, ".patch");
    date = a[1];
    # Only select patches >= target_date AND < latest_backup_date
    if (date >= target && date < latest) {
        print $0; # Print the full path
    }
}')

if [ -z "$PATCHES_TO_APPLY" ]; then
  echo "⚠️ No patches to apply. The restore directory contains the state of $LATEST_DATE."
  if [ "$TARGET_DATE" != "$LATEST_DATE" ]; then
    echo "   (Your target date $TARGET_DATE is older, but no patches were found to revert to it.)"
  fi
  echo "✅ Restore complete!"
  exit 0
fi

echo "Applying patches in reverse to reach state of $TARGET_DATE..."

# 5. CD into the new restore directory to apply patches
cd "$RESTORE_PATH"

for patch_file in $PATCHES_TO_APPLY; do
  patch_date=$(basename "$patch_file" .patch)
  
  # The patch date (e.g., 2025-10-10.patch) represents the state we are *reverting to*.
  echo "    ⬅️ Applying $patch_date.patch (reverting to state of $patch_date)"
  
  # We use:
  # -p1 : To strip the leading directory (e.g., '2025-10-11/') from the patch file.
  # -R  : To apply the patch in REVERSE.
  # < "$patch_file" : Read the patch from its original location.
  patch -p1 -R < "$patch_file"
done

# --- Finish ---
cd "$SCRIPT_DIR"
echo "✅ Restore complete!"
echo "Restored data is now available in: $RESTORE_PATH"
