#!/bin/bash
set -euo pipefail

# Device Profile Import Validator
# Validates profile structure and plist syntax

PROFILE="${1:?Usage: $0 <profile-directory>}"

echo "=================================================="
echo "   Device Profile Import Validator"
echo "=================================================="
echo ""

if [[ ! -d "$PROFILE" ]]; then
    echo "ERROR: Profile directory not found: $PROFILE"
    exit 1
fi

echo "[1/4] Checking required files..."
required_files=(
    "capabilities.plist"
    "hardware.plist"
    "display.plist"
    "cameras.plist"
    "sensors.plist"
    "connectivity.plist"
    "software.plist"
    "simulator.plist"
    "validation.json"
)

missing=0
for file in "${required_files[@]}"; do
    if [[ -f "$PROFILE/$file" ]]; then
        echo "✓ $file"
    else
        echo "✗ MISSING: $file"
        ((missing++))
    fi
done

if [[ $missing -gt 0 ]]; then
    echo ""
    echo "ERROR: $missing required file(s) missing"
    exit 1
fi
echo ""

echo "[2/4] Validating plist syntax..."
plist_files=("capabilities.plist" "hardware.plist" "display.plist" "cameras.plist" "sensors.plist" "connectivity.plist" "software.plist" "simulator.plist")

for plist in "${plist_files[@]}"; do
    if plutil -lint "$PROFILE/$plist" > /dev/null 2>&1; then
        echo "✓ $plist (valid)"
    else
        echo "✗ $plist (INVALID)"
        plutil -lint "$PROFILE/$plist" || true
        exit 1
    fi
done
echo ""

echo "[3/4] Validating JSON schema..."
if command -v jq &> /dev/null; then
    if jq empty "$PROFILE/validation.json" 2>/dev/null; then
        echo "✓ validation.json (valid JSON)"
        rule_count=$(jq '.validation_rules | length' "$PROFILE/validation.json")
        echo "  Contains $rule_count validation rules"
    else
        echo "✗ validation.json (INVALID JSON)"
        exit 1
    fi
else
    echo "⚠ jq not found - skipping JSON validation"
fi
echo ""

echo "[4/4] Summary..."
file_count=$(ls -1 "$PROFILE" | wc -l)
echo "Profile directory: $PROFILE"
echo "Total files: $file_count"
echo "Required files: ${#required_files[@]} ✓"
echo ""

echo "=================================================="
echo "   Validation: PASSED"
echo "=================================================="
echo ""
echo "Profile is ready for import and use."
echo ""
