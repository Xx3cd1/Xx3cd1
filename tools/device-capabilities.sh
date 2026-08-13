#!/bin/bash
set -euo pipefail

# Device Capabilities Query Interface
# Provides stable API for querying device specifications

PROFILE="${1:-devices/iPhone17ProMax}"
QUERY="${2:-all}"

if [[ ! -d "$PROFILE" ]]; then
    echo "ERROR: Profile directory not found: $PROFILE" >&2
    exit 1
fi

case "$QUERY" in
    model)
        # Get model identifier
        if command -v plutil &> /dev/null; then
            plutil -p "$PROFILE/capabilities.plist" | \
                grep -A1 "modelIdentifier" | \
                tail -1 | \
                awk '{print $NF}' | \
                tr -d '"'
        else
            echo "ERROR: plutil not found" >&2
            exit 1
        fi
        ;;

    device-name)
        # Get device name
        if command -v plutil &> /dev/null; then
            plutil -p "$PROFILE/capabilities.plist" | \
                grep -A1 "device-name" | \
                tail -1 | \
                awk '{print $NF}' | \
                tr -d '"'
        else
            echo "ERROR: plutil not found" >&2
            exit 1
        fi
        ;;

    display)
        # Get full display configuration
        if [[ -f "$PROFILE/display.plist" ]]; then
            plutil -p "$PROFILE/display.plist" 2>/dev/null || \
            cat "$PROFILE/display.plist"
        else
            echo "ERROR: display.plist not found" >&2
            exit 1
        fi
        ;;

    display:resolution)
        # Get just the resolution
        if command -v plutil &> /dev/null; then
            plutil -p "$PROFILE/display.plist" | \
                grep -A1 "resolution" | \
                tail -1 | \
                awk '{print $NF}' | \
                tr -d '"'
        else
            echo "ERROR: plutil not found" >&2
            exit 1
        fi
        ;;

    display:ppi)
        # Get pixel density
        if command -v plutil &> /dev/null; then
            plutil -p "$PROFILE/display.plist" | \
                grep -A1 "^  ppi" | \
                tail -1 | \
                awk '{print $NF}'
        else
            echo "ERROR: plutil not found" >&2
            exit 1
        fi
        ;;

    hardware)
        # Get hardware configuration
        if [[ -f "$PROFILE/hardware.plist" ]]; then
            plutil -p "$PROFILE/hardware.plist" 2>/dev/null || \
            cat "$PROFILE/hardware.plist"
        else
            echo "ERROR: hardware.plist not found" >&2
            exit 1
        fi
        ;;

    hardware:chip)
        # Get chip name
        if command -v plutil &> /dev/null; then
            plutil -p "$PROFILE/hardware.plist" | \
                grep -A1 "^  chip" | \
                tail -1 | \
                awk '{print $NF}' | \
                tr -d '"'
        else
            echo "ERROR: plutil not found" >&2
            exit 1
        fi
        ;;

    cameras)
        # Get camera configuration
        if [[ -f "$PROFILE/cameras.plist" ]]; then
            plutil -p "$PROFILE/cameras.plist" 2>/dev/null || \
            cat "$PROFILE/cameras.plist"
        else
            echo "ERROR: cameras.plist not found" >&2
            exit 1
        fi
        ;;

    sensors)
        # Get sensors configuration
        if [[ -f "$PROFILE/sensors.plist" ]]; then
            plutil -p "$PROFILE/sensors.plist" 2>/dev/null || \
            cat "$PROFILE/sensors.plist"
        else
            echo "ERROR: sensors.plist not found" >&2
            exit 1
        fi
        ;;

    connectivity)
        # Get connectivity options
        if [[ -f "$PROFILE/connectivity.plist" ]]; then
            plutil -p "$PROFILE/connectivity.plist" 2>/dev/null || \
            cat "$PROFILE/connectivity.plist"
        else
            echo "ERROR: connectivity.plist not found" >&2
            exit 1
        fi
        ;;

    software)
        # Get software configuration
        if [[ -f "$PROFILE/software.plist" ]]; then
            plutil -p "$PROFILE/software.plist" 2>/dev/null || \
            cat "$PROFILE/software.plist"
        else
            echo "ERROR: software.plist not found" >&2
            exit 1
        fi
        ;;

    software:version)
        # Get iOS version
        if command -v plutil &> /dev/null; then
            plutil -p "$PROFILE/software.plist" | \
                grep -A1 "major-version" | \
                tail -1 | \
                awk '{print $NF}'
        else
            echo "ERROR: plutil not found" >&2
            exit 1
        fi
        ;;

    all)
        # Print all capabilities in summary format
        echo "=================================================="
        echo "   Device Capabilities Summary"
        echo "=================================================="
        echo ""
        echo "Device Name: $(./tools/device-capabilities.sh "$PROFILE" device-name)"
        echo "Model ID: $(./tools/device-capabilities.sh "$PROFILE" model)"
        echo "Chip: $(./tools/device-capabilities.sh "$PROFILE" hardware:chip)"
        echo "Display: $(./tools/device-capabilities.sh "$PROFILE" display:resolution) @ $(./tools/device-capabilities.sh "$PROFILE" display:ppi) PPI"
        echo "iOS Version: 26"
        echo ""
        ;;

    *)
        echo "Unknown capability query: $QUERY" >&2
        echo ""
        echo "Available queries:" >&2
        echo "  model                - Device model identifier" >&2
        echo "  device-name          - Device marketing name" >&2
        echo "  display              - Full display configuration" >&2
        echo "  display:resolution   - Screen resolution" >&2
        echo "  display:ppi          - Pixel density" >&2
        echo "  hardware             - Full hardware configuration" >&2
        echo "  hardware:chip        - Processor name" >&2
        echo "  cameras              - Camera specifications" >&2
        echo "  sensors              - Sensor capabilities" >&2
        echo "  connectivity         - Network capabilities" >&2
        echo "  software             - OS and software features" >&2
        echo "  software:version     - iOS version" >&2
        echo "  all                  - Summary of all capabilities" >&2
        exit 2
        ;;
esac
