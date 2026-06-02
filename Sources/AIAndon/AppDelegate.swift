import AppKit
import ServiceManagement

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var menuBarController: MenuBarIcon!
    private var lightWindow: StatusLightWindow?
    private var monitor: SessionMonitor!
    private var timer: Timer?
    private var launchAtLogin: Bool {
        get { UserDefaults.standard.bool(forKey: "LaunchAtLogin") }
        set {
            UserDefaults.standard.set(newValue, forKey: "LaunchAtLogin")
            applyLaunchAtLogin(newValue)
        }
    }
    private var isVertical: Bool {
        get {
            let v = UserDefaults.standard.object(forKey: "WindowOrientation")
            return v == nil ? true : UserDefaults.standard.bool(forKey: "WindowOrientation")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "WindowOrientation")
            lightWindow?.isVertical = newValue
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        monitor = SessionMonitor()
        setupMenuBar()

        if showWindow {
            setupLightWindow()
        }

        timer = Timer(timeInterval: 0.1, target: self, selector: #selector(tick), userInfo: nil, repeats: true)
        RunLoop.main.add(timer!, forMode: .common)
    }

    private var showWindow: Bool {
        get { UserDefaults.standard.bool(forKey: "ShowWindow") }
        set {
            UserDefaults.standard.set(newValue, forKey: "ShowWindow")
            applyWindowVisibility()
        }
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        menuBarController = MenuBarIcon(statusItem: statusItem)

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Claude Andon", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())

        let windowItem = NSMenuItem(title: "显示窗口", action: #selector(toggleWindow(_:)), keyEquivalent: "w")
        windowItem.state = showWindow ? .on : .off
        menu.addItem(windowItem)

        let orientationItem = NSMenuItem(title: "水平方向", action: #selector(toggleOrientation(_:)), keyEquivalent: "")
        orientationItem.state = isVertical ? .off : .on
        menu.addItem(orientationItem)

        let launchItem = NSMenuItem(title: "开机自动启动", action: #selector(toggleLaunchAtLogin(_:)), keyEquivalent: "")
        launchItem.state = launchAtLogin ? .on : .off
        menu.addItem(launchItem)

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = menu
    }

    @objc private func toggleLaunchAtLogin(_ sender: NSMenuItem) {
        launchAtLogin = !launchAtLogin
        sender.state = launchAtLogin ? .on : .off
    }

    private func applyLaunchAtLogin(_ enable: Bool) {
        do {
            if enable {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Launch at login error: \(error)")
        }
    }

    private func setupLightWindow() {
        lightWindow = StatusLightWindow()
        lightWindow?.isVertical = isVertical
        lightWindow?.makeKeyAndOrderFront(nil)
    }

    @objc private func toggleOrientation(_ sender: NSMenuItem) {
        isVertical = !isVertical
        sender.state = isVertical ? .off : .on
    }

    @objc private func toggleWindow(_ sender: NSMenuItem) {
        showWindow = !showWindow
        sender.state = showWindow ? .on : .off
    }

    private func applyWindowVisibility() {
        if showWindow {
            if lightWindow == nil { setupLightWindow() }
            lightWindow?.makeKeyAndOrderFront(nil)
        } else {
            lightWindow?.orderOut(nil)
        }
    }

    @objc private func tick() {
        let sessions = monitor.updateState()
        let aggregate = SessionMonitor.aggregateState(sessions)
        lightWindow?.updateSessions(sessions)
        menuBarController.updateState(aggregate)
    }

    func applicationWillTerminate(_ notification: Notification) {
        timer?.invalidate()
    }
}
