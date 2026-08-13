# iPhone 17 Pro Max Device Profile (v2)

## Overview

This directory contains the normalized device profile for the iPhone 17 Pro Max running iOS 26. The profile has been restructured into modular, single-responsibility layers to improve maintainability, testability, and scalability.

## Directory Structure

```
iPhone17ProMax/
├── capabilities.plist      # Core device capabilities and identifiers
├── hardware.plist          # Processor, memory, and storage specifications
├── display.plist           # Screen technology and dimensions
├── cameras.plist           # Camera systems and video capabilities
├── sensors.plist           # Motion, location, and biometric sensors
├── connectivity.plist      # Network and wireless capabilities
├── software.plist          # OS version and software features
├── simulator.plist         # Simulator and development support
├── validation.json         # Schema validation rules
└── README.md              # This file
```

## File Descriptions

### capabilities.plist
Core device identifiers and fundamental capabilities:
- Device name and marketing name
- Model identifier (iPhone18,2)
- Device idiom (phone)
- Graphics feature set (APPLE9)
- ARM64 and Metal support
- ASTC texture support

### hardware.plist
Processor, memory, and storage specifications:
- **Chip:** A19 Pro with 6-core CPU and 6-core GPU
- **Neural Engine:** 16-core for machine learning
- **Memory:** 8GB LPDDR5X
- **Storage Options:** 256GB, 512GB, 1TB

### display.plist
Display technology and screen specifications:
- **Technology:** Super Retina XDR OLED
- **Size:** 6.9-inch diagonal
- **Resolution:** 2868x1320 pixels
- **Pixel Density:** 460 PPI
- **Features:** ProMotion (120Hz), Always-On display, Dynamic Island
- **Color:** Wide Color P3

### cameras.plist
Rear and front camera specifications:

**Rear Cameras:**
- Main: 48MP, f/1.78, 1/1.28-inch sensor, OIS
- Telephoto: 12MP, f/2.8, 5x optical zoom, OIS
- Ultra-wide: 12MP, f/2.2, 120° field of view

**Front Camera:**
- 12MP, f/1.9, autofocus

**Video:**
- 4K recording at up to 60fps
- HDR video support

### sensors.plist
Motion, environmental, and biometric sensors:
- **Motion:** Accelerometer, Gyroscope, Magnetometer, Compass, Barometer
- **Environmental:** Proximity sensor, Ambient light sensor
- **Biometric:** Face ID (TrueDepth) — Touch ID not supported
- **Location:** GPS with multi-constellation support (GPS, GLONASS, Galileo, QZSS, BeiDou)

### connectivity.plist
Network and wireless capabilities:
- **Wi-Fi:** Wi-Fi 6E (802.11ax)
- **Cellular:** 5G and LTE
- **Wireless:** Bluetooth 5.3, Bluetooth LE, NFC
- **Ports:** USB-C
- **Interfaces:** DisplayPort support

### software.plist
Operating system and software features:
- **Platform:** iOS
- **Version:** iOS 26 (major version)
- **Minimum Deployment Target:** iOS 18.0
- **Swift Version:** 6.0
- **Features:** Multitasking, Split View, Picture-in-Picture, App Clips, Widgets, GameKit

### simulator.plist
Simulator and development environment support:
- Xcode Simulator support
- Simulator identifier for CoreSimulator
- Metal rendering engine support
- Screen recording capability

### validation.json
JSON schema for validating profile integrity:
- Defines validation rules for critical specifications
- Assigns severity levels (critical, high, medium, low)
- Used for CI/CD pipeline validation and testing

## Configuring the Environment

### Prerequisites

- macOS 12.0 or later
- Xcode 15.0 or later
- iOS 18.0 SDK or later
- Swift 6.0 toolchain

### Setup Instructions

#### 1. Clone the Repository

```bash
git clone https://github.com/Xx3cd1/Xx3cd1.git
cd Xx3cd1
```

#### 2. Navigate to Device Profile

```bash
cd devices/iPhone17ProMax
```

#### 3. Validate Profile Configuration

To validate the profile against the schema:

```bash
# Using Python (requires json module)
python3 -c "
import json
with open('validation.json') as f:
    schema = json.load(f)
    print('Validation schema loaded successfully')
    print(f'Total validation rules: {len(schema[\"validation_rules\"])}')
"
```

#### 4. Load Profile in Xcode

To use this profile in Xcode:

```bash
# Copy to Xcode's device profiles directory
cp -r iPhone17ProMax ~/Library/Developer/Xcode/DerivedData/DeviceProfiles/
```

#### 5. Verify Installation

Open Xcode and check:
- Window → Devices and Simulators
- Look for iPhone 17 Pro Max in the device list

### Integration with Development Workflow

#### Testing Against This Profile

```swift
import UIKit

// Access device capabilities at runtime
let idiom = UIDevice.current.userInterfaceIdiom
let model = UIDevice.current.model

if idiom == .phone && model == "iPhone" {
    // Code specifically for iPhone 17 Pro Max
    let screen = UIScreen.main
    let resolution = screen.nativeBounds
    // resolution should be 2868 x 1320 (in points: 1320 x 960)
}
```

#### Building with Profile Support

```bash
# Build for iPhone 17 Pro Max simulator
xcodebuild -scheme YourApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' build

# Build for device (if available)
xcodebuild -scheme YourApp -destination 'generic/platform=iOS' build
```

## Version History

- **v2 (Current):** Normalized multi-layer architecture
  - Separated concerns into focused modules
  - Added validation schema
  - Enhanced documentation
  - Improved maintainability

- **v1:** Monolithic profile structure

## Key Specifications Summary

| Aspect | Specification |
|--------|---------------|
| **Device** | iPhone 17 Pro Max |
| **Model ID** | iPhone18,2 |
| **OS** | iOS 26 |
| **Processor** | A19 Pro (6-core CPU, 6-core GPU, 16-core Neural Engine) |
| **RAM** | 8GB LPDDR5X |
| **Storage** | 256GB / 512GB / 1TB |
| **Display** | 6.9" Super Retina XDR OLED, 2868×1320 @ 460 PPI, 120Hz |
| **Rear Cameras** | 48MP (main) + 12MP (telephoto, 5x) + 12MP (ultra-wide) |
| **Front Camera** | 12MP with TrueDepth |
| **Connectivity** | 5G, Wi-Fi 6E, Bluetooth 5.3, NFC, USB-C |
| **Auth Method** | Face ID (TrueDepth) |
| **Graphics** | Metal with APPLE9 feature set |

## Notes

- This is a portable corrected profile derived from Apple's capabilities specification
- iPhone18,2 identifies the iPhone 17 Pro Max in Apple's diagnostic and developer records
- Apple's CoreSimulator capability schemas are private and subject to change
- ModelNumber and RegulatoryModelNumber have been intentionally omitted for accuracy

## Contributing

When updating this profile:

1. Update the relevant `.plist` file only
2. Run validation.json tests
3. Update this README if structure changes
4. Create a pull request with clear descriptions
5. Ensure all specifications are verified against official Apple documentation

## Resources

- [Apple Developer Documentation](https://developer.apple.com)
- [iOS Device Specifications](https://support.apple.com)
- [Xcode Simulator Documentation](https://developer.apple.com/documentation/xcode/simulator)
- [Plist Format Reference](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/PropertyLists/)

## License

This device profile is provided as-is for development and testing purposes.
