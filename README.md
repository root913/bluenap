![BlueNap logo](images/icon.png)

# BlueNap

**BlueNap prevents your sleeping Mac from connecting to Bluetooth accessories.**

If you pair Bluetooth headphones or speakers with both your phone & Mac it can be frustrating when your sleeping Mac connects intermittently and disrupts the audio.

With BlueNap the Bluetooth connection is switched off when your Mac sleeps, and switched on when your Mac wakes.

*BlueNap is a fork of [Bluesnooze](https://github.com/odm/Bluesnooze) by [Oliver Drobnik](https://github.com/odm), modernized (SwiftUI, Swift Package Manager, native menu, Settings window) and extended with a "Disconnect on sleep" feature. Licensed under the MIT License (see `LICENSE`).*

![Screenshot showing BlueNap in the status bar](images/screenshot.png)

![Screenshot showing the BlueNap settings window](images/screenshot-settings.png)

## Requirements

- macOS 13 (Ventura) or higher

## Installation

1. Build the release (`make all`), or grab a build from [Releases](https://github.com/root913/bluesnooze/releases/latest)
1. Open `BlueNap.app` in your `Applications` directory
1. *Optional*: Enable 'Launch at login' from the Settings window

## Caveats

- This app is not compatible with the "Allow your Apple Watch to unlock your Mac" feature.
- This app can't be distributed via the App Store because it uses a private API to switch Bluetooth on/off.

## How it works

BlueNap listens for the macOS sleep/wake notifications and toggles Bluetooth power via the private `IOBluetoothPreferenceSetControllerPowerState` API. It runs as a menu bar app (SwiftUI).

When you select devices under **Settings → Disconnect on sleep**, those devices are disconnected (instead of Bluetooth being powered off) when your Mac sleeps, and reconnected when it wakes.

## FAQs

### Can I disconnect only some devices on sleep?

Yes — open **Settings** and tick the devices to disconnect when your Mac sleeps. When at least one device is selected, Bluetooth stays on and only the selected devices are disconnected; if no device is selected, BlueNap falls back to switching Bluetooth off entirely.

Note: some devices (e.g. headphones) may reconnect to a sleeping Mac on their own, so selective disconnection is best-effort for auto-reconnecting hardware.

### How can I hide the BlueNap icon?

In your terminal run the following command:

```sh
defaults write dev.root913.bluenap hideIcon -bool true && killall BlueNap
```

When you next relaunch the application there should be no icon in the menu bar.

### How can I restore the BlueNap icon?

In your terminal run the following command:

```sh
defaults delete dev.root913.bluenap hideIcon && killall BlueNap
```

When you next relaunch the application it should appear in the menu bar.
