# Browser-Scanner-v1
Scan for browsers and kill if not allowed

Scan for .app's in process list > Looks inside plist  of it > Check if its from chrome or safari > if not then & is browser (identified by http) then kill and send popup

# This script scans for non allowed browsers and kill them.

## This is the process it uses.

- Lists all user processes (and those running with a GUI)
- Checks if its an app
- Checks its plist
- Checks if the bundle id is that of Google Chrome or Safari, if not than continue
- Checks if its a browser by searching for HTTP in the PList file.
- If the above conditions are true, it will kill the application and send a popup.

#### Important 
- This is a very early version, don't rely on this. Things may break.
