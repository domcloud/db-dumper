#!/bin/bash
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
BUP_REPO=~/bup_repo

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

mkdir -p ~/bup_repo
cd ~/bup_repo
bup init

for dir in $SCRIPT_DIR/20*/; do
    # Extract date folder name
    date=$(basename "$dir")

    # Create backup for each date directory
    echo "Backing up $date"
    bup split -n "$dir" && bup save -n "$HOME/bup_repo/$date"
done
