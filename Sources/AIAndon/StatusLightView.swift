import AppKit

class StatusLightView: NSView {
    private var sessions: [SessionInfo] = []
    private var blinkPhase: Bool = true
    private var blinkTimer: Timer?
    var isVertical: Bool = true {
        didSet { needsDisplay = true }
    }

    private let greenColor = NSColor(red: 0.2, green: 0.85, blue: 0.3, alpha: 1.0)
    private let yellowColor = NSColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1.0)
    private let redColor = NSColor(red: 0.95, green: 0.2, blue: 0.15, alpha: 1.0)
    private let offColor = NSColor(red: 0.35, green: 0.35, blue: 0.35, alpha: 1.0)

    private let circleSize: CGFloat = 28
    private let spacing: CGFloat = 6
    private let padding: CGFloat = 8

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        layer?.cornerRadius = 12
        layer?.backgroundColor = NSColor(white: 0.12, alpha: 0.92).cgColor
        startBlinkTimer()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    private func startBlinkTimer() {
        blinkTimer = Timer(timeInterval: 0.5, target: self, selector: #selector(toggleBlink), userInfo: nil, repeats: true)
        RunLoop.main.add(blinkTimer!, forMode: .common)
    }

    @objc private func toggleBlink() {
        blinkPhase.toggle()
        needsDisplay = true
    }

    func updateSessions(_ sessions: [SessionInfo]) {
        let changed = sessions.count != self.sessions.count ||
            !zip(sessions, self.sessions).allSatisfy { $0.status == $1.status && $0.id == $1.id }
        if changed {
            self.sessions = sessions
            needsDisplay = true
        }
    }

    private func lightCenters() -> [CGPoint] {
        let w = bounds.width
        let h = bounds.height
        let count = sessions.count
        guard count > 0 else { return [] }

        let availableLength = isVertical ? h : w
        let totalContentLength = CGFloat(count) * circleSize + CGFloat(max(count - 1, 0)) * spacing
        let startOffset = (availableLength - totalContentLength) / 2.0 + circleSize / 2.0

        return sessions.indices.map { i in
            let offset = startOffset + CGFloat(i) * (circleSize + spacing)
            if isVertical {
                return CGPoint(x: w / 2, y: h - offset)
            } else {
                return CGPoint(x: offset, y: h / 2)
            }
        }
    }

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        let centers = lightCenters()
        let hitRadius = circleSize / 2.0 + 4

        for (i, center) in centers.enumerated() {
            let dx = point.x - center.x
            let dy = point.y - center.y
            if dx * dx + dy * dy <= hitRadius * hitRadius {
                focusTerminal(pid: Int32(sessions[i].pid))
                return
            }
        }

        super.mouseDown(with: event)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        guard let ctx = NSGraphicsContext.current?.cgContext else { return }

        let centers = lightCenters()
        guard !centers.isEmpty else { return }

        for (i, session) in sessions.enumerated() {
            let center = centers[i]

            let activeColor: NSColor
            let isActive: Bool

            switch session.status {
            case .busy:
                activeColor = greenColor
                isActive = true
            case .idle:
                activeColor = yellowColor
                isActive = blinkPhase
            case .inactive, .noSession:
                activeColor = redColor
                isActive = blinkPhase
            }

            let rect = CGRect(x: center.x - circleSize / 2, y: center.y - circleSize / 2,
                              width: circleSize, height: circleSize)

            if isActive {
                let glowRect = rect.insetBy(dx: -3, dy: -3)
                ctx.setFillColor(activeColor.withAlphaComponent(0.3).cgColor)
                ctx.fillEllipse(in: glowRect)
            }

            let color = isActive ? activeColor : offColor
            ctx.setFillColor(color.cgColor)
            ctx.fillEllipse(in: rect)
        }
    }

    private func focusTerminal(pid: Int32) {
        var currentPid = pid
        for _ in 0..<8 {
            guard let app = NSRunningApplication(processIdentifier: currentPid) else {
                currentPid = parentPid(of: currentPid)
                guard currentPid > 0 else { return }
                continue
            }

            let bundleId = app.bundleIdentifier ?? ""
            let execName = (app.executableURL?.lastPathComponent ?? "").lowercased()

            let knownTerminals = [
                "iterm2", "iterm", "com.googlecode.iterm2",
                "com.apple.terminal",
                "net.kovidgoyal.kitty",
                "org.alacritty",
                "com.mitchellh.ghostty",
                "dev.warp.Warp-Stable", "dev.warp.Warp",
                "com.github.wez.wezterm",
                "co.zeit.hyper"
            ]

            let isTerminal = knownTerminals.contains(bundleId) ||
                knownTerminals.contains(execName) ||
                execName.contains("terminal") ||
                execName.contains("iterm") ||
                execName.contains("kitty") ||
                execName.contains("alacritty") ||
                execName.contains("ghostty") ||
                execName.contains("warp") ||
                execName.contains("wezterm") ||
                execName.contains("hyper")

            if isTerminal {
                app.activate()
                unminimizeWindows(bundleId: bundleId, appName: app.localizedName ?? "")
                return
            }

            currentPid = parentPid(of: currentPid)
            guard currentPid > 0 else { return }
        }
    }

    private func unminimizeWindows(bundleId: String, appName: String) {
        guard !bundleId.isEmpty else { return }

        let script = """
        tell application id "\(bundleId)"
            activate
            try
                set miniaturized of every window to false
            end try
        end tell
        """

        DispatchQueue.global(qos: .userInitiated).async {
            if let appleScript = NSAppleScript(source: script) {
                var error: NSDictionary?
                appleScript.executeAndReturnError(&error)
            }
        }
    }

    private func parentPid(of pid: Int32) -> Int32 {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/ps")
        task.arguments = ["-o", "ppid=", "-p", String(pid)]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = FileHandle.nullDevice
        do {
            try task.run()
            task.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let ppid = Int32(String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "0") ?? 0
            return ppid
        } catch {
            return 0
        }
    }

    deinit {
        blinkTimer?.invalidate()
    }
}
