import SwiftUI

struct ContentView: View {
    @StateObject private var bleManager = BLEManager()
    @State private var showSettings = false

    var body: some View {
        NavigationView {
            VStack {
                // Status bar
                HStack {
                    Image(systemName: bluetoothIcon)
                        .foregroundColor(bluetoothColor)
                    Text(bluetoothStatusText)
                        .font(.subheadline)
                    Spacer()
                    if bleManager.isScanning {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Scanning...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemGray6))

                // Readings list
                if bleManager.readings.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("No readings yet")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        if !bleManager.isScanning && bleManager.bluetoothState == .poweredOn {
                            Text("Tap Start to scan for EnvSensor devices")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    Spacer()
                } else {
                    List(bleManager.readings) { reading in
                        SensorReadingRow(reading: reading)
                    }
                    .listStyle(.plain)
                }

                // Start/Stop button
                Button(action: toggleScanning) {
                    Text(bleManager.isScanning ? "Stop Scanning" : "Start Scanning")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(bleManager.bluetoothState == .poweredOn ? Color.blue : Color.gray)
                        .cornerRadius(10)
                }
                .padding()
                .disabled(bleManager.bluetoothState != .poweredOn)
            }
            .navigationTitle("EnvSensor Reader")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showSettings = true
                    }) {
                        Image(systemName: "gearshape")
                    }
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    if !bleManager.discoveredDevices.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                                .font(.caption)
                            Text("\(bleManager.discoveredDevices.count)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(bleManager: bleManager)
            }
        }
    }

    private var bluetoothIcon: String {
        switch bleManager.bluetoothState {
        case .poweredOn:
            return "bluetooth"
        case .poweredOff:
            return "bluetooth.slash"
        default:
            return "bluetooth"
        }
    }

    private var bluetoothColor: Color {
        bleManager.bluetoothState == .poweredOn ? .blue : .red
    }

    private var bluetoothStatusText: String {
        switch bleManager.bluetoothState {
        case .poweredOn:
            return "Bluetooth Ready"
        case .poweredOff:
            return "Bluetooth Off"
        case .unauthorized:
            return "Bluetooth Unauthorized"
        case .unsupported:
            return "Bluetooth Not Supported"
        default:
            return "Bluetooth Unknown"
        }
    }

    private func toggleScanning() {
        if bleManager.isScanning {
            bleManager.stopScanning()
        } else {
            bleManager.startScanning()
        }
    }
}

struct SensorReadingRow: View {
    let reading: SensorReading

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Text(reading.timestampString)
                    .font(.headline)
                Text("(\(String(format: "%04X", reading.nonce)))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(reading.rssi) dBm")
                    .font(.subheadline)
                    .foregroundColor(rssiColor(reading.rssi))
            }

            // Device address
            Text(reading.deviceAddress)
                .font(.caption)
                .foregroundColor(.secondary)

            // Environmental readings
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Temperature")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    HStack(spacing: 4) {
                        Image(systemName: "thermometer")
                            .foregroundColor(.red)
                        Text(String(format: "%.1f°C", reading.temperature))
                            .font(.system(.body, design: .monospaced))
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Humidity")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    HStack(spacing: 4) {
                        Image(systemName: "humidity")
                            .foregroundColor(.blue)
                        Text(String(format: "%.1f%%", reading.humidity))
                            .font(.system(.body, design: .monospaced))
                    }
                }
            }

            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Pressure")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    HStack(spacing: 4) {
                        Image(systemName: "gauge")
                            .foregroundColor(.purple)
                        Text(String(format: "%.1f hPa", reading.pressure))
                            .font(.system(.body, design: .monospaced))
                    }
                }
            }

            Divider()

            // Power readings
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Voltage")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    HStack(spacing: 4) {
                        Image(systemName: "bolt")
                            .foregroundColor(.orange)
                        Text(String(format: "%.2f V", reading.voltage))
                            .font(.system(.body, design: .monospaced))
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Current")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    HStack(spacing: 4) {
                        Image(systemName: "waveform.path")
                            .foregroundColor(.green)
                        Text(String(format: "%.2f mA", reading.current))
                            .font(.system(.body, design: .monospaced))
                    }
                }
            }

            HStack(spacing: 4) {
                Image(systemName: "power")
                    .foregroundColor(.yellow)
                Text("Power: ")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(String(format: "%.2f mW", reading.power))
                    .font(.system(.body, design: .monospaced))
            }
        }
        .padding(.vertical, 8)
    }

    private func rssiColor(_ rssi: Int) -> Color {
        if rssi > -60 {
            return .green
        } else if rssi > -80 {
            return .orange
        } else {
            return .red
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
