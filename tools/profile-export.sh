#!/bin/bash
set -euo pipefail

# Device Capabilities Export
# Exports simulator configuration and environment

DEVICE_ID="${1:?Usage: $0 <simulator-udid> [output-directory]}"
OUTPUT="${2:-iPhone17ProMax-export}"

echo "=================================================="
echo "   Device Profile Export Utility"
echo "=================================================="
echo ""

echo "[1/3] Creating output directory..."
mkdir -p "$OUTPUT"
echo "✓ Output directory: $OUTPUT"
echo ""

echo "[2/3] Exporting device configuration..."

# Export device list information
echo "Exporting device list..."
xcrun simctl list "$DEVICE_ID" > "$OUTPUT/device-list.txt" 2>/dev/null || \
    echo "Note: Could not export full device list"

# Export environment variables
echo "Exporting simulator environment..."
xcrun simctl getenv "$DEVICE_ID" HOME > "$OUTPUT/simulator-home.txt" 2>/dev/null || \
    echo "Note: Could not export simulator home path"

# Create manifest
echo "Creating export manifest..."
cat > "$OUTPUT/manifest.json" <<EOF
{
  "device": "iPhone 17 Pro Max",
  "modelIdentifier": "iPhone18,2",
  "exportDate": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "simulatorUDID": "$DEVICE_ID",
  "exportedFrom": "$(uname -s) $(uname -r)",
  "xcodeVersion": "$(xcodebuild -version 2>/dev/null | head -1 || echo 'unknown')",
  "files": [
    "device-list.txt",
    "simulator-home.txt",
    "manifest.json"
  ]
}
EOF
echo "✓ Manifest created"
echo ""

echo "[3/3] Verification..."
echo "Files in export:"
ls -lh "$OUTPUT/"
echo ""

echo "=================================================="
echo "   Export Complete!"
echo "=================================================="
echo "Location: $OUTPUT"
echo ""
echo "Contents:"
echo "  • device-list.txt    - Simulator device information"
echo "  • simulator-home.txt - Simulator home directory path"
echo "  • manifest.json      - Export metadata"
echo ""
