#!/bin/bash

# Config
ALLOWED_BUNDLE_IDS=("com.apple.Safari" "com.google.Chrome" "com.jamf.selfserviceplus")
LOG_FILE="/var/log/browser-block.log"
COOLDOWN_FILE="/tmp/browser_block_cooldown"
DISK_CACHE_FILE="/var/db/browser_block_hashes.cache"
COOLDOWN_SECONDS=60
CHECK_INTERVAL=10 
ICON_PATH="/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/Resources/restrictedSoftware.png"

# check if the  cache exists
touch "$DISK_CACHE_FILE"

# actual functions

rotate_logs() {
    if [ -f "$LOG_FILE" ]; then
        # only keep most recent 1000 lines of logs
        echo "$(tail -n 1000 "$LOG_FILE")" > "$LOG_FILE"
    fi
}

show_popup() {
    local uid="$1"
    local user="$2"
    now=$(date +%s)
    last=0
    [ -f "$COOLDOWN_FILE" ] && last=$(cat "$COOLDOWN_FILE")

    if (( now - last < COOLDOWN_SECONDS )); then return; fi

    echo "$now" > "$COOLDOWN_FILE"
    launchctl asuser "$uid" sudo -u "$user" /usr/bin/osascript <<-EOF 2>/dev/null
        display dialog "Application Restricted. Further attempts to access may result in disciplinary action." \
        buttons {"OK"} default button "OK" \
        with icon POSIX file "$ICON_PATH"
EOF
}

is_allowed() {
    for allowed in "${ALLOWED_BUNDLE_IDS[@]}"; do
        [[ "$1" == "$allowed" ]] && return 0
    done
    return 1
}

# main monitoring stuff

while true; do
    rotate_logs
    loggedInUser=$(stat -f%Su /dev/console)
    
    if [[ "$loggedInUser" != "root" && -n "$loggedInUser" ]]; then
        uid=$(id -u "$loggedInUser")

        # get list of running apps / bundles / execs
        app_list=$(launchctl asuser "$uid" sudo -u "$loggedInUser" lsappinfo list | awk -F'"' '/bundleID/ && /path/ {print $2 "|" $4}')

        while IFS="|" read -r bundleID appPath; do
            [[ -z "$bundleID" || -z "$appPath" ]] && continue
            is_allowed "$bundleID" && continue

            # get hash and skip if already checke.
            plist="$appPath/Contents/Info.plist"
            [[ ! -f "$plist" ]] && continue
            app_sig=$(shasum -a 256 "$plist" 2>/dev/null | awk '{print $1}')
            
            isBrowser="false"
            
            if grep -q "$app_sig" "$DISK_CACHE_FILE"; then
                isBrowser="true"
            else
                if /usr/libexec/PlistBuddy -c "Print CFBundleURLTypes" "$plist" 2>/dev/null | grep -qi "http"; then
                    isBrowser="true"
                    echo "$app_sig" >> "$DISK_CACHE_FILE"
                fi
            fi

            if [[ "$isBrowser" == "true" ]]; then
                # get binary and kill it if its detected as not approved
                binaryName=$(/usr/libexec/PlistBuddy -c "Print CFBundleExecutable" "$plist" 2>/dev/null)
                
                echo "$(date): Blocking $bundleID (Binary: $binaryName) at $appPath" >> "$LOG_FILE"
                
                if [[ -n "$binaryName" ]]; then
                    # actually killss
                    killall -9 "$binaryName" 2>/dev/null
                fi
                
                # kill entire .app incase it has a ton of process's
                pkill -9 -f "$appPath" 2>/dev/null
                
                show_popup "$uid" "$loggedInUser"
            fi
        done <<< "$app_list"
    fi

    sleep "$CHECK_INTERVAL"
done
