#!/bin/bash
set -euo pipefail

# Device Profile Validator
# Validates profile against schema and runs integration tests

PROFILE="${1:-devices/iPhone17ProMax}"
VERBOSE="${2:-false}"

echo "=================================================="
echo "   Device Profile Validator"
echo "=================================================="
echo ""

if [[ ! -d "$PROFILE" ]]; then
    echo "ERROR: Profile directory not found: $PROFILE"
    exit 1
fi

if [[ ! -f "$PROFILE/validation.json" ]]; then
    echo "ERROR: validation.json not found in profile"
    exit 1
fi

# Counter for passed/failed tests
PASSED=0
FAILED=0

echo "[1/3] Structural Validation..."
echo ""

# Check all required files exist
echo "Checking required files:"
required_files=("capabilities.plist" "hardware.plist" "display.plist" "cameras.plist" "sensors.plist" "connectivity.plist" "software.plist" "simulator.plist" "validation.json")

for file in "${required_files[@]}"; do
    if [[ -f "$PROFILE/$file" ]]; then
        echo "  ✓ $file"
        ((PASSED++))
    else
        echo "  ✗ $file (MISSING)"
        ((FAILED++))
    fi
done
echo ""

echo "[2/3] Syntax Validation..."
echo ""

# Validate plist files
echo "Validating plist files:"
for plist in "${required_files[@]:0:8}"; do  # All except validation.json
    if plutil -lint "$PROFILE/$plist" > /dev/null 2>&1; then
        echo "  ✓ $plist"
        ((PASSED++))
    else
        echo "  ✗ $plist (INVALID SYNTAX)"
        if [[ "$VERBOSE" == "true" ]]; then
            plutil -lint "$PROFILE/$plist"
        fi
        ((FAILED++))
    fi
done
echo ""

# Validate JSON
echo "Validating JSON schema:"
if command -v jq &> /dev/null; then
    if jq empty "$PROFILE/validation.json" 2>/dev/null; then
        echo "  ✓ validation.json (valid JSON)"
        ((PASSED++))
    else
        echo "  ✗ validation.json (INVALID JSON)"
        ((FAILED++))
    fi
else
    echo "  ⚠ jq not found - skipping JSON validation"
fi
echo ""

echo "[3/3] Content Validation..."
echo ""

# Validate critical specifications
echo "Checking critical specifications:"

# Check model identifier
if plutil -p "$PROFILE/capabilities.plist" 2>/dev/null | grep -q "iPhone18,2"; then
    echo "  ✓ Model ID is iPhone18,2"
    ((PASSED++))
else
    echo "  ✗ Model ID mismatch or not found"
    ((FAILED++))
fi

# Check display resolution
if plutil -p "$PROFILE/display.plist" 2>/dev/null | grep -q "2868x1320"; then
    echo "  ✓ Display resolution is 2868x1320"
    ((PASSED++))
else
    echo "  ✗ Display resolution mismatch or not found"
    ((FAILED++))
fi

# Check chip specification
if plutil -p "$PROFILE/hardware.plist" 2>/dev/null | grep -q "A19 Pro"; then
    echo "  ✓ Chip is A19 Pro"
    ((PASSED++))
else
    echo "  ✗ Chip specification mismatch or not found"
    ((FAILED++))
fi

# Check iOS version
if plutil -p "$PROFILE/software.plist" 2>/dev/null | grep -q "26"; then
    echo "  ✓ iOS major version is 26"
    ((PASSED++))
else
    echo "  ✗ iOS version mismatch or not found"
    ((FAILED++))
fi

# Check 5G support
if plutil -p "$PROFILE/connectivity.plist" 2>/dev/null | grep -q "5G"; then
    echo "  ✓ 5G connectivity is supported"
    ((PASSED++))
else
    echo "  ✗ 5G support not found"
    ((FAILED++))
fi

echo ""
echo "=================================================="
echo "   Validation Report"
echo "=================================================="
echo "Profile: $PROFILE"
echo "Passed: $PASSED tests"
echo "Failed: $FAILED tests"
echo ""

if [[ $FAILED -eq 0 ]]; then
    echo "Status: ✓ ALL TESTS PASSED"
    echo ""
    exit 0
else
    echo "Status: ✗ VALIDATION FAILED"
    echo ""
    exit 1
fi
