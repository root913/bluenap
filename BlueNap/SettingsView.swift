import LaunchAtLogin
import SwiftUI

struct SettingsView: View {
    @State private var launchAtLogin = LaunchAtLogin.isEnabled
    @State private var showMenuBarIcon = !UserDefaults.standard.bool(forKey: "hideIcon")
    @State private var devices: [PairedDevice] = []
    @State private var selected: Set<String> = []
    @State private var isRefreshing = false

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

            Section {
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
            } header: {
                HStack {
                    Text("Disconnect on sleep")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button {
                        refresh()
                    } label: {
                        if isRefreshing {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                    .buttonStyle(IconButtonStyle())
                    .disabled(isRefreshing)
                    .help("Refresh device list")
                    .accessibilityLabel("Refresh device list")
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 380)
        .padding()
        .onAppear(perform: reload)
        .onAppear {
            showMenuBarIcon = !UserDefaults.standard.bool(forKey: "hideIcon")
        }
        .onReceive(NotificationCenter.default.publisher(for: .statusItemVisibilityChanged)) { notification in
            if let isVisible = notification.object as? Bool {
                showMenuBarIcon = isVisible
            }
        }
    }

    private func refresh() {
        guard !isRefreshing else { return }
        isRefreshing = true
        reload()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isRefreshing = false
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

private struct IconButtonStyle: ButtonStyle {
    @State private var isHovering = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(isHovering ? Color.accentColor : Color.secondary)
            .padding(4)
            .background(isHovering ? Color.primary.opacity(0.1) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.easeInOut(duration: 0.15), value: isHovering)
            .onHover { hovering in
                isHovering = hovering
            }
    }
}
