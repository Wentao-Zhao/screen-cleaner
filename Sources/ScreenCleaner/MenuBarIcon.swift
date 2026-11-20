import AppKit

enum MenuBarIcon {
  static let image: NSImage = {
    let image = render()
    image.isTemplate = true
    return image
  }()

  static func render(color: NSColor = .black) -> NSImage {
    NSImage(size: NSSize(width: 20, height: 20), flipped: false) { _ in
      color.setStroke()
      color.setFill()

      let screen = NSBezierPath(
        roundedRect: NSRect(x: 1.7, y: 4, width: 16.6, height: 12),
        xRadius: 2,
        yRadius: 2
      )
      screen.lineWidth = 1.8
      screen.stroke()

      // A solid wiping corner remains legible without the full-size cloth's texture.
      let cloth = NSBezierPath()
      cloth.move(to: NSPoint(x: 9.6, y: 4))
      cloth.curve(
        to: NSPoint(x: 18.3, y: 11.3),
        controlPoint1: NSPoint(x: 12, y: 7.2),
        controlPoint2: NSPoint(x: 15, y: 10.2)
      )
      cloth.line(to: NSPoint(x: 18.3, y: 6))
      cloth.curve(
        to: NSPoint(x: 16.3, y: 4),
        controlPoint1: NSPoint(x: 18.3, y: 4.9),
        controlPoint2: NSPoint(x: 17.4, y: 4)
      )
      cloth.close()
      cloth.fill()

      // Clear an alpha channel between the cloth and frame for both menu-bar appearances.
      if let context = NSGraphicsContext.current?.cgContext {
        context.saveGState()
        context.setBlendMode(.clear)
        let seam = NSBezierPath()
        seam.lineWidth = 1.25
        seam.lineCapStyle = .round
        seam.move(to: NSPoint(x: 8.2, y: 3))
        seam.curve(
          to: NSPoint(x: 19, y: 12.5),
          controlPoint1: NSPoint(x: 11.7, y: 7.3),
          controlPoint2: NSPoint(x: 15.1, y: 11.1)
        )
        seam.stroke()
        context.restoreGState()
      }
      return true
    }
  }
}
