import AppKit
import IOBluetooth

struct PairedDevice: Identifiable {
    let address: String
    let name: String
    let isConnected: Bool

    var id: String { address }
}

final class BluetoothController {
    static let shared = BluetoothController()

    private static let disconnectOnSleepKey = "disconnectOnSleepDevices"

    private var observers: [NSObjectProtocol] = []
    private var disconnectedAtSleep: [String] = []

    private init() {}

    func debugLog(_ message: String) {
        let line = "\(Date()) \(message)\n"
        guard let data = line.data(using: .utf8) else { return }
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let url = directory.appendingPathComponent("bluenap.log")
        if let handle = try? FileHandle(forWritingTo: url) {
            handle.seekToEndOfFile()
            handle.write(data)
            try? handle.close()
        } else {
            try? data.write(to: url)
        }
    }

    func start() {
        installObservers()
        setPower(on: true)
    }

    // MARK: - Device selection

    var selectedDeviceAddresses: [String] {
        UserDefaults.standard.stringArray(forKey: Self.disconnectOnSleepKey) ?? []
    }

    func setSelected(_ address: String, isSelected: Bool) {
        var selection = selectedDeviceAddresses
        if isSelected {
            if !selection.contains(address) {
                selection.append(address)
            }
        } else {
            selection.removeAll { $0 == address }
        }
        UserDefaults.standard.set(selection, forKey: Self.disconnectOnSleepKey)
    }

    func pairedDevices() -> [PairedDevice] {
        pairedDevices().map { device in
            PairedDevice(
                address: device.addressString,
                name: device.nameOrAddress,
                isConnected: device.isConnected()
            )
        }
    }

    // MARK: - Sleep/wake

    private func installObservers() {
        let center = NSWorkspace.shared.notificationCenter
        observers = [
            center.addObserver(forName: NSWorkspace.willSleepNotification, object: nil, queue: .main) { [weak self] _ in
                self?.handlePowerDown()
            },
            center.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { [weak self] _ in
                self?.handlePowerUp()
            },
            center.addObserver(forName: NSWorkspace.willPowerOffNotification, object: nil, queue: .main) { [weak self] _ in
                self?.handlePowerDown()
            },
        ]
    }

    private func handlePowerDown() {
        let selection = selectedDeviceAddresses
        if selection.isEmpty {
            debugLog("sleep: powering off Bluetooth")
            setPower(on: false)
        } else {
            debugLog("sleep: disconnecting devices \(selection)")
            disconnectedAtSleep = selection
            disconnect(devices: selection)
        }
    }

    private func handlePowerUp() {
        setPower(on: true)
        let devices = disconnectedAtSleep
        disconnectedAtSleep = []
        guard !devices.isEmpty else { return }
        DispatchQueue.global().async { [weak self] in
            self?.debugLog("wake: reconnecting devices \(devices)")
            self?.reconnect(devices: devices)
        }
    }

    private func disconnect(devices: [String]) {
        for address in devices {
            debugLog("disconnect: \(address)")
            device(withAddress: address)?.closeConnection()
        }
    }

    private func reconnect(devices: [String]) {
        for address in devices {
            debugLog("reconnect: \(address)")
            device(withAddress: address)?.openConnection()
        }
    }

    private func device(withAddress address: String) -> IOBluetoothDevice? {
        pairedDevices().first { $0.addressString == address }
    }

    private func pairedDevices() -> [IOBluetoothDevice] {
        (IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice]) ?? []
    }

    private func setPower(on: Bool) {
        debugLog("setPower: \(on)")
        IOBluetoothPreferenceSetControllerPowerState(on ? 1 : 0)
    }
}
