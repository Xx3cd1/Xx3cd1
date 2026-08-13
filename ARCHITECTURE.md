# Device Profile Architecture Guide

## Overview

This document outlines the recommended final architecture for device profile management, distinguishing between:

1. **Repository Profiles** - Configuration, simulation, and testing
2. **Runtime APIs** - Actual application capability detection
3. **Integration Layer** - How they work together

---

## Architecture Layers

### Layer 1: Repository Profiles (Configuration)

**Purpose:** Define device specifications for development, testing, and simulation.

**Location:** `devices/iPhone17ProMax/`

**Responsibilities:**
- Store baseline device specifications
- Configure simulator environments
- Enable consistent testing across teams
- Document hardware capabilities for reference

**Access Pattern:**
```bash
# Command-line tools for profile access
bash tools/device-capabilities.sh devices/iPhone17ProMax model
bash tools/device-capabilities.sh devices/iPhone17ProMax display:resolution
```

**Not for:** Runtime decision-making in production apps

---

### Layer 2: Runtime APIs (Actual Capability Detection)

**Purpose:** Determine actual device capabilities at runtime using Apple's official APIs.

**Why This Matters:**
```swift
// ❌ DON'T: Parse model identifier
if UIDevice.current.model.contains("iPhone18,2") {
    // Enable AR features
}

// ✅ DO: Use Apple's capability APIs
if ARWorldTrackingConfiguration.isSupported {
    // Enable AR features
}
```

**Key Differences:**

| Aspect | Repository Profile | Runtime API |
|--------|-------------------|-------------|
| **Source** | Static files | Live device info |
| **Reliability** | Reference only | Authoritative |
| **Updates** | Manual (repo commit) | Automatic (OS updates) |
| **Use Case** | Testing, CI/CD, docs | Production apps |
| **Accuracy** | ~95% (baseline) | 100% (actual device) |

---

### Layer 3: Integration Layer (DeviceCapabilities Framework)

**Purpose:** Provide a typed abstraction that queries Apple runtime APIs but maintains awareness of profile specifications.

**Architecture:**
```
┌──────────────────────────────────────────────────┐
│   Production Application Code                    │
└──────────────────────┬───────────────────────────┘
                 │
┌────────────────────────────────────────v──────────┐
│   DeviceCapabilities Framework (Swift)            │
│   ├─ RuntimeFeatures (Apple APIs)                 │
│   ├─ ProfileDefaults (Fallback specs)             │
│   └─ DeviceContext (High-level API)               │
└────────────────────────┬───────────────────────────┘
                 │
        ┌────────┴─────────┬──────────────┐
        │                  │              │
   ┌────v──────────┐  ┌────v──────────┐
   │  Apple       │  │ Profile       │
   │  Runtime     │  │  Config       │
   │  APIs        │  │  (plist)      │
   └──────────────┘  └───────────────┘
```

---

## iPhone 17 Pro Max Integration Tools 2–5

### Tools Overview

The repository includes five essential shell utilities for profile management:

- **`profile-validate.sh`** — validates required profile files, plist/JSON syntax, `iPhone18,2`, and known iPhone 16 contamination.
- **`profile-export.sh`** — validates and packages a profile.
- **`profile-import.sh`** — imports and validates a profile directory/archive.
- **`device-capabilities.sh`** — queries individual profile layers or all layers.
- **`xcode-profile-load.sh`** — automatic Xcode/Simulator loader.

### Usage

```bash
# Validate profile integrity
./tools/profile-validate.sh devices/iPhone17ProMax

# Export profile for sharing/backup
./tools/profile-export.sh devices/iPhone17ProMax

# Import profile from archive
./tools/profile-import.sh iPhone17ProMax-profile-export.tar.gz

# Query individual capabilities
./tools/device-capabilities.sh devices/iPhone17ProMax model
./tools/device-capabilities.sh devices/iPhone17ProMax display:resolution
./tools/device-capabilities.sh devices/iPhone17ProMax hardware:chip

# Query all capabilities
./tools/device-capabilities.sh devices/iPhone17ProMax all

# Setup simulator automatically
./tools/xcode-profile-load.sh devices/iPhone17ProMax
```

### Tool Features

