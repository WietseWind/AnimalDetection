#!/usr/bin/env bash
set -euo pipefail

SOCKET_DIR="/tmp/socket"
FIFO_PATH="${SOCKET_DIR}/events.fifo"
FOLLOWUP_SCRIPT="/scripts/"${FOLLOWUP_SCRIPT:-followup.sh}

mkdir -p "${SOCKET_DIR}"
chmod 777 "${SOCKET_DIR}"
rm -f "${FIFO_PATH}"
mkfifo "${FIFO_PATH}"
chmod 777 "${FIFO_PATH}"
chown 911:911 "${FIFO_PATH}"  # Give ownership to sender's user
echo "FIFO created at ${FIFO_PATH}"
ls -la "${FIFO_PATH}"

while true; do
    while read -r line < "${FIFO_PATH}"; do
        event_type="${line%%:*}"
        parameter="${line#*:}"
        
        echo "Received event: ${event_type} with parameter: ${parameter}"
        
        case "${event_type}" in
            "VIDEO")
                echo "Postprocessing video: $parameter"
                fpath=$(echo "$parameter"|cut -d":" -f 2-100000)
                echo "$fpath"
                ls -lahs "$fpath"
                set +e  # Temporarily disable exit on error
                (python detect.py "$fpath" -c 0.75 -q -p)
                status=$?
                set -e  # Re-enable exit on error
                if [ $status -eq 1 ]; then
                    echo "No animals detected, removing file: $fpath"
                    rm "$fpath"
                else
                    echo "Animals detected, keeping file: $fpath"
                    echo " ---> Next: checking for follow up process..."
                    if [ -f "$FOLLOWUP_SCRIPT" ]; then
                        echo "Found follow-up script at $FOLLOWUP_SCRIPT"
                        if [ -x "$FOLLOWUP_SCRIPT" ]; then
                            echo "Executing follow-up script..."
                            set +e
                            "$FOLLOWUP_SCRIPT" "$fpath"
                            followup_status=$?
                            set -e
                            echo "Follow-up script completed with status: $followup_status"
                        else
                            echo "Follow-up script exists but is not executable"
                        fi
                    else
                        echo "No follow-up script found at $FOLLOWUP_SCRIPT"
                    fi
                fi
                echo "Processing complete, waiting for next event..."
                ;;
            *)
                echo "Unknown event: ${event_type}"
                ;;
        esac
    done
done