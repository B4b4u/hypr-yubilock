#!/bin/bash

# ==============================================
# YubiKey Auto-Lock Script
# Feature: Polling Grace Period + Pause Check
# ==============================================

# --- CONFIGURATION (EDIT THIS) ---
TARGET_USER="YOUR_USERNAME"           # <--- CHANGE THIS to your username
LOG="/tmp/yubikey-debug.log"          # Debug log path
TIMEOUT=5                             # Grace period in seconds
UNIT_NAME="yubikey-lock-grace.service" # Systemd transient unit name
FLAG_FILE="/tmp/yubikey-lock-paused"  # File existence indicates "Pause Mode"

# ALLOWED SERIALS (Regex format)
# Add your YubiKey serials here, separated by pipes (|).
# Example: "12345678|87654321"
ALLOWED_SERIALS="YOUR_PRIMARY_SERIAL|YOUR_BACKUP_SERIAL"   # <--- CHANGE THIS

# ---------------------------------

# Logging Helper Function
log() { echo "[$(date '+%H:%M:%S')] $1" >> "$LOG"; }

# 1. CHECK PAUSE STATUS
# If the pause flag file exists, the user has manually disabled the lock.
if [ -f "$FLAG_FILE" ]; then
    log "PAUSE ACTIVE: Lock file found ($FLAG_FILE). Ignoring removal event."
    exit 0
fi

# 2. PRE-CHECKS
# Verify if the target user is actually logged in.
if ! loginctl list-users | grep -q "$TARGET_USER"; then
    exit 0
fi

# Verify if Hyprlock is already running to avoid redundant actions.
if pgrep -x "hyprlock" > /dev/null; then
    exit 0
fi

# 3. START GRACE PERIOD TIMER
# We use systemd-run to detach from the Udev environment and enter the user session.
# We suppress stdout/stderr to keep system logs clean from "Unit already exists" messages.
/usr/bin/systemd-run \
    --unit="$UNIT_NAME" \
    --machine="${TARGET_USER}@.host" \
    --user \
    --quiet \
    /bin/bash -c "
        # Log the start of the event
        echo \"[$(date '+%H:%M:%S')] START: Removal detected. Starting $TIMEOUT second countdown...\" >> $LOG
        
        # Polling Loop (Grace Period)
        for i in {1..$TIMEOUT}; do
            sleep 1
            
            # Check if any connected USB device matches our allowed serials
            if grep -qE '$ALLOWED_SERIALS' /sys/bus/usb/devices/*/serial 2>/dev/null; then
                echo \"[$(date '+%H:%M:%S')] SUCCESS: YubiKey detected/returned. Lock CANCELLED.\" >> $LOG
                exit 0
            fi
        done

        # If loop finishes without finding a key:
        echo \"[$(date '+%H:%M:%S')] TIMEOUT: No YubiKey found. LOCKING SYSTEM!\" >> $LOG
        /usr/bin/hyprlock
    " 2>/dev/null
