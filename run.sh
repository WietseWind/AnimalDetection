#!/bin/bash
set -e

chmod +x ./docker/sender/app.sh
chmod +x ./docker/receiver/app.sh

REPO_PATH="./docker/unifi-protect-backup"
BRANCH="prerelease/excludecam-postprocess"
REPO_URL="https://github.com/WietseWind/unifi-protect-backup.git"

if [ -d "$REPO_PATH/.git" ]; then
    echo "Repository exists, updating..."
    echo $(cd "$REPO_PATH"; git fetch origin; git reset --hard origin/$BRANCH; git clean -fdx)
else
    echo "Cloning repo..."
    git clone -b $BRANCH $REPO_URL $REPO_PATH
fi

echo $(cd ./docker/unifi-protect-backup && poetry build && docker build -t wietse-unifi-protect-backup .)
rm -rf /tmp/unifi
docker compose up --build $@ # could be -d

# docker compose down