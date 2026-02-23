#!/usr/bin/env swift

import Cocoa

// Create DMG background with arrow
func createDMGBackground() {
    let width: CGFloat = 660
    let height: CGFloat = 400

    let image = NSImage(size: NSSize(width: width, height: height))

    image.lockFocus()

    // Background gradient (dark)
    let bounds = NSRect(x: 0, y: 0, width: width, height: height)
    let gradient = NSGradient(colors: [
        NSColor(red: 0.08, green: 0.08, blue: 0.1, alpha: 1.0),
        NSColor(red: 0.12, green: 0.12, blue: 0.15, alpha: 1.0)
    ])
    gradient?.draw(in: bounds, angle: -90)

    // Draw arrow from app (right side) to Applications (left side)
    let arrowPath = NSBezierPath()
    let arrowY: CGFloat = height / 2 + 20
    let arrowStartX: CGFloat = 420  // Start near app icon
    let arrowEndX: CGFloat = 240    // End near Applications

    // Arrow line
    arrowPath.move(to: NSPoint(x: arrowStartX, y: arrowY))
    arrowPath.line(to: NSPoint(x: arrowEndX + 20, y: arrowY))

    arrowPath.lineWidth = 4
    arrowPath.lineCapStyle = .round
    NSColor(red: 0.5, green: 0.5, blue: 0.6, alpha: 0.8).setStroke()
    arrowPath.stroke()

    // Arrow head
    let arrowHead = NSBezierPath()
    arrowHead.move(to: NSPoint(x: arrowEndX + 20, y: arrowY))
    arrowHead.line(to: NSPoint(x: arrowEndX + 40, y: arrowY + 15))
    arrowHead.line(to: NSPoint(x: arrowEndX + 40, y: arrowY - 15))
    arrowHead.close()

    NSColor(red: 0.5, green: 0.5, blue: 0.6, alpha: 0.8).setFill()
    arrowHead.fill()

    // "Drag to install" text
    let textAttrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 13, weight: .medium),
        .foregroundColor: NSColor(white: 0.6, alpha: 1.0)
    ]
    let text = "Drag to Applications to install"
    let textSize = text.size(withAttributes: textAttrs)
    text.draw(at: NSPoint(x: (width - textSize.width) / 2, y: 70), withAttributes: textAttrs)

    image.unlockFocus()

    // Save as PNG
    if let tiffData = image.tiffRepresentation,
       let bitmap = NSBitmapImageRep(data: tiffData),
       let pngData = bitmap.representation(using: .png, properties: [:]) {
        let path = "Resources/dmg-background.png"
        try? pngData.write(to: URL(fileURLWithPath: path))
        print("Created \(path)")
    }
}

createDMGBackground()
