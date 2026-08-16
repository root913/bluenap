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

    private let powerController: BluetoothPowerControlling
    private let deviceConnector: BluetoothDeviceConnecting
    private let userDefaults: UserDefaults
    private let runAsync: (@escaping () -> Void) -> Void
    private var observers: [NSObjectProtocol] = []
    private var disconnectedAtSleep: [String] = []

    init(
        powerController: BluetoothPowerControlling = IOBluetoothPowerController(),
        deviceConnector: BluetoothDeviceConnecting = IOBluetoothDeviceConnector(),
        userDefaults: UserDefaults = .standard,
        runAsync: @escaping (@escaping () -> Void) -> Void = { work in
            DispatchQueue.global().async(execute: work)
        }
    ) {
        self.powerController = powerController
        self.deviceConnector = deviceConnector
        self.userDefaults = userDefaults
        self.runAsync = runAsync
    }

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
        userDefaults.stringArray(forKey: Self.disconnectOnSleepKey) ?? []
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
        userDefaults.set(selection, forKey: Self.disconnectOnSleepKey)
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

    func handlePowerDown() {
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

    func handlePowerUp() {
        setPower(on: true)
        let devices = disconnectedAtSleep
        disconnectedAtSleep = []
        guard !devices.isEmpty else { return }
        runAsync { [weak self] in
            self?.debugLog("wake: reconnecting devices \(devices)")
            self?.reconnect(devices: devices)
        }
    }

    private func disconnect(devices: [String]) {
        for address in devices {
            debugLog("disconnect: \(address)")
        }
        deviceConnector.disconnect(devices)
    }

    private func reconnect(devices: [String]) {
        for address in devices {
            debugLog("reconnect: \(address)")
        }
        deviceConnector.reconnect(devices)
    }

    private func pairedDevices() -> [IOBluetoothDevice] {
        (IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice]) ?? []
    }

    private func setPower(on: Bool) {
        debugLog("setPower: \(on)")
        powerController.setPower(on: on)
    }
}
