import IOBluetooth

protocol BluetoothPowerControlling {
    func setPower(on: Bool)
}

protocol BluetoothDeviceConnecting {
    func disconnect(_ addresses: [String])
    func reconnect(_ addresses: [String])
}

struct IOBluetoothPowerController: BluetoothPowerControlling {
    func setPower(on: Bool) {
        IOBluetoothPreferenceSetControllerPowerState(on ? 1 : 0)
    }
}

struct IOBluetoothDeviceConnector: BluetoothDeviceConnecting {
    func disconnect(_ addresses: [String]) {
        for address in addresses {
            device(withAddress: address)?.closeConnection()
        }
    }

    func reconnect(_ addresses: [String]) {
        for address in addresses {
            device(withAddress: address)?.openConnection()
        }
    }

    private func device(withAddress address: String) -> IOBluetoothDevice? {
        (IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice])?
            .first { $0.addressString == address }
    }
}
