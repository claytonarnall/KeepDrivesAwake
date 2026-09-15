import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var timer: Timer?
    private var config = Config.default
    private var lastResult: PingResult?
    private var lastOkCount = 0

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppLog.line("KeepDrivesAwake started")
        config = ConfigStore.load()
        setupStatusItem()
        pingNow()
        startTimer()
    }

    func applicationWillTerminate(_ notification: Notification) {
        timer?.invalidate()
        AppLog.line("KeepDrivesAwake quit")
    }

    private func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.image = NSImage(systemSymbolName: "externaldrive.fill", accessibilityDescription: "Keep Drives Awake")
        item.button?.image?.isTemplate = true
        statusItem = item
        rebuildMenu()
    }

    private func startTimer() {
        timer?.invalidate()
        let timer = Timer.scheduledTimer(withTimeInterval: config.pollInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.pingNow()
            }
        }
        timer.tolerance = min(5, config.pollInterval / 5)
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func pingNow() {
        let current = config
        let result = DrivePinger.ping(config: current)
        lastResult = result
        lastOkCount = result.statuses.values.filter { $0 == .ok }.count
        rebuildMenu()
    }

    private func rebuildMenu() {
        let menu = NSMenu()
        menu.addItem(header("Keep Drives Awake"))

        if let result = lastResult {
            let relative = Self.relativeTime(result.at)
            menu.addItem(header("Last poll \(relative)"))
            for path in config.volumes {
                let name = URL(fileURLWithPath: path).lastPathComponent
                let status = result.statuses[path] ?? .missing
                let item = NSMenuItem(title: "\(name): \(status.menuText)", action: nil, keyEquivalent: "")
                item.isEnabled = false
                menu.addItem(item)
            }
        } else {
            menu.addItem(header("Waiting for first poll…"))
        }

        menu.addItem(.separator())
        let pingItem = menu.addItem(withTitle: "Ping now", action: #selector(pingNowAction), keyEquivalent: "r")
        pingItem.target = self
        let logItem = menu.addItem(withTitle: "Open log", action: #selector(openLog), keyEquivalent: "l")
        logItem.target = self
        let configItem = menu.addItem(withTitle: "Open config", action: #selector(openConfig), keyEquivalent: ",")
        configItem.target = self
        menu.addItem(.separator())
        let quitItem = menu.addItem(withTitle: "Quit Keep Drives Awake", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quitItem.target = NSApp
        statusItem?.menu = menu
        statusItem?.button?.toolTip = tooltip()
    }

    private func tooltip() -> String {
        if lastOkCount == config.volumes.count, lastOkCount > 0 {
            return "Keep Drives Awake — all volumes OK"
        }
        if lastResult?.statuses.values.contains(.denied) == true {
            return "Keep Drives Awake — grant Removable Volumes access"
        }
        return "Keep Drives Awake"
    }

    private func header(_ title: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }

    @objc private func pingNowAction() {
        pingNow()
    }

    @objc private func openLog() {
        NSWorkspace.shared.open(AppLog.logURL)
    }

    @objc private func openConfig() {
        _ = ConfigStore.load()
        NSWorkspace.shared.open(ConfigStore.configURL)
    }

    private static func relativeTime(_ date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        if seconds < 5 { return "just now" }
        if seconds < 60 { return "\(seconds)s ago" }
        return "\(seconds / 60)m ago"
    }
}
