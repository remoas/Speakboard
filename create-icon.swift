#!/usr/bin/env swift

import Cocoa

// Create app icon using system symbol
func createAppIcon() {
    let sizes: [(CGFloat, String)] = [
        (16, "icon_16x16"),
        (32, "icon_16x16@2x"),
        (32, "icon_32x32"),
        (64, "icon_32x32@2x"),
        (128, "icon_128x128"),
        (256, "icon_128x128@2x"),
        (256, "icon_256x256"),
        (512, "icon_256x256@2x"),
        (512, "icon_512x512"),
        (1024, "icon_512x512@2x")
    ]

    let iconsetPath = "Resources/AppIcon.iconset"

    // Create iconset directory
    try? FileManager.default.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)

    for (size, name) in sizes {
        let image = createIcon(size: size)
        let path = "\(iconsetPath)/\(name).png"

        if let tiffData = image.tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: tiffData),
           let pngData = bitmap.representation(using: .png, properties: [:]) {
            try? pngData.write(to: URL(fileURLWithPath: path))
            print("Created \(path)")
        }
    }

    print("\nIconset created. Run: iconutil -c icns Resources/AppIcon.iconset")
}

func createIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))

    image.lockFocus()

    // Background gradient
    let bounds = NSRect(x: 0, y: 0, width: size, height: size)
    let cornerRadius = size * 0.22

    let path = NSBezierPath(roundedRect: bounds, xRadius: cornerRadius, yRadius: cornerRadius)

    // Gradient from deep purple to blue
    let gradient = NSGradient(colors: [
        NSColor(red: 0.4, green: 0.2, blue: 0.8, alpha: 1.0),
        NSColor(red: 0.2, green: 0.4, blue: 0.9, alpha: 1.0)
    ])
    gradient?.draw(in: path, angle: -45)

    // Draw microphone symbol
    let symbolSize = size * 0.55
    let symbolConfig = NSImage.SymbolConfiguration(pointSize: symbolSize, weight: .medium)

    if let micImage = NSImage(systemSymbolName: "mic.fill", accessibilityDescription: nil)?
        .withSymbolConfiguration(symbolConfig) {

        let micSize = micImage.size
        let x = (size - micSize.width) / 2
        let y = (size - micSize.height) / 2

        // Draw white mic
        NSColor.white.set()
        micImage.draw(
            in: NSRect(x: x, y: y, width: micSize.width, height: micSize.height),
            from: .zero,
            operation: .sourceOver,
            fraction: 1.0
        )
    }

    // Add subtle sound waves
    let waveColor = NSColor.white.withAlphaComponent(0.4)
    waveColor.setStroke()

    let centerX = size / 2 + size * 0.15
    let centerY = size / 2

    for i in 1...3 {
        let waveRadius = size * 0.12 * CGFloat(i)
        let wavePath = NSBezierPath()
        wavePath.lineWidth = size * 0.02

        let startAngle: CGFloat = -30
        let endAngle: CGFloat = 30

        wavePath.appendArc(
            withCenter: NSPoint(x: centerX, y: centerY),
            radius: waveRadius,
            startAngle: startAngle,
            endAngle: endAngle
        )
        wavePath.stroke()
    }

    image.unlockFocus()
    return image
}

createAppIcon()
