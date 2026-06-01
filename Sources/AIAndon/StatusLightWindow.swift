import AppKit

class StatusLightWindow: NSWindow {
    private(set) var lightView: StatusLightView!
    var isVertical: Bool = true {
        didSet {
            lightView.isVertical = isVertical
            resizeForOrientation()
        }
    }

    private let verticalSize = NSSize(width: 60, height: 160)
    private let horizontalSize = NSSize(width: 160, height: 60)

    init() {
        let screen = NSScreen.main ?? NSScreen.screens[0]
        let screenFrame = screen.visibleFrame
        let x = screenFrame.maxX - verticalSize.width - 20
        let y = screenFrame.maxY - verticalSize.height - 40

        super.init(contentRect: NSRect(x: x, y: y, width: verticalSize.width, height: verticalSize.height),
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

        lightView = StatusLightView(frame: NSRect(x: 0, y: 0, width: verticalSize.width, height: verticalSize.height))
        contentView = lightView
    }

    private func resizeForOrientation() {
        let newSize = isVertical ? verticalSize : horizontalSize
        let oldFrame = frame
        let newFrame = NSRect(x: oldFrame.origin.x, y: oldFrame.origin.y + oldFrame.height - newSize.height,
                              width: newSize.width, height: newSize.height)
        setFrame(newFrame, display: true)
        lightView.frame = NSRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
    }

    func updateState(_ state: AndonState) {
        lightView?.updateState(state)
    }
}
