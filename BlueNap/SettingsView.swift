import LaunchAtLogin
import SwiftUI

struct SettingsView: View {
    @State private var launchAtLogin = LaunchAtLogin.isEnabled
    @State private var showMenuBarIcon = !UserDefaults.standard.bool(forKey: "hideIcon")
    @State private var devices: [PairedDevice] = []
    @State private var selected: Set<String> = []

    var body: some View {
        Form {
            Toggle("Launch at login", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { isEnabled in
                    LaunchAtLogin.isEnabled = isEnabled
                }

            Toggle("Show menu bar icon", isOn: $showMenuBarIcon)
                .onChange(of: showMenuBarIcon) { isVisible in
                    UserDefaults.standard.set(!isVisible, forKey: "hideIcon")
                    NotificationCenter.default.post(
                        name: .statusItemVisibilityChanged, object: isVisible
                    )
                }

            Section("Disconnect on sleep") {
                if devices.isEmpty {
                    Text("No paired devices")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(devices) { device in
                        Toggle(isOn: selectionBinding(for: device)) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(device.name)
                                if device.isConnected {
                                    Text("Connected")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 380)
        .padding()
        .onAppear(perform: reload)
        .toolbar {
            Button("Refresh") {
                reload()
            }
        }
    }

    private func reload() {
        devices = BluetoothController.shared.pairedDevices()
        selected = Set(BluetoothController.shared.selectedDeviceAddresses)
    }

    private func selectionBinding(for device: PairedDevice) -> Binding<Bool> {
        Binding(
            get: { selected.contains(device.address) },
            set: { isOn in
                if isOn {
                    selected.insert(device.address)
                } else {
                    selected.remove(device.address)
                }
                BluetoothController.shared.setSelected(device.address, isSelected: isOn)
            }
        )
    }
}
