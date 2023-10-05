#!/bin/bash

now=$(date +'%Y-%m-%d-%H-%M-%S')
BACKUPDIRECTORY="/opt/mcserver/backups/${now}";

# Make sure we have a directory to save to
mkdir -p "$BACKUPDIRECTORY"

ALLWORLDS=("world" "world_nether" "world_the_end")

# Back up every folder in the above list to the previously created backup folder for the current run
# Do this in parallel to avoid any potential holdups between different directories
for w in "${ALLWORLDS[@]}"; do
(
    BACKUPNAME="${BACKUPDIRECTORY}/$w.tar.gz"

    if test -d "$w"; then

        tar -czf "$BACKUPNAME" "$w" || exit
        echo "Backed up ${w} to ${BACKUPNAME}"
    else 
        echo "${w} didn't exist to back up"
    fi    
) &
done;
wait