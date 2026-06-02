import AppKit

class StatusLightWindow: NSWindow {
    private(set) var lightView: StatusLightView!
    private var currentSessions: [SessionInfo] = []
    var isVertical: Bool = true {
        didSet {
            lightView.isVertical = isVertical
            resizeForOrientation()
        }
    }

    private let fixedWidth: CGFloat = 60
    private let fixedHeight: CGFloat = 60
    private let circleSize: CGFloat = 28
    private let spacing: CGFloat = 6
    private let padding: CGFloat = 8

    init() {
        let initialHeight: CGFloat = 28 + 8 * 2  // 1 circle + padding
        let screen = NSScreen.main ?? NSScreen.screens[0]
        let screenFrame = screen.visibleFrame
        let x = screenFrame.maxX - 60 - 20
        let y = screenFrame.maxY - initialHeight - 40

        super.init(contentRect: NSRect(x: x, y: y, width: 60, height: initialHeight),
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

        lightView = StatusLightView(frame: NSRect(x: 0, y: 0, width: 60, height: initialHeight))
        contentView = lightView
    }

    private func sizeForSessionCount(_ count: Int, isVertical: Bool) -> NSSize {
        let effectiveCount = max(count, 1)
        let contentLength = CGFloat(effectiveCount) * circleSize + CGFloat(max(effectiveCount - 1, 0)) * spacing + padding * 2
        let minDimension: CGFloat = max(44, contentLength)

        if isVertical {
            return NSSize(width: fixedWidth, height: minDimension)
        } else {
            return NSSize(width: minDimension, height: fixedHeight)
        }
    }

    private func resizeForOrientation() {
        let newSize = sizeForSessionCount(currentSessions.count, isVertical: isVertical)
        let oldFrame = frame
        let newFrame = NSRect(x: oldFrame.origin.x, y: oldFrame.origin.y + oldFrame.height - newSize.height,
                              width: newSize.width, height: newSize.height)
        setFrame(newFrame, display: true)
        lightView.frame = NSRect(origin: .zero, size: newSize)
    }

    func updateSessions(_ sessions: [SessionInfo]) {
        let newSize = sizeForSessionCount(sessions.count, isVertical: isVertical)
        let currentSize = frame.size

        if newSize.width != currentSize.width || newSize.height != currentSize.height {
            let oldFrame = frame
            let newFrame = NSRect(x: oldFrame.origin.x, y: oldFrame.origin.y + oldFrame.height - newSize.height,
                                  width: newSize.width, height: newSize.height)
            setFrame(newFrame, display: true)
            lightView.frame = NSRect(origin: .zero, size: newSize)
        }

        currentSessions = sessions
        lightView.updateSessions(sessions)
    }
}
