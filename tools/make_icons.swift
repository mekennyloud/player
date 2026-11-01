// Рисует иконки плеера: зелёно-бирюзовый фон на весь квадрат (iOS сама скругляет углы) и белый треугольник «играть».
// Запуск: swift tools/make_icons.swift icons
import AppKit

let dir = CommandLine.arguments[1]

func icon(_ px: Int, _ name: String) {
    let size = CGFloat(px)
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px,
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    NSGradient(starting: NSColor(red: 0.20, green: 0.80, blue: 0.56, alpha: 1),
               ending: NSColor(red: 0.10, green: 0.50, blue: 0.62, alpha: 1))!
        .draw(in: NSRect(x: 0, y: 0, width: size, height: size), angle: -45)

    // треугольник «играть», чуть сдвинут вправо для оптического центра
    let s = size * 0.36
    let cx = size * 0.535, cy = size * 0.5
    let tri = NSBezierPath()
    tri.move(to: NSPoint(x: cx - s * 0.42, y: cy + s * 0.5))
    tri.line(to: NSPoint(x: cx + s * 0.5, y: cy))
    tri.line(to: NSPoint(x: cx - s * 0.42, y: cy - s * 0.5))
    tri.close()
    tri.lineJoinStyle = .round
    tri.lineWidth = size * 0.06
    NSColor.white.setFill(); NSColor.white.setStroke()
    tri.fill(); tri.stroke()

    NSGraphicsContext.current = nil
    try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "\(dir)/\(name)"))
}

icon(180, "apple-touch-icon.png")
icon(192, "icon-192.png")
icon(512, "icon-512.png")
