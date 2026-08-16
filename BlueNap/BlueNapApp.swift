import AppKit
import SwiftUI

extension Notification.Name {
    static let statusItemVisibilityChanged = Notification.Name("statusItemVisibilityChanged")
}

@main
struct BlueNapApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            SettingsView()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var settingsObserver: NSObjectProtocol?
    private var statusItemObserver: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {
        BluetoothController.shared.debugLog("app did finish launching")
        BluetoothController.shared.start()

        settingsObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification, object: nil, queue: .main
        ) { _ in
            DispatchQueue.main.async {
                if !NSApp.windows.contains(where: { $0.title == "BlueNap Settings" && $0.isVisible }) {
                    NSApp.setActivationPolicy(.accessory)
                }
            }
        }

        statusItemObserver = NotificationCenter.default.addObserver(
            forName: .statusItemVisibilityChanged, object: nil, queue: .main
        ) { [weak self] notification in
            guard let show = notification.object as? Bool else { return }
            if show {
                self?.installStatusItem()
            } else {
                self?.removeStatusItem()
            }
        }

        guard !UserDefaults.standard.bool(forKey: "hideIcon") else { return }
        installStatusItem()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        guard statusItem == nil else { return true }
        UserDefaults.standard.set(false, forKey: "hideIcon")
        installStatusItem()
        openSettings()
        return true
    }

    private func installStatusItem() {
        guard statusItem == nil else { return }
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        let image = NSImage(named: "bluenap")
        image?.isTemplate = true
        statusItem.button?.image = image
        statusItem.menu = buildMenu()
        self.statusItem = statusItem
    }

    private func removeStatusItem() {
        guard let statusItem else { return }
        NSStatusBar.system.removeStatusItem(statusItem)
        self.statusItem = nil
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()
        menu.autoenablesItems = false

        let settingsItem = NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit BlueNap", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        return menu
    }

    @objc private func openSettings() {
        NSApp.setActivationPolicy(.regular)
        if let item = settingsMenuItem(), let action = item.action {
            NSApp.sendAction(action, to: item.target, from: item)
        } else {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        }
        findSettingsWindow()?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func settingsMenuItem() -> NSMenuItem? {
        for topLevel in NSApp.mainMenu?.items ?? [] {
            for item in topLevel.submenu?.items ?? [] where item.title == "Settings…" {
                return item
            }
        }
        return nil
    }

    private func findSettingsWindow() -> NSWindow? {
        NSApp.windows.first { $0.title == "BlueNap Settings" }
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}
