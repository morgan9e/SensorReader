# EnvSensor Reader - iOS App

An iOS application for scanning and reading environmental sensor data from BLE devices named "EnvSensor".

## Features

- Real-time BLE scanning for EnvSensor devices
- Displays environmental readings:
  - Temperature (°C)
  - Humidity (%)
  - Pressure (hPa)
- Displays power metrics:
  - Voltage (V)
  - Current (mA)
  - Power (mW)
- Shows signal strength (RSSI in dBm)
- Automatic deduplication of readings based on nonce
- Clean, modern SwiftUI interface

## Requirements

- iOS 15.0 or later
- iPhone or iPad with Bluetooth LE support
- Xcode 15.0 or later (for building)

## BLE Protocol

The app scans for BLE devices with the following characteristics:

- **Device Name**: `EnvSensor`
- **Company ID**: `0xFFFF`
- **Data Format** (16 bytes, little-endian):
  - Bytes 0-1: Nonce (UInt16)
  - Bytes 2-3: Temperature (Int16, divide by 100 for °C)
  - Bytes 4-5: Humidity (UInt16, divide by 100 for %)
  - Bytes 6-9: Pressure (UInt32, divide by 10 for hPa)
  - Bytes 10-11: Voltage (UInt16, divide by 100 for V)
  - Bytes 12-15: Current (Int32, divide by 100 for mA)

## Building the App

### Using Xcode

1. Open `EnvSensorReader.xcodeproj` in Xcode
2. Select your target device or simulator
3. Press Cmd+R to build and run

### Using xcodebuild (command line)

For iOS device:
```bash
xcodebuild clean build \
  -project EnvSensorReader.xcodeproj \
  -scheme EnvSensorReader \
  -sdk iphoneos \
  -configuration Release
```

For iOS Simulator:
```bash
xcodebuild clean build \
  -project EnvSensorReader.xcodeproj \
  -scheme EnvSensorReader \
  -sdk iphonesimulator \
  -configuration Release
```

## GitHub Actions

This project includes a GitHub Actions workflow that automatically builds the app on every push to main/master/develop branches. The workflow:

- Builds for both iOS device and simulator
- Runs on macOS runners
- Archives build artifacts for download
- Supports manual triggering via workflow_dispatch

## Permissions

The app requires Bluetooth permissions to function. The following permissions are declared in Info.plist:

- `NSBluetoothAlwaysUsageDescription`: For scanning BLE devices
- `NSBluetoothPeripheralUsageDescription`: For BLE peripheral access

Users will be prompted to grant Bluetooth access when the app first launches.

## Project Structure

```
EnvSensorReader/
├── EnvSensorReader/
│   ├── EnvSensorReaderApp.swift    # App entry point
│   ├── ContentView.swift           # Main UI
│   ├── BLEManager.swift            # BLE scanning and parsing
│   ├── SensorReading.swift         # Data model
│   ├── Assets.xcassets/            # App assets
│   └── Info.plist                  # App configuration
├── EnvSensorReader.xcodeproj/      # Xcode project
└── .github/
    └── workflows/
        └── build.yml               # CI/CD workflow
```

## Python Version

This iOS app is a port of the Python script `env_reader.py` which uses the Bleak library for BLE scanning. Both versions implement the same protocol and functionality.

## License

This project is provided as-is for educational and development purposes.
