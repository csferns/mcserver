#!/bin/bash

TARGET=$1;
VERSION=$2;

# Check that we're passed a target parameter
if [ -z "$TARGET" ]; then

    echo "Argument 1 cannot be empty"
    exit
fi

URL="https://api.papermc.io/v2/projects/paper"
now=$(date +'%Y-%m-%d-%H-%M-%S')

# Make sure we have a target directory for everything to go into
if ! test -d "$TARGET"; then
    mkdir "$TARGET"

    echo "Made directory ${TARGET}"
fi

cd "$TARGET" || exit

# Make sure we have a Backups directory
if ! test -d "Backups"; then
    mkdir "Backups"
fi

BACKUPFOLDER="Backups/${now}"

# Make sure we have a backup folder for the current run
if ! test -d "$BACKUPFOLDER"; then

    mkdir "$BACKUPFOLDER"
fi

ALLWORLDS=("world" "world_nether" "world_the_end")

# Back up every folder in the above list to the previously created backup folder for the current run
# Do this in parallel to avoid any potential holdups between different directories
for w in "${ALLWORLDS[@]}"; do
(
    BACKUPNAME="${BACKUPFOLDER}/$w.tar.gz"

    if test -d "$w"; then

        tar -czf "$BACKUPNAME" "$w" || exit
        echo "Backed up ${w} to ${BACKUPNAME}"
    else 
        echo "${w} didn't exist to back up"
    fi    
) &
done;
wait

# If we're not explicitly setting the current version in the script, then query the latest from the paper API
if [ -z "$VERSION" ]; then
    VERSION=$(curl -s "$URL" | jq -r '.versions[-1]')

    echo "Latest version: ${VERSION}"
fi

# Make sure we have an EULA acceptance file otherwise the .jar file will exit out immediately
echo 'eula=true' > 'eula.txt';
BUILD=$(curl -s "${URL}/versions/${VERSION}" | jq '.builds[-1]')

FILENAME="paper-${VERSION}-${BUILD}.jar"

if ! test -f "$FILENAME"; then
   
    # Delete any existing .jar files so they don't pile up
    echo 'Deleting old paper .jar files'
    find . -name "paper-${VERSION}-*.jar" -delete

    # Download the given version from the paper API
    echo "Downloading ${FILENAME}"
    curl -s "${URL}/versions/${VERSION}/builds/${BUILD}/downloads/${FILENAME}" -o "$FILENAME" -H "Content-Type: application/java-archive"
fi

echo "Running ${FILENAME}"

java -Xmx10G \
     -Xms4G \
     -XX:+UseG1GC \
     -XX:+ParallelRefProcEnabled \
     -XX:MaxGCPauseMillis=200 \
     -XX:+UnlockExperimentalVMOptions \
     -XX:+DisableExplicitGC \
     -XX:+AlwaysPreTouch \
     -XX:G1NewSizePercent=30 \
     -XX:G1MaxNewSizePercent=40 \
     -XX:G1HeapRegionSize=8M \
     -XX:G1ReservePercent=20 \
     -XX:G1HeapWastePercent=5 \
     -XX:G1MixedGCCountTarget=4 \
     -XX:InitiatingHeapOccupancyPercent=15 \
     -XX:G1MixedGCLiveThresholdPercent=90 \
     -XX:G1RSetUpdatingPauseTimePercent=5 \
     -XX:SurvivorRatio=32 \
     -XX:+PerfDisableSharedMem \
     -XX:MaxTenuringThreshold=1 \
     -Dusing.aikars.flags=https://mcflags.emc.gs \
     -Daikars.new.flags=true \
     -jar "$FILENAME" \
     --nogui