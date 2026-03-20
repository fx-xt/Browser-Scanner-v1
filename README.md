# Browser-Scanner-v1
Scan for browsers and kill if not allowed

Scan for .app's in home directory > Looks inside plist > Check if its from chrome or safari > if not then & is browser (identified by http) then kill

# This script scans for non allowed browsers and kill them.

## This is the process it uses.

- Scans for MacOS applications in home folder
- Checks if it has a plist
- Checks if the bundle id is that of Google Chrome or Safari, if not than continue
- Checks if its a browser by searching for HTTP in the PList file.
- If the above conditions are true, it will kill the application.

#### Important 
- This is a very early version, don't rely on this. Things may break.
