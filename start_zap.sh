#!/bin/bash
# scripts/start_zap.sh

ZAP_PATH=/opt/zap
ZAP_PORT=8085
ZAP_HOST=127.0.0.1

# Remove corrupted add-ons (optional but recommended)
rm -rf $ZAP_PATH/*.zap

# Start ZAP headless
$ZAP_PATH/zap.sh -daemon -port $ZAP_PORT -host $ZAP_HOST -config api.disablekey=true &

echo "Starting ZAP daemon..."

# Wait until ZAP is ready
until curl -s http://$ZAP_HOST:$ZAP_PORT >/dev/null; do
    sleep 5
done

echo "ZAP is ready!"
