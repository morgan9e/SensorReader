import SwiftUI

struct SettingsView: View {
    @ObservedObject var bleManager: BLEManager
    @State private var newUUID = ""
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Discovered Devices")) {
                    if bleManager.discoveredDevices.isEmpty {
                        Text("No devices discovered yet")
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        ForEach(Array(bleManager.discoveredDevices).sorted(), id: \.self) { uuid in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(uuid)
                                        .font(.system(.caption, design: .monospaced))
                                    Text(bleManager.allowedUUIDs.contains(uuid) ? "Allowed" : "Not filtered")
                                        .font(.caption2)
                                        .foregroundColor(bleManager.allowedUUIDs.contains(uuid) ? .green : .secondary)
                                }
                                Spacer()
                                if bleManager.allowedUUIDs.contains(uuid) {
                                    Button("Remove") {
                                        bleManager.allowedUUIDs.remove(uuid)
                                    }
                                    .foregroundColor(.red)
                                } else {
                                    Button("Add") {
                                        bleManager.allowedUUIDs.insert(uuid)
                                    }
                                }
                            }
                        }
                    }
                }

                Section(header: Text("Device Filter")) {
                    Toggle("Filter by UUID", isOn: Binding(
                        get: { !bleManager.allowedUUIDs.isEmpty },
                        set: { enabled in
                            if !enabled {
                                bleManager.allowedUUIDs.removeAll()
                            }
                        }
                    ))

                    if !bleManager.allowedUUIDs.isEmpty {
                        Text("Only devices with these UUIDs will be shown")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        ForEach(Array(bleManager.allowedUUIDs).sorted(), id: \.self) { uuid in
                            HStack {
                                Text(uuid)
                                    .font(.system(.caption, design: .monospaced))
                                Spacer()
                                Button(action: {
                                    bleManager.allowedUUIDs.remove(uuid)
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    } else {
                        Text("All devices with Company ID 0xFFFF will be shown")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Section(header: Text("Manual UUID Entry")) {
                    HStack {
                        TextField("Enter UUID", text: $newUUID)
                            .autocapitalization(.allCharacters)
                            .font(.system(.body, design: .monospaced))
                        Button("Add") {
                            let trimmed = newUUID.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
                            if !trimmed.isEmpty {
                                bleManager.allowedUUIDs.insert(trimmed)
                                newUUID = ""
                            }
                        }
                        .disabled(newUUID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    Text("Format: 12345678-1234-1234-1234-123456789ABC")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Section(header: Text("Advanced")) {
                    Toggle("Discovery Mode", isOn: $bleManager.discoveryMode)
                    Text("Shows all BLE devices in console logs")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section {
                    Button("Clear All Filters") {
                        bleManager.allowedUUIDs.removeAll()
                    }
                    .foregroundColor(.red)
                    .disabled(bleManager.allowedUUIDs.isEmpty)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
