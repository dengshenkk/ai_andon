import AppKit

class StatusLightWindow: NSWindow {
    private(set) var lightView: StatusLightView!

    init() {
        let width: CGFloat = 60
        let height: CGFloat = 160

        let screen = NSScreen.main ?? NSScreen.screens[0]
        let screenFrame = screen.visibleFrame
        let x = screenFrame.maxX - width - 20
        let y = screenFrame.maxY - height - 40

        super.init(contentRect: NSRect(x: x, y: y, width: width, height: height),
                   styleMask: [.borderless],
                   backing: .buffered,
                   defer: false)

        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        level = .floating
        isMovableByWindowBackground = true
        isReleasedWhenClosed = false
        collectionBehavior = [.canJoinAllSpaces, .stationary]
        hidesOnDeactivate = false

        lightView = StatusLightView(frame: NSRect(x: 0, y: 0, width: width, height: height))
        contentView = lightView
    }

    func updateState(_ state: AndonState) {
        lightView?.updateState(state)
    }
}
