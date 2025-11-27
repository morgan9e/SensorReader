# EnvSensor Reader - iOS App

An iOS application for scanning and reading environmental sensor data from BLE devices named "EnvSensor".

## Features

- **Real-time BLE scanning** for EnvSensor devices
- **Environmental readings display:**
  - Temperature (°C)
  - Humidity (%)
  - Pressure (hPa)
- **Power metrics display:**
  - Voltage (V)
  - Current (mA)
  - Power (mW)
- **Device Management:**
  - UUID-based device filtering (iOS doesn't expose MAC addresses)
  - Discovered devices list
  - Optional device whitelist
  - Discovery mode for debugging
- **Visual Features:**
  - Signal strength indicator (RSSI in dBm)
  - Color-coded RSSI display
  - Card-based UI with borders and shadows
  - Dark/Light mode support
- **Smart Features:**
  - Automatic deduplication of readings based on nonce
  - Keeps last 100 readings
  - Company ID filtering (0xFFFF)

## Requirements

- iOS 15.0 or later
- iPhone or iPad with Bluetooth LE support
- Xcode 15.0 or later (for building)

## Device Filtering

**Note:** iOS does not expose Bluetooth MAC addresses for privacy reasons. Instead, the app uses device UUIDs which are assigned by iOS.

### How to Filter Devices

1. **Start scanning** - The app will show all devices with Company ID `0xFFFF`
2. **Open Settings** - Tap the gear icon in the top-right
3. **View discovered devices** - All found devices are listed with their UUIDs
4. **Add to filter** - Tap "Add" next to any device to whitelist it
5. **Manual entry** - You can also manually enter UUIDs in the format `12345678-1234-1234-1234-123456789ABC`

When the whitelist is empty, all devices with the correct Company ID are shown. When you add devices to the whitelist, only those specific devices will display readings.

## BLE Protocol

The app scans for BLE devices with the following characteristics:

- **Company ID**: `0xFFFF` (required)
- **Device Name**: Optional, not used for filtering
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
