#!/bin/bash

# Specifies that chrome and safari are allowed.
ALLOWED=("com.apple.Safari" "com.google.Chrome")

# You specify add additional directories after /Users
find  /Users -name "*.app" 2>/dev/null | while read app; do
    plist="$app/Contents/Info.plist"
    [ -f "$plist" ] || continue

    # Get the bundle ID
    bundleID=$(/usr/libexec/PlistBuddy -c "Print CFBundleIdentifier" "$plist" 2>/dev/null)
    [[ " ${ALLOWED[@]} " =~ " $bundleID " ]] && continue

    # Check if it handles http/https protocols 
    if /usr/libexec/PlistBuddy -c "Print CFBundleURLTypes" "$plist" 2>/dev/null | grep -qi "http"; then
        echo "Found an unauthorized browser: $app ($bundleID)"
        # Kill process if its running
        pkill -f "$bundleID"
    fi
done
