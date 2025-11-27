import Foundation
import CoreBluetooth
import Combine

class BLEManager: NSObject, ObservableObject {
    @Published var readings: [SensorReading] = []
    @Published var isScanning = false
    @Published var bluetoothState: CBManagerState = .unknown
    @Published var discoveredDevices: Set<String> = []

    private var centralManager: CBCentralManager!
    private var seenNonces: Set<String> = []

    // Configuration
    private let companyID: UInt16 = 0xFFFF

    // Optional: Set specific UUIDs to filter. Empty = accept all devices with correct company ID
    // Example: ["12345678-1234-1234-1234-123456789ABC"]
    var allowedUUIDs: Set<String> = []

    // Set to true to show all devices regardless of company ID (for discovery)
    var discoveryMode = false

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func startScanning() {
        guard centralManager.state == .poweredOn else {
            print("Bluetooth not ready")
            return
        }

        seenNonces.removeAll()
        centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        isScanning = true
        print("Started scanning for EnvSensor devices...")
    }

    func stopScanning() {
        centralManager.stopScan()
        isScanning = false
        print("Stopped scanning")
    }

    private func parseManufacturerData(_ data: Data) -> (nonce: UInt16, temp: Double, hum: Double, pres: Double, voltage: Double, current: Double)? {
        guard data.count == 16 else { return nil }

        let bytes = [UInt8](data)

        // Parse according to struct format: '<HhHIHi'
        // H = unsigned short (2 bytes)
        // h = signed short (2 bytes)
        // I = unsigned int (4 bytes)
        // i = signed int (4 bytes)

        let nonce = UInt16(bytes[0]) | (UInt16(bytes[1]) << 8)

        let tempRaw = Int16(bitPattern: UInt16(bytes[2]) | (UInt16(bytes[3]) << 8))
        let temp = Double(tempRaw) / 100.0

        let humRaw = UInt16(bytes[4]) | (UInt16(bytes[5]) << 8)
        let hum = Double(humRaw) / 100.0

        let presRaw = UInt32(bytes[6]) | (UInt32(bytes[7]) << 8) | (UInt32(bytes[8]) << 16) | (UInt32(bytes[9]) << 24)
        let pres = Double(presRaw) / 10.0

        let voltageRaw = UInt16(bytes[10]) | (UInt16(bytes[11]) << 8)
        let voltage = Double(voltageRaw) / 100.0

        let currentRaw = Int32(bitPattern: UInt32(bytes[12]) | (UInt32(bytes[13]) << 8) | (UInt32(bytes[14]) << 16) | (UInt32(bytes[15]) << 24))
        let current = Double(currentRaw) / 100.0

        return (nonce, temp, hum, pres, voltage, current)
    }
}

extension BLEManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        bluetoothState = central.state

        switch central.state {
        case .poweredOn:
            print("Bluetooth is powered on")
        case .poweredOff:
            print("Bluetooth is powered off")
            isScanning = false
        case .unauthorized:
            print("Bluetooth is unauthorized")
        case .unsupported:
            print("Bluetooth is not supported")
        default:
            print("Bluetooth state: \(central.state.rawValue)")
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        let deviceUUID = peripheral.identifier.uuidString

        // Check for manufacturer data
        guard let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data,
              manufacturerData.count >= 2 else {
            // In discovery mode, log devices without manufacturer data
            if discoveryMode {
                print("Device without manufacturer data: \(deviceUUID) (\(peripheral.name ?? "Unknown"))")
            }
            return
        }

        // Extract company ID (first 2 bytes, little-endian)
        let companyIDBytes = manufacturerData.prefix(2)
        let extractedCompanyID = UInt16(companyIDBytes[0]) | (UInt16(companyIDBytes[1]) << 8)

        // In discovery mode, log all devices with their company IDs
        if discoveryMode {
            print("Discovered: \(deviceUUID) (\(peripheral.name ?? "Unknown")) - Company ID: 0x\(String(format: "%04X", extractedCompanyID))")
        }

        // Filter by company ID
        guard extractedCompanyID == companyID else {
            return
        }

        // Add to discovered devices
        DispatchQueue.main.async {
            self.discoveredDevices.insert(deviceUUID)
        }

        // Filter by UUID whitelist if configured
        if !allowedUUIDs.isEmpty && !allowedUUIDs.contains(deviceUUID) {
            return
        }

        // Parse the payload (skip the first 2 bytes which are the company ID)
        let payload = manufacturerData.dropFirst(2)

        guard let parsed = parseManufacturerData(payload) else {
            return
        }

        // Create unique key for deduplication
        let key = "\(deviceUUID)-\(parsed.nonce)"
        guard !seenNonces.contains(key) else {
            return
        }
        seenNonces.insert(key)

        // Create reading
        let reading = SensorReading(
            timestamp: Date(),
            deviceAddress: peripheral.identifier.uuidString,
            nonce: parsed.nonce,
            temperature: parsed.temp,
            humidity: parsed.hum,
            pressure: parsed.pres,
            voltage: parsed.voltage,
            current: parsed.current,
            rssi: RSSI.intValue
        )

        DispatchQueue.main.async {
            self.readings.insert(reading, at: 0)

            // Keep only last 100 readings
            if self.readings.count > 100 {
                self.readings = Array(self.readings.prefix(100))
            }
        }

        let deviceName = peripheral.name ?? "Unknown"
        print("[\(reading.timestampString)] (\(String(format: "%04X", parsed.nonce))) \(deviceUUID) (\(deviceName))")
        print("  T=\(String(format: "%5.1f", parsed.temp))°C  H=\(String(format: "%5.1f", parsed.hum))%  P=\(String(format: "%7.1f", parsed.pres))hPa")
        print("  V=\(String(format: "%5.2f", parsed.voltage))V  I=\(String(format: "%7.2f", parsed.current))mA  P=\(String(format: "%7.2f", reading.power))mW")
        print("  RSSI=\(String(format: "%3d", RSSI.intValue))dBm")
        print()
    }
}