#### profile-validate.sh
- ✓ Checks all 9 required files exist
- ✓ Validates plist syntax with `plutil`
- ✓ Validates JSON schema
- ✓ Confirms model identifier is `iPhone18,2`
- ✓ Detects iPhone 16 Pro Max contamination
- ✓ Generates detailed validation report

#### profile-export.sh
- ✓ Validates profile before export
- ✓ Creates timestamped export directory
- ✓ Generates manifest.json with metadata
- ✓ Exports device configuration
- ✓ Ready for archiving and distribution

#### profile-import.sh
- ✓ Validates archive format
- ✓ Checks all required files
- ✓ Verifies plist syntax
- ✓ Confirms specifications match iPhone 17 Pro Max
- ✓ Reports validation status

#### device-capabilities.sh
- ✓ Queries individual capabilities (model, display, hardware, etc.)
- ✓ Supports nested queries (display:resolution, hardware:chip)
- ✓ Generates summaries (all)
- ✓ Readable, machine-parseable output
- ✓ Comprehensive help documentation

#### xcode-profile-load.sh
- ✓ Checks iOS 26 runtime availability
- ✓ Creates simulator if needed
- ✓ Boots simulator automatically
- ✓ Validates profile structure
- ✓ Ready for immediate use in Xcode

---

## Implementation Strategy

### Step 1: Define Feature Detection Contracts

Create protocols that abstract both sources:

```swift
protocol DeviceFeatureProvider {
    // Camera capabilities
    func supportsFaceID() -> Bool
    func supportsProRawCapture() -> Bool
    
    // Location services
    func supportsLocationServices() -> Bool
    func supportsMultiGNSS() -> Bool
    
    // AR/ML
    func supportsARWorldTracking() -> Bool
    func supportsLiDAR() -> Bool
    
    // Display
    func supportsProMotion() -> Bool
    func supportsAlwaysOnDisplay() -> Bool
}
```

### Step 2: Implement Runtime Provider

Query Apple's official APIs:

```swift
import DeviceCheck
import CoreLocation
import ARKit
import Vision

class AppleRuntimeFeatureProvider: DeviceFeatureProvider {
    
    // MARK: - Camera & Authentication
    func supportsFaceID() -> Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) &&
               context.biometryType == .faceID
    }
    
    func supportsProRawCapture() -> Bool {
        // Check if camera system supports RAW capture
        guard #available(iOS 18, *) else { return false }
        return AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInTripleCamera],
            mediaType: .video,
            position: .back
        ).devices.contains { device in
            device.supportedColorSpaces.contains(.dcDCIRGB)
        }
    }
    
    // MARK: - Location
    func supportsLocationServices() -> Bool {
        CLLocationManager.locationServicesEnabled()
    }
    
    func supportsMultiGNSS() -> Bool {
        // iOS 16+: Multi-constellation GNSS support
        guard #available(iOS 16, *) else { return false }
        let manager = CLLocationManager()
        return manager.accuracyAuthorization == .fullAccuracy
    }
    
    // MARK: - AR/ML
    func supportsARWorldTracking() -> Bool {
        ARWorldTrackingConfiguration.isSupported
    }
    
    func supportsLiDAR() -> Bool {
        ARWorldTrackingConfiguration.supportsLiDARDepthData
    }
    
    // MARK: - Display
    func supportsProMotion() -> Bool {
        let screen = UIScreen.main
        // ProMotion = 120Hz or higher refresh rate
        return screen.maximumFramesPerSecond > 60
    }
    
    func supportsAlwaysOnDisplay() -> Bool {
        guard #available(iOS 16.1, *) else { return false }
        // Check for dynamic island, which requires always-on capable display
        return UIScreen.main.bounds.width < UIScreen.main.bounds.height &&
               UIApplication.shared.statusBarOrientation.isPortrait
    }
}
```

### Step 3: Implement Profile Provider (Fallback)

Read from plist configuration:

