#!/bin/bash

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Try to load VIMEO_ACCESS_TOKEN from .env file if it exists
if [ -f "$SCRIPT_DIR/.env" ]; then
    # Source the .env file
    . "$SCRIPT_DIR/.env"
fi

# Check if an access token is set
if [ -z "${VIMEO_ACCESS_TOKEN}" ]; then
    echo "Error: VIMEO_ACCESS_TOKEN environment variable is not set"
    echo "Please either:"
    echo "1. Set it with: export VIMEO_ACCESS_TOKEN='your_access_token'"
    echo "2. Create a .env file in the script directory with: VIMEO_ACCESS_TOKEN='your_access_token'"
    exit 1
fi

# Check arguments
if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <video_file>"
    echo "Example: $0 /path/to/Wildlife/2024-12-23/2024-12-23T09-39-33.mp4"
    exit 1
fi

# Check if the file exists
if [ ! -f "$1" ]; then
    echo "Error: File '$1' does not exist"
    exit 1
fi

# Extract components from filename
filename="$1"

# Extract camera name (folder name before the date)
camera_name=$(echo "$filename" | grep -o "Wildlife [0-9]*")

# Extract date and time
datetime=$(echo "$filename" | grep -o "[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}T[0-9]\{2\}-[0-9]\{2\}-[0-9]\{2\}")

if [ -z "$datetime" ] || [ -z "$camera_name" ]; then
    echo "Error: Could not parse date/time or camera name from filename"
    exit 1
fi

# Convert date format from YYYY-MM-DD to DD-MM-YYYY
date_part=$(echo "$datetime" | cut -d'T' -f1)
year=$(echo "$date_part" | cut -d'-' -f1)
month=$(echo "$date_part" | cut -d'-' -f2)
day=$(echo "$date_part" | cut -d'-' -f3)

# Convert time format from HH-MM-SS to HH:MM:SS
time_part=$(echo "$datetime" | cut -d'T' -f2 | tr '-' ':')

# Create formatted title and description
title="${day}-${month}-${year}, ${time_part} (Cam: ${camera_name})"
description="Wildlife footage captured on ${day}-${month}-${year} at ${time_part} by ${camera_name}"

echo "Uploading video with title: $title"
echo "Description: $description"

# Get the file size
FILE_SIZE=$(stat -f%z "$1" 2>/dev/null || stat -c%s "$1" 2>/dev/null)
if [ $? -ne 0 ]; then
    echo "Error: Could not determine file size"
    exit 1
fi

# Create JSON data with proper escaping
json_data=$(cat <<EOF
{
    "upload": {
        "approach": "tus",
        "size": "${FILE_SIZE}"
    },
    "name": $(printf '%s\n' "$title" | jq -R .),
    "description": $(printf '%s\n' "$description" | jq -R .),
    "privacy": {
        "view": "anybody",
        "embed": "public",
        "comments": "anybody",
        "download": false
    },
    "content_rating": ["safe"],
    "rating_mod_locked": false,
    "embed": {
        "buttons": {
            "like": true,
            "watchlater": true,
            "share": true
        },
        "logos": {
            "vimeo": true
        },
        "title": {
            "name": "show",
            "owner": "show",
            "portrait": "show"
        }
    },
    "review_page": {
        "active": false
    },
    "tag": {
        "tag": ["netherlands", "wildlife", "badger", "fox"]
    }
}
EOF
)

echo "Creating upload ticket..."
# Create the upload ticket with title and description
UPLOAD_RESPONSE=$(curl -s -X POST https://api.vimeo.com/me/videos \
    -H "Authorization: Bearer ${VIMEO_ACCESS_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "$json_data")

# Extract the upload URL from the response
UPLOAD_URL=$(echo "$UPLOAD_RESPONSE" | jq -r '.upload.upload_link')
if [ -z "$UPLOAD_URL" ] || [ "$UPLOAD_URL" = "null" ]; then
    echo "Error: Failed to get upload URL"
    echo "Response: $UPLOAD_RESPONSE"
    exit 1
fi

# Extract the video URI for status checking
VIDEO_URI=$(echo "$UPLOAD_RESPONSE" | jq -r '.uri // ""')

echo "Starting upload..."
# Use curl to upload the file
curl -X PATCH "$UPLOAD_URL" \
    -H "Tus-Resumable: 1.0.0" \
    -H "Upload-Offset: 0" \
    -H "Content-Type: application/offset+octet-stream" \
    --upload-file "$1"

if [ $? -ne 0 ]; then
    echo "Error: Upload failed"
    exit 1
fi

echo "Upload completed successfully!"
echo "Video URI: $VIDEO_URI"

# Add tags with a separate request
# echo "Adding tags..."
# curl -s -X PUT "https://api.vimeo.com$VIDEO_URI/tags" \
#     -H "Authorization: Bearer ${VIMEO_ACCESS_TOKEN}" \
#     -H "Content-Type: application/json" \
#     -d '{
#         "data": []
#     }'

# Check the video status and get link
echo "Checking video status..."
STATUS_RESPONSE=$(curl -s "https://api.vimeo.com$VIDEO_URI" \
    -H "Authorization: Bearer ${VIMEO_ACCESS_TOKEN}" \
    -H "Content-Type: application/json")

VIDEO_LINK=$(echo "$STATUS_RESPONSE" | jq -r '.link // "Not available yet"')
TRANSCODE_STATUS=$(echo "$STATUS_RESPONSE" | jq -r '.transcode.status // "unknown"')

echo "Video link: $VIDEO_LINK"
echo "Transcode status: $TRANSCODE_STATUS"
echo -e "\nDone! Your video has been uploaded to Vimeo."