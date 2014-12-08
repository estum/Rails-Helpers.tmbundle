#!/usr/bin/env bash

uuid=$1

open "txmt://open/?uuid=${uuid}" && osascript <<EOF
tell application "System Events"
	delay 0.2
  keystroke "w" using {command down}
	delay 0.1
end tell
EOF