```swift
class ProfileFeatureProvider: DeviceFeatureProvider {
    private let profilePath: String
    
    init(profilePath: String = "devices/iPhone17ProMax") {
        self.profilePath = profilePath
    }
    
    private func loadPlist(_ filename: String) -> NSDictionary? {
        guard let path = Bundle.main.path(forResource: filename, ofType: "plist",
                                         inDirectory: profilePath) else {
            return nil
        }
        return NSDictionary(contentsOfFile: path)
    }
    
    func supportsFaceID() -> Bool {
        let sensors = loadPlist("sensors")
        return sensors?["face-id"] as? NSDictionary != nil
    }
    
    func supportsProRawCapture() -> Bool {
        let cameras = loadPlist("cameras")
        return cameras?["raw-support"] as? Bool ?? false
    }
    
    func supportsLocationServices() -> Bool {
        let sensors = loadPlist("sensors")
        return sensors?["location-services"] as? Bool ?? false
    }
    
    func supportsMultiGNSS() -> Bool {
        let sensors = loadPlist("sensors")
        if let gnss = sensors?["gps-variants"] as? [String] {
            return gnss.count > 1
        }
        return false
    }
    
    func supportsARWorldTracking() -> Bool {
        let capabilities = loadPlist("capabilities")
        return capabilities?["metal"] as? Bool ?? false
    }
    
    func supportsLiDAR() -> Bool {
        let sensors = loadPlist("sensors")
        return sensors?["lidar"] as? Bool ?? false
    }
    
    func supportsProMotion() -> Bool {
        let display = loadPlist("display")
        return display?["proMotion"] as? Bool ?? false
    }
    
    func supportsAlwaysOnDisplay() -> Bool {
        let display = loadPlist("display")
        return display?["alwaysOn"] as? Bool ?? false
    }
}
```

### Step 4: Create High-Level DeviceContext

```swift
class DeviceContext {
    /// Primary source: Apple runtime APIs
    private let runtimeProvider: DeviceFeatureProvider
    
    /// Fallback source: Profile specifications
    private let profileProvider: DeviceFeatureProvider?
    
    /// Environment override (testing)
    private let testingOverrides: [String: Bool]
    
    init(
        useRuntimeAPIs: Bool = true,
        profilePath: String? = nil,
        testingOverrides: [String: Bool] = [:]
    ) {
        self.runtimeProvider = AppleRuntimeFeatureProvider()
        self.profileProvider = profilePath.map { ProfileFeatureProvider(profilePath: $0) }
        self.testingOverrides = testingOverrides
    }
    
    // MARK: - Public API
    
    func supportsFaceID() -> Bool {
        // Priority: Testing override > Runtime API > Profile fallback
        if let override = testingOverrides["faceID"] {
            return override
        }
        return runtimeProvider.supportsFaceID() ||
               (profileProvider?.supportsFaceID() ?? false)
    }
    
    func supportsAR() -> Bool {
        if let override = testingOverrides["arSupport"] {
            return override
        }
        return runtimeProvider.supportsARWorldTracking() ||
               (profileProvider?.supportsARWorldTracking() ?? false)
    }
    
    func supportsLocationServices() -> Bool {
        if let override = testingOverrides["locationServices"] {
            return override
        }
        return runtimeProvider.supportsLocationServices() ||
               (profileProvider?.supportsLocationServices() ?? false)
    }
    
    func supportsProMotion() -> Bool {
        if let override = testingOverrides["proMotion"] {
            return override
        }
        return runtimeProvider.supportsProMotion() ||
               (profileProvider?.supportsProMotion() ?? false)
    }
    
    // MARK: - Device Information
    
    func deviceModel() -> String {
        UIDevice.current.model
    }
    
    func iosVersion() -> String {
        UIDevice.current.systemVersion
    }
}
```

### Step 5: Usage in Application Code

```swift
class MyViewController: UIViewController {
    let device = DeviceContext(useRuntimeAPIs: true)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Use high-level API
        if device.supportsAR() {
            setupARView()
        }
        
        if device.supportsFaceID() {
            setupBiometricAuth()
        }
        
        if device.supportsProMotion() {
            displayLink.preferredFramesPerSecond = 120
        }
    }
}

// MARK: - Testing
class MyViewControllerTests: XCTestCase {
    func testARFeatureOnSimulator() {
        // Override for testing
        let device = DeviceContext(testingOverrides: [
            "arSupport": true,
            "locationServices": true
        ])
        
        XCTAssertTrue(device.supportsAR())
    }
}
```

---

## Final Architecture Diagram

