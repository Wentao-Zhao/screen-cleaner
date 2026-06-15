import AppKit

enum MenuBarIcon {
    static let image: NSImage = {
        let size = NSSize(width: 20, height: 20)
        let image = NSImage(size: size, flipped: false) { _ in
            NSColor.black.setStroke()
            NSColor.black.setFill()

            drawMonitor()
            drawBroom()
            return true
        }
        image.isTemplate = true
        return image
    }()

    private static func drawMonitor() {
        let monitor = NSBezierPath(
            roundedRect: NSRect(x: 1.4, y: 5.1, width: 17.2, height: 11.8),
            xRadius: 1.7,
            yRadius: 1.7
        )
        monitor.lineWidth = 1.45
        monitor.stroke()

        let stand = NSBezierPath()
        stand.lineWidth = 1.45
        stand.lineCapStyle = .round
        stand.move(to: NSPoint(x: 10, y: 5.1))
        stand.line(to: NSPoint(x: 10, y: 2.2))
        stand.move(to: NSPoint(x: 6.8, y: 2.2))
        stand.line(to: NSPoint(x: 13.2, y: 2.2))
        stand.stroke()
    }

    private static func drawBroom() {
        guard let context = NSGraphicsContext.current?.cgContext else {
            return
        }

        context.saveGState()
        context.translateBy(x: 10.2, y: 11.2)
        context.rotate(by: -.pi * 42 / 180)
        context.scaleBy(x: 0.8, y: 0.8)

        let handle = NSBezierPath(
            roundedRect: NSRect(x: -0.75, y: -0.6, width: 1.5, height: 7.2),
            xRadius: 0.75,
            yRadius: 0.75
        )
        handle.fill()

        let connector = NSBezierPath(
            roundedRect: NSRect(x: -2.8, y: -1.8, width: 5.6, height: 1.45),
            xRadius: 0.25,
            yRadius: 0.25
        )
        connector.fill()

        let bristles = NSBezierPath()
        bristles.move(to: NSPoint(x: -2.5, y: -2.05))
        bristles.line(to: NSPoint(x: 2.5, y: -2.05))
        bristles.line(to: NSPoint(x: 2.15, y: -5.5))
        bristles.line(to: NSPoint(x: 0.8, y: -5.1))
        bristles.line(to: NSPoint(x: 0.9, y: -3.5))
        bristles.line(to: NSPoint(x: 0.2, y: -5.0))
        bristles.line(to: NSPoint(x: -1.1, y: -4.55))
        bristles.line(to: NSPoint(x: -0.8, y: -3.15))
        bristles.line(to: NSPoint(x: -1.75, y: -4.35))
        bristles.line(to: NSPoint(x: -2.9, y: -3.75))
        bristles.close()
        bristles.fill()

        context.restoreGState()
    }
}

