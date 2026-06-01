import AppKit

class StatusLightView: NSView {
    private var currentState: AndonState = .noSession
    private var blinkPhase: Bool = true
    private var blinkTimer: Timer?
    var isVertical: Bool = true {
        didSet { needsDisplay = true }
    }

    private let greenColor = NSColor(red: 0.2, green: 0.85, blue: 0.3, alpha: 1.0)
    private let yellowColor = NSColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1.0)
    private let redColor = NSColor(red: 0.95, green: 0.2, blue: 0.15, alpha: 1.0)
    private let offColor = NSColor(red: 0.35, green: 0.35, blue: 0.35, alpha: 1.0)

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

    func updateState(_ state: AndonState) {
        if currentState != state {
            currentState = state
            needsDisplay = true
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        guard let ctx = NSGraphicsContext.current?.cgContext else { return }

        let w = bounds.width
        let h = bounds.height
        let circleSize: CGFloat = 28

        let greenCenter: CGPoint
        let yellowCenter: CGPoint
        let redCenter: CGPoint

        if isVertical {
            let spacing: CGFloat = h / 3.0
            let centerY = h - spacing / 2.0
            greenCenter = CGPoint(x: w / 2, y: centerY)
            yellowCenter = CGPoint(x: w / 2, y: centerY - spacing)
            redCenter = CGPoint(x: w / 2, y: centerY - spacing * 2)
        } else {
            let spacing: CGFloat = w / 3.0
            let centerX = spacing / 2.0
            greenCenter = CGPoint(x: centerX, y: h / 2)
            yellowCenter = CGPoint(x: centerX + spacing, y: h / 2)
            redCenter = CGPoint(x: centerX + spacing * 2, y: h / 2)
        }

        func drawLight(center: CGPoint, activeColor: NSColor, isActive: Bool) {
            let color = isActive ? activeColor : offColor
            let rect = CGRect(x: center.x - circleSize / 2, y: center.y - circleSize / 2,
                              width: circleSize, height: circleSize)

            if isActive {
                let glowRect = rect.insetBy(dx: -3, dy: -3)
                ctx.setFillColor(color.withAlphaComponent(0.3).cgColor)
                ctx.fillEllipse(in: glowRect)
            }

            ctx.setFillColor(color.cgColor)
            ctx.fillEllipse(in: rect)
        }

        switch currentState {
        case .busy:
            drawLight(center: greenCenter, activeColor: greenColor, isActive: true)
            drawLight(center: yellowCenter, activeColor: yellowColor, isActive: false)
            drawLight(center: redCenter, activeColor: redColor, isActive: false)

        case .idle:
            drawLight(center: greenCenter, activeColor: greenColor, isActive: false)
            drawLight(center: yellowCenter, activeColor: yellowColor, isActive: blinkPhase)
            drawLight(center: redCenter, activeColor: redColor, isActive: false)

        case .inactive:
            drawLight(center: greenCenter, activeColor: greenColor, isActive: false)
            drawLight(center: yellowCenter, activeColor: yellowColor, isActive: false)
            drawLight(center: redCenter, activeColor: redColor, isActive: blinkPhase)

        case .noSession:
            drawLight(center: greenCenter, activeColor: greenColor, isActive: false)
            drawLight(center: yellowCenter, activeColor: yellowColor, isActive: false)
            drawLight(center: redCenter, activeColor: redColor, isActive: false)
        }
    }

    deinit {
        blinkTimer?.invalidate()
    }
}