```
┌──────────────────────────────────────────────────────┐
│  iOS Application (Production)                        │
└──────────────────────────┬──────────────────────────┘
                      │
           DeviceContext (High-level)
           ├─ supportsAR()
           ├─ supportsFaceID()
           ├─ supportsLocationServices()
           └─ supportsProMotion()
                      │
        ┌─────────────┼─────────────┬────────────┐
        │             │              │            │
   ┌────v────────┐ ┌─v────────┐ ┌──v────────┐
   │  Testing  │ │ Runtime  │ │  Profile │
   │ Overrides │ │   APIs   │ │ Fallback │
   │           │ │  (Real)  │ │ (Plist)  │
   └───────────┘ │          │ └──────────┘
                 │ ┌────────────────────────┐
                 │ │ ARKit                  │
                 │ │ CoreLocation           │
                 │ │ DeviceCheck            │
                 │ │ AVFoundation           │
                 │ │ LocalAuthentication    │
                 │ │ UIKit                  │
                 │ └────────────────────────┘
                 │
                 └─> devices/iPhone17ProMax/
                     ├─ cameras.plist
                     ├─ sensors.plist
                     ├─ display.plist
                     └─ capabilities.plist

Decision Flow:

1. Testing Mode?
   → Use testingOverrides (for unit/UI tests)

2. Production Mode?
   → Query Apple Runtime APIs first (authoritative)
   → Fall back to profile specs (if APIs unavailable)
   → Profile specs used for simulator development
```

---

## Key Principles

### ✅ DO

- Use Apple's runtime APIs (`ARKit`, `CoreLocation`, `AVFoundation`, etc.) for production app logic
- Use repository profiles for simulator configuration and testing setup
- Use command-line tools (profile-validate, device-capabilities) for CI/CD
- Create a typed `DeviceContext` wrapper that abstracts both sources
- Implement testing overrides for unit/UI test scenarios
- Document which API determines each capability

### ❌ DON'T

- Parse model identifiers (`"iPhone18,2"`) in application logic
- Hardcode device-specific behavior based on model names
- Use repository profiles as the source of truth in production
- Ignore availability checks (`#available()` guards)
- Assume simulator and device capabilities are identical

---

## Integration with Repository Tools

### Profile-Based Configuration

```bash
# Development: Use profiles for simulator setup
bash tools/xcode-profile-load.sh devices/iPhone17ProMax

# Testing: Validate profiles before test runs
bash tools/profile-validate.sh devices/iPhone17ProMax

# CI/CD: Query profile specs in build scripts
bash tools/device-capabilities.sh devices/iPhone17ProMax hardware:chip
```

### Runtime Detection (In App)

```swift
// DeviceContext queries Apple APIs at runtime
let device = DeviceContext(useRuntimeAPIs: true)
if device.supportsAR() { /* ... */ }
```

### Testing Layer

```swift
// Override capabilities for testing
let device = DeviceContext(testingOverrides: ["arSupport": false])
XCTAssertFalse(device.supportsAR())
```

---

## Recommended File Structure

```
Xx3cd1/Xx3cd1/
├─ devices/
│  └─ iPhone17ProMax/           # Profile configuration
│     ├─ capabilities.plist
│     ├─ hardware.plist
│     ├─ display.plist
│     ├─ cameras.plist
│     ├─ sensors.plist
│     ├─ connectivity.plist
│     ├─ software.plist
│     ├─ simulator.plist
│     ├─ validation.json
│     └─ README.md
│
├─ tools/                         # Profile tools (CLI)
│  ├─ xcode-profile-load.sh
│  ├─ profile-export.sh
│  ├─ profile-import.sh
│  ├─ device-capabilities.sh
│  └─ profile-validate.sh
│
└─ Sources/
   └─ DeviceCapabilities/        # Swift framework
      ├─ DeviceContext.swift
      ├─ DeviceFeatureProvider.swift
      ├─ AppleRuntimeFeatureProvider.swift
      ├─ ProfileFeatureProvider.swift
      └─ README.md
```

---

## Summary

**Repository Profiles** provide:
- Configuration for simulators and testing
- Documentation of baseline device specs
- Consistent development environment setup via CLI tools

**Runtime APIs** provide:
- Authoritative capability detection
- Production-safe decision making
- Automatic updates with OS changes

**DeviceContext Framework** bridges them:
- Typed, high-level abstraction
- Testing overrides for unit/UI tests
- Seamless fallback behavior
- Single source of truth for app logic

**Command-line Tools** enable:
- Profile validation and verification
- Automated simulator setup
- CI/CD integration
- Device specification queries

This architecture ensures your app makes decisions based on **actual device capabilities**, not assumptions.
