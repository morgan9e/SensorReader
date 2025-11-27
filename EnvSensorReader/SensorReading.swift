import Foundation

struct SensorReading: Identifiable, Equatable {
    let id = UUID()
    let timestamp: Date
    let deviceAddress: String
    let nonce: UInt16
    let temperature: Double
    let humidity: Double
    let pressure: Double
    let voltage: Double
    let current: Double
    let rssi: Int

    var power: Double {
        voltage * current
    }

    var timestampString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: timestamp)
    }

    static func == (lhs: SensorReading, rhs: SensorReading) -> Bool {
        lhs.deviceAddress == rhs.deviceAddress && lhs.nonce == rhs.nonce
    }
}
