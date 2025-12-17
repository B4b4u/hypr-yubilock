#!/bin/bash

# ==============================================
# YubiKey Lock Toggle (Pause/Resume)
# Used via Keyboard Shortcut to create a 'semaphore' file
# ==============================================

FLAG_FILE="/tmp/yubikey-lock-paused"

if [ -f "$FLAG_FILE" ]; then
    # Scenario: File exists -> Security is currently PAUSED.
    # Action: Remove file to RE-ENABLE security.
    rm "$FLAG_FILE"
    
    notify-send -u normal -t 3000 -i security-high \
        "YubiKey Security" \
        "🟢 Auto-Lock ENABLED"
else
    # Scenario: File does not exist -> Security is ACTIVE.
    # Action: Create file to PAUSE security (allow removal).
    # Since /tmp is cleared on reboot, security defaults to ON after restart.
    touch "$FLAG_FILE"
    
    notify-send -u critical -t 5000 -i security-low \
        "YubiKey Security" \
        "🔴 Auto-Lock PAUSED\nYou may remove the key safely."
fi
