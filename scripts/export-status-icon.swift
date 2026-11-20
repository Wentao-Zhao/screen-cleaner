import AppKit

@main
enum ExportStatusIcon {
  @MainActor
  static func main() throws {
    let directory = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
    let iconset = URL(fileURLWithPath: CommandLine.arguments[2], isDirectory: true)
    try writeAppIcon(iconset: iconset, output: directory.appendingPathComponent("AppIcon.icns"))
    for scale in [1, 2] {
      try bitmap(width: 20 * scale, height: 20 * scale) { context in
        context.cgContext.scaleBy(x: CGFloat(scale), y: CGFloat(scale))
        MenuBarIcon.render().draw(in: NSRect(x: 0, y: 0, width: 20, height: 20))
      }.write(to: directory.appendingPathComponent("StatusIcon-\(20 * scale).png"))
    }

    try bitmap(width: 720, height: 240) { _ in
      for (index, color) in [NSColor.black, .white].enumerated() {
        let origin = CGFloat(index * 360)
        (index == 0 ? NSColor(white: 0.96, alpha: 1) : NSColor(white: 0.12, alpha: 1)).setFill()
        NSRect(x: origin, y: 0, width: 360, height: 240).fill()
        let icon = MenuBarIcon.render(color: color)
        icon.draw(in: NSRect(x: origin + 44, y: 110, width: 20, height: 20))
        icon.draw(in: NSRect(x: origin + 104, y: 100, width: 40, height: 40))
        icon.draw(in: NSRect(x: origin + 200, y: 72, width: 96, height: 96))
      }
    }.write(to: directory.appendingPathComponent("StatusIconPreview.png"))
  }

  private static func writeAppIcon(iconset: URL, output: URL) throws {
    let variants = [
      ("icp4", "icon_16x16.png"), ("icp5", "icon_32x32.png"),
      ("icp6", "icon_32x32@2x.png"), ("ic07", "icon_128x128.png"),
      ("ic08", "icon_256x256.png"), ("ic09", "icon_512x512.png"),
      ("ic10", "icon_512x512@2x.png"), ("ic11", "icon_16x16@2x.png"),
      ("ic12", "icon_32x32@2x.png"), ("ic13", "icon_128x128@2x.png"),
      ("ic14", "icon_256x256@2x.png"),
    ]
    var body = Data()
    for (type, filename) in variants {
      let png = try Data(contentsOf: iconset.appendingPathComponent(filename))
      body.append(contentsOf: type.utf8)
      appendLength(UInt32(png.count + 8), to: &body)
      body.append(png)
    }
    var file = Data("icns".utf8)
    appendLength(UInt32(body.count + 8), to: &file)
    file.append(body)
    try file.write(to: output, options: .atomic)
  }

  private static func appendLength(_ value: UInt32, to data: inout Data) {
    var length = value.bigEndian
    withUnsafeBytes(of: &length) { data.append(contentsOf: $0) }
  }

  @MainActor
  private static func bitmap(
    width: Int, height: Int, draw: (NSGraphicsContext) -> Void
  ) throws -> Data {
    guard let bitmap = NSBitmapImageRep(
      bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height,
      bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
      isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    ), let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
      throw CocoaError(.fileWriteUnknown)
    }
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    draw(context)
    NSGraphicsContext.restoreGraphicsState()
    guard let png = bitmap.representation(using: .png, properties: [:]) else {
      throw CocoaError(.fileWriteUnknown)
    }
    return png
  }
}
