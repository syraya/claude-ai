// Builds the App Store screenshots: each raw simulator capture, scaled down, under a
// serif caption, on a background sampled from the screenshot's own theme.
// Run: swift make-frames.swift   (from this folder)
import AppKit

let width = 1320, height = 2868
let folder = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)

let shots: [(file: String, title: String, subtitle: String)] = [
    ("1-focus", "Think before you scroll", "Block the apps that pull you away, and focus on what matters."),
    ("2-session", "Focus with intention", "Your goal stays in view, even when you reach for a blocked app."),
    ("3-break", "Every break starts with a pause", "A short reflection before anything unlocks."),
    ("4-schedules", "Blocks that run themselves", "Weekdays 9 to 5, bedtime every night. Set it once."),
    ("5-lifetime", "Watch your focus grow", "Every hour since day one, with titles to earn along the way."),
    ("6-omos", "Earn mythic companions", "29 OMOs from myths around the world, each with its own theme."),
]

func serif(_ size: CGFloat, _ weight: NSFont.Weight) -> NSFont {
    let base = NSFont.systemFont(ofSize: size, weight: weight)
    guard let descriptor = base.fontDescriptor.withDesign(.serif) else { return base }
    return NSFont(descriptor: descriptor, size: size) ?? base
}

func luminance(_ color: NSColor) -> CGFloat {
    let c = color.usingColorSpace(.sRGB) ?? color
    return 0.2126 * c.redComponent + 0.7152 * c.greenComponent + 0.0722 * c.blueComponent
}

let output = folder.appendingPathComponent("App Store 6.9 inch")
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)

for shot in shots {
    guard let raw = NSImage(contentsOf: folder.appendingPathComponent("raw/\(shot.file).png")),
          let rawRep = raw.representations.first as? NSBitmapImageRep ?? NSBitmapImageRep(data: raw.tiffRepresentation!) else {
        print("missing \(shot.file)"); continue
    }
    // The theme's paper colour, just under the status bar.
    let paper = rawRep.colorAt(x: 40, y: 260) ?? .white
    let isDark = luminance(paper) < 0.4
    let ink = isDark ? NSColor(srgbRed: 0.96, green: 0.93, blue: 0.87, alpha: 1)
                     : NSColor(srgbRed: 0.14, green: 0.13, blue: 0.18, alpha: 1)

    // A colour-managed sRGB canvas, so the simulator's Display P3 captures convert properly.
    let canvas = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height,
                                  bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                                  colorSpaceName: .calibratedRGB, bytesPerRow: 0, bitsPerPixel: 0)!
        .retagging(with: .sRGB)!
    canvas.size = NSSize(width: width, height: height)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: canvas)

    // Background: the theme colour, a touch lighter at the top like OMO's own backdrop.
    let top = isDark ? paper.blended(withFraction: 0.12, of: .white)! : paper.blended(withFraction: 0.35, of: .white)!
    NSGradient(starting: top, ending: paper)!.draw(in: NSRect(x: 0, y: 0, width: width, height: height), angle: -90)

    // Caption (AppKit's y axis starts at the bottom).
    let centered = NSMutableParagraphStyle()
    centered.alignment = .center
    centered.lineBreakMode = .byWordWrapping
    let title = NSAttributedString(string: shot.title, attributes: [
        .font: serif(104, .bold), .foregroundColor: ink, .paragraphStyle: centered])
    let subtitle = NSAttributedString(string: shot.subtitle, attributes: [
        .font: NSFont.systemFont(ofSize: 50, weight: .regular),
        .foregroundColor: ink.withAlphaComponent(0.72), .paragraphStyle: centered])
    let textWidth = CGFloat(width) - 160
    let titleHeight = title.boundingRect(with: NSSize(width: textWidth, height: 1000),
                                         options: [.usesLineFragmentOrigin]).height
    let subtitleHeight = subtitle.boundingRect(with: NSSize(width: textWidth - 40, height: 1000),
                                               options: [.usesLineFragmentOrigin]).height
    let titleTop = CGFloat(height) - 150
    title.draw(with: NSRect(x: 80, y: titleTop - titleHeight, width: textWidth, height: titleHeight),
               options: [.usesLineFragmentOrigin])
    let subtitleTop = titleTop - titleHeight - 30
    subtitle.draw(with: NSRect(x: 100, y: subtitleTop - subtitleHeight, width: textWidth - 40, height: subtitleHeight),
                  options: [.usesLineFragmentOrigin])

    // The screenshot, scaled into a rounded phone-shaped card with a soft shadow.
    let scale: CGFloat = 0.76
    let shotWidth = CGFloat(width) * scale, shotHeight = CGFloat(height) * scale
    let shotTop = subtitleTop - subtitleHeight - 70
    let frame = NSRect(x: (CGFloat(width) - shotWidth) / 2, y: shotTop - shotHeight, width: shotWidth, height: shotHeight)
    let corner: CGFloat = 92
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(isDark ? 0.55 : 0.22)
    shadow.shadowBlurRadius = 60
    shadow.shadowOffset = NSSize(width: 0, height: -24)
    NSGraphicsContext.saveGraphicsState()
    shadow.set()
    paper.setFill()
    NSBezierPath(roundedRect: frame, xRadius: corner, yRadius: corner).fill()
    NSGraphicsContext.restoreGraphicsState()
    NSGraphicsContext.saveGraphicsState()
    NSBezierPath(roundedRect: frame, xRadius: corner, yRadius: corner).addClip()
    raw.draw(in: frame, from: .zero, operation: .sourceOver, fraction: 1,
             respectFlipped: true, hints: [.interpolation: NSImageInterpolation.high])
    NSGraphicsContext.restoreGraphicsState()
    (isDark ? NSColor.white.withAlphaComponent(0.14) : NSColor.black.withAlphaComponent(0.08)).setStroke()
    let border = NSBezierPath(roundedRect: frame.insetBy(dx: 1.5, dy: 1.5), xRadius: corner, yRadius: corner)
    border.lineWidth = 3
    border.stroke()

    NSGraphicsContext.restoreGraphicsState()
    let png = canvas.representation(using: .png, properties: [:])!
    try png.write(to: output.appendingPathComponent("\(shot.file).png"))
    print("made \(shot.file).png")
}
