#!/bin/bash
# start_zap.sh - cleans corrupted add-ons and starts ZAP headless

ZAP_PATH="/path/to/ZAP"  # Adjust this to where ZAP is installed
ZAP_HOME="$HOME/.ZAP"

echo "Cleaning corrupted add-ons..."
rm -rf "$ZAP_HOME/addons/*.zap" 2>/dev/null || true

echo "Starting ZAP headless..."
"$ZAP_PATH/zap.sh" -daemon -config api.disablekey=true -port 8080

# Optional: wait until ZAP fully loads
sleep 10
echo "ZAP is running!"
