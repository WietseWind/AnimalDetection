#!/bin/bash
set -euo pipefail

# Set up FIFO first
SOCKET_DIR="/tmp/socket"
FIFO_PATH="${SOCKET_DIR}/events.fifo"

ls -la "${FIFO_PATH}"

send_event() {
    local event_type="$1"
    local parameter="$2"
    local max_retries=5
    local attempt=0
    
    while [ $attempt -lt $max_retries ]; do
        if [ -p "$FIFO_PATH" ]; then
            echo "$event_type:$parameter" > "$FIFO_PATH"
            echo "Successfully sent event: $event_type"
            return 0
        fi
        
        echo "Attempt $((attempt + 1)) failed, retrying..."
        attempt=$((attempt + 1))
        sleep 1
    done
    
    echo "Failed to send event after $max_retries attempts"
    return 1
}

send_event "VIDEO" "$1"
