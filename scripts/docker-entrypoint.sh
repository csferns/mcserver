#!/bin/bash

MC_SERVER_VOL=/minecraft
MC_SERVER_FOLDERNAME="${MC_SERVER_FOLDERNAME:-'server'}"
MC_SERVER_VERSION=''
URL="https://api.papermc.io/v2/projects/paper"
RETRIES=3

# Check that we're passed a target parameter
if [ -z "$MC_SERVER_VOL" ]; then

    echo "Server volume name cannot be empty"
    exit
fi

cd "$MC_SERVER_VOL" || exit

# Make sure we have a target directory for everything to go into
if ! test -d "$MC_SERVER_FOLDERNAME"; then
    mkdir "$MC_SERVER_FOLDERNAME"

    echo "Made directory ${MC_SERVER_FOLDERNAME}"
fi

cd "$MC_SERVER_FOLDERNAME" || exit

bash ./backup.sh

# If we're not explicitly setting the current version in the script, then query the latest from the paper API
if [ -z "$MC_SERVER_VERSION" ]; then
    MC_SERVER_VERSION=$(curl -s "$URL" --retry "$RETRIES" | jq -r '.versions[-1]')

    echo "Latest version: ${MC_SERVER_VERSION}"
fi

# Make sure we have an EULA acceptance file otherwise the .jar file will exit out immediately
if ! test -f eula.txt; then

    echo 'eula=true' > 'eula.txt';
fi

BUILD=$(curl -s "${URL}/versions/${MC_SERVER_VERSION}" --retry "$RETRIES" | jq '.builds[-1]')

FILENAME="paper-${MC_SERVER_VERSION}-${BUILD}.jar"

if ! test -f "$FILENAME"; then
   
    # Delete any existing .jar files so they don't pile up
    echo 'Deleting old paper .jar files'
    find . -name "paper-${MC_SERVER_VERSION}-*.jar" -delete

    # Download the given version from the paper API
    echo "Downloading ${FILENAME}"
    curl -s "${URL}/versions/${MC_SERVER_VERSION}/builds/${BUILD}/downloads/${FILENAME}" -o "$FILENAME" -H "Content-Type: application/java-archive" --retry "$RETRIES"
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