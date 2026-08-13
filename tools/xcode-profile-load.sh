#!/bin/bash
set -euo pipefail

# iPhone 17 Pro Max Xcode Profile Loader
# Automatically creates and boots simulator with proper configuration

PROFILE="${1:-devices/iPhone17ProMax}"
RUNTIME="${RUNTIME:-com.apple.CoreSimulator.SimRuntime.iOS-26-0}"
DEVICE_NAME="iPhone 17 Pro Max"

echo "=================================================="
echo "   iPhone 17 Pro Max Xcode Profile Loader"
echo "=================================================="
echo ""

# Check if runtime is available
echo "[1/4] Checking iOS 26 runtime availability..."
if ! xcrun simctl list runtimes | grep -F "$RUNTIME" >/dev/null; then
    echo "ERROR: Required iOS 26 runtime is not installed."
    echo "Please install iOS 26 SDK in Xcode."
    exit 1
fi
echo "✓ Runtime found: $RUNTIME"
echo ""

# Check if device already exists
echo "[2/4] Checking for existing simulator device..."
DEVICE_ID="$(
    xcrun simctl list devices available 2>/dev/null |
    awk -F '[()]' -v name="$DEVICE_NAME" '$1 ~ name {print $2; exit}'
)"

if [[ -z "$DEVICE_ID" ]]; then
    echo "Device not found. Creating new simulator..."
    
    # Find device type
    DEVICE_TYPE="$(
        xcrun simctl list devicetypes 2>/dev/null |
        grep -F "iPhone 17 Pro Max" |
        sed -n 's/.*(\/\/com[^)]*)/\1/p' |
        head -n1
    )"
    
    if [[ -z "$DEVICE_TYPE" ]]; then
        echo "ERROR: iPhone 17 Pro Max device type not found in Xcode."
        echo "This device type may not be available in your Xcode version."
        exit 1
    fi
    
    DEVICE_ID="$(
        xcrun simctl create \
            "$DEVICE_NAME" \
            "$DEVICE_TYPE" \
            "$RUNTIME"
    )"
    echo "✓ Simulator created with UDID: $DEVICE_ID"
else
    echo "✓ Found existing simulator: $DEVICE_ID"
fi
echo ""

# Validate profile
echo "[3/4] Validating device profile..."
if [[ ! -d "$PROFILE" ]]; then
    echo "ERROR: Profile directory not found: $PROFILE"
    exit 1
fi

required_files=("capabilities.plist" "hardware.plist" "display.plist" "validation.json")
for file in "${required_files[@]}"; do
    if [[ ! -f "$PROFILE/$file" ]]; then
        echo "ERROR: Missing required file: $file"
        exit 1
    fi
done
echo "✓ Profile structure validated"
echo ""

# Boot simulator
echo "[4/4] Booting simulator..."
if xcrun simctl boot "$DEVICE_ID" 2>/dev/null; then
    echo "✓ Simulator booted successfully"
elif xcrun simctl list devices | grep -F "$DEVICE_ID" | grep -q "(Booted)"; then
    echo "✓ Simulator already running"
else
    echo "WARNING: Could not verify simulator boot status"
fi
echo ""

echo "=================================================="
echo "   Setup Complete!"
echo "=================================================="
echo "Device Name:    $DEVICE_NAME"
echo "Device UDID:    $DEVICE_ID"
echo "Profile Path:   $PROFILE"
echo "Runtime:        $RUNTIME"
echo ""
echo "Next steps:"
echo "  • Open Xcode and select this simulator"
echo "  • Build and run your app"
echo "  • Run 'xcrun simctl open $DEVICE_ID' to launch Simulator.app"
echo ""
