import AppKit

guard CommandLine.arguments.count == 2 else {
  fputs("Usage: generate-app-icon <output.png>\n", stderr)
  exit(2)
}

let outputURL = URL(fileURLWithPath: CommandLine.arguments[1])
let canvasSize = NSSize(width: 1024, height: 1024)
let image = NSImage(size: canvasSize)

image.lockFocus()
guard let context = NSGraphicsContext.current?.cgContext else {
  fputs("Unable to create graphics context\n", stderr)
  exit(1)
}

context.clear(CGRect(origin: .zero, size: canvasSize))
NSGraphicsContext.current?.imageInterpolation = .high

let tileRect = NSRect(x: 64, y: 64, width: 896, height: 896)
let tilePath = NSBezierPath(
  roundedRect: tileRect,
  xRadius: 205,
  yRadius: 205
)

NSGraphicsContext.saveGraphicsState()
let shadow = NSShadow()
shadow.shadowColor = NSColor.black.withAlphaComponent(0.22)
shadow.shadowBlurRadius = 58
shadow.shadowOffset = NSSize(width: 0, height: -24)
shadow.set()

let backgroundGradient = NSGradient(colors: [
  NSColor(calibratedRed: 0.96, green: 0.98, blue: 1.0, alpha: 1),
  NSColor(calibratedRed: 0.75, green: 0.86, blue: 0.96, alpha: 1),
])!
backgroundGradient.draw(in: tilePath, angle: 90)
NSGraphicsContext.restoreGraphicsState()

let monitorColor = NSColor(calibratedRed: 0.08, green: 0.11, blue: 0.16, alpha: 1)
let screenPath = NSBezierPath(
  roundedRect: NSRect(x: 190, y: 314, width: 644, height: 430),
  xRadius: 58,
  yRadius: 58
)
screenPath.lineWidth = 42
monitorColor.setStroke()
screenPath.stroke()

let screenHighlight = NSBezierPath(
  roundedRect: NSRect(x: 225, y: 349, width: 574, height: 360),
  xRadius: 34,
  yRadius: 34
)
NSColor.white.withAlphaComponent(0.32).setFill()
screenHighlight.fill()

let stand = NSBezierPath()
stand.lineWidth = 42
stand.lineCapStyle = .round
stand.move(to: NSPoint(x: 512, y: 314))
stand.line(to: NSPoint(x: 512, y: 210))
stand.move(to: NSPoint(x: 392, y: 210))
stand.line(to: NSPoint(x: 632, y: 210))
monitorColor.setStroke()
stand.stroke()

context.saveGState()
context.translateBy(x: 526, y: 524)
context.rotate(by: -.pi * 42 / 180)
context.scaleBy(x: 0.8, y: 0.8)

let handle = NSBezierPath(
  roundedRect: NSRect(x: -30, y: -18, width: 60, height: 320),
  xRadius: 30,
  yRadius: 30
)
monitorColor.setFill()
handle.fill()

let connector = NSBezierPath(
  roundedRect: NSRect(x: -128, y: -92, width: 256, height: 70),
  xRadius: 12,
  yRadius: 12
)
connector.fill()

let bristles = NSBezierPath()
bristles.move(to: NSPoint(x: -112, y: -104))
bristles.line(to: NSPoint(x: 112, y: -104))
bristles.line(to: NSPoint(x: 96, y: -284))
bristles.line(to: NSPoint(x: 34, y: -260))
bristles.line(to: NSPoint(x: 40, y: -182))
bristles.line(to: NSPoint(x: 8, y: -254))
bristles.line(to: NSPoint(x: -50, y: -224))
bristles.line(to: NSPoint(x: -36, y: -158))
bristles.line(to: NSPoint(x: -78, y: -212))
bristles.line(to: NSPoint(x: -130, y: -178))
bristles.close()
bristles.fill()

context.restoreGState()

image.unlockFocus()

guard
  let tiffData = image.tiffRepresentation,
  let bitmap = NSBitmapImageRep(data: tiffData),
  let pngData = bitmap.representation(using: .png, properties: [:])
else {
  fputs("Unable to encode icon PNG\n", stderr)
  exit(1)
}

try pngData.write(to: outputURL)
