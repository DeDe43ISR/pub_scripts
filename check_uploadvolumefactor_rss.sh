#!/bin/bash

# Configuration
URL=""
TEMP_FILE="rss_temp"
TITLE="$1"

# Check if the title name is provided
if [ $# -ne 1 ]; then
  echo "Usage: $0 <title_name>"
  exit 1
fi

# Download the file if it doesn't exist or is older than 1 hour
if [ ! -f "$TEMP_FILE" ] || [ "$(find "$TEMP_FILE" -mmin +60 2>/dev/null)" ]; then
  echo "Downloading the file..."
  curl -s -o "$TEMP_FILE" "$URL"
  if [ $? -ne 0 ]; then
    echo "Error: Failed to download the file."
    exit 1
  fi
else
  echo "Using cached file: $TEMP_FILE"
fi

# Search for the item in the XML file
RESULT=$(awk -v title="$TITLE" '
  /<item>/ { in_item = 1; item = "" }
  in_item { item = item $0 ORS }
  /<\/item>/ {
    in_item = 0
    if (item ~ "<title>" title "</title>" && item ~ "<torznab:attr name=\"uploadvolumefactor\" value=\"2\"") {
      print "found"
    }
  }
' "$TEMP_FILE")

# Return based on the result
if [ "$RESULT" == "found" ]; then
  exit 0
else
  exit 1
fi
