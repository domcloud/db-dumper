#!/bin/bash
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

if ! command -v bup 2>&1 >/dev/null
then
    echo installing bup...
    git clone https://github.com/bup/bup -b 0.33.7
    cd bup
    make
    make install DESTDIR=$HOME PREFIX=/.local
    cd ..
    rm -rf bup
fi

echo Bup version is $(bup --version)
for dir in $(ls -d $SCRIPT_DIR/20*) | sort; do
    # Extract date folder name
    date=$(basename "$dir")
    timestamp=$(date -d "$date" +%s)

    # Create backup for each date directory
    echo "Indexing and saving backup for $date"
    bup index "$dir"
    bup save -n db -d "$timestamp" "$dir"
done
