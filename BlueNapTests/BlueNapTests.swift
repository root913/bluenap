import XCTest
@testable import BlueNap

final class BlueNapTests: XCTestCase {
    func testSetSelectedPersistsAddresses() {
        let defaults = makeDefaults()
        let controller = makeController(userDefaults: defaults)

        controller.setSelected("AA:BB", isSelected: true)
        controller.setSelected("CC:DD", isSelected: true)
        controller.setSelected("AA:BB", isSelected: false)

        XCTAssertEqual(controller.selectedDeviceAddresses, ["CC:DD"])
    }

    func testHandlePowerDownWithoutSelectionPowersOffBluetooth() {
        let power = MockPowerController()
        let connector = MockDeviceConnector()
        let controller = makeController(power: power, connector: connector)

        controller.handlePowerDown()

        XCTAssertEqual(power.calls, [false])
        XCTAssertTrue(connector.disconnected.isEmpty)
    }

    func testHandlePowerDownWithSelectionDisconnectsDevicesInsteadOfPoweringOff() {
        let defaults = makeDefaults()
        defaults.set(["AA:BB", "CC:DD"], forKey: "disconnectOnSleepDevices")
        let power = MockPowerController()
        let connector = MockDeviceConnector()
        let controller = makeController(power: power, connector: connector, userDefaults: defaults)

        controller.handlePowerDown()

        XCTAssertTrue(power.calls.isEmpty)
        XCTAssertEqual(connector.disconnected, [["AA:BB", "CC:DD"]])
    }

    func testHandlePowerUpAlwaysPowersOnBluetooth() {
        let power = MockPowerController()
        let connector = MockDeviceConnector()
        let controller = makeController(power: power, connector: connector)

        controller.handlePowerUp()

        XCTAssertEqual(power.calls, [true])
        XCTAssertTrue(connector.reconnected.isEmpty)
    }

    func testHandlePowerUpReconnectsDevicesDisconnectedOnSleep() {
        let defaults = makeDefaults()
        defaults.set(["AA:BB", "CC:DD"], forKey: "disconnectOnSleepDevices")
        let power = MockPowerController()
        let connector = MockDeviceConnector()
        let reconnected = expectation(description: "reconnected")
        let controller = makeController(
            power: power,
            connector: connector,
            userDefaults: defaults,
            runAsync: { work in
                work()
                reconnected.fulfill()
            }
        )

        controller.handlePowerDown()
        controller.handlePowerUp()

        wait(for: [reconnected], timeout: 1)
        XCTAssertEqual(power.calls, [true])
        XCTAssertEqual(connector.disconnected, [["AA:BB", "CC:DD"]])
        XCTAssertEqual(connector.reconnected, [["AA:BB", "CC:DD"]])
    }

    private func makeController(
        power: MockPowerController = MockPowerController(),
        connector: MockDeviceConnector = MockDeviceConnector(),
        userDefaults: UserDefaults? = nil,
        runAsync: @escaping (@escaping () -> Void) -> Void = { work in work() }
    ) -> BluetoothController {
        let defaults = userDefaults ?? makeDefaults()
        return BluetoothController(
            powerController: power,
            deviceConnector: connector,
            userDefaults: defaults,
            runAsync: runAsync
        )
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "BlueNapTests-\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            fatalError("Failed to create UserDefaults suite")
        }
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}

private final class MockPowerController: BluetoothPowerControlling {
    private(set) var calls: [Bool] = []

    func setPower(on: Bool) {
        calls.append(on)
    }
}

private final class MockDeviceConnector: BluetoothDeviceConnecting {
    private(set) var disconnected: [[String]] = []
    private(set) var reconnected: [[String]] = []

    func disconnect(_ addresses: [String]) {
        disconnected.append(addresses)
    }

    func reconnect(_ addresses: [String]) {
        reconnected.append(addresses)
    }
}
