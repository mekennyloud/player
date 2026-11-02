// Рисует иконки плеера (iOS сама скругляет углы, поэтому фон — на весь квадрат).
// Цвета — те же, что в самом плеере: чернила #111, бумага #f1eee8, красный #ff3b24.
// Запуск: swift tools/make_icons.swift icons [glow|paper|wave]   (по умолчанию glow)
//         swift tools/make_icons.swift preview.png preview        — все варианты рядом, для выбора
import AppKit
import CoreImage

let args = CommandLine.arguments
let out = args[1]
let style = args.count > 2 ? args[2] : "glow"

let ink = NSColor(red: 0.067, green: 0.067, blue: 0.067, alpha: 1)
let paper = NSColor(red: 0.945, green: 0.933, blue: 0.910, alpha: 1)
let red = NSColor(red: 1.0, green: 0.231, blue: 0.141, alpha: 1)

/// треугольник «играть» со скруглёнными углами; центр масс — в (cx, cy)
func playPath(cx: CGFloat, cy: CGFloat, s: CGFloat) -> NSBezierPath {
    let p = NSBezierPath()
    p.move(to: NSPoint(x: cx - s * 0.36, y: cy + s * 0.5))
    p.line(to: NSPoint(x: cx + s * 0.5, y: cy))
    p.line(to: NSPoint(x: cx - s * 0.36, y: cy - s * 0.5))
    p.close()
    p.lineJoinStyle = .round
    p.lineWidth = s * 0.16
    return p
}

func circle(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat) -> NSBezierPath {
    NSBezierPath(ovalIn: NSRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2))
}

/// «Волна»: чёрный фон и волна из столбиков, как в самом плеере; сыгранная часть — красная
func drawWave(_ S: CGFloat) {
    ink.setFill(); NSRect(x: 0, y: 0, width: S, height: S).fill()
    let heights: [CGFloat] = [0.20, 0.38, 0.62, 0.46, 0.80, 0.56, 0.34, 0.50, 0.26]
    let w = S * 0.058, step = S * 0.083
    let x0 = S * 0.5 - step * CGFloat(heights.count - 1) / 2
    for (i, h) in heights.enumerated() {
        let bh = S * 0.62 * h
        let r = NSRect(x: x0 + step * CGFloat(i) - w / 2, y: S * 0.5 - bh / 2, width: w, height: bh)
        (i < 5 ? red : paper).setFill()
        NSBezierPath(roundedRect: r, xRadius: w / 2, yRadius: w / 2).fill()
    }
}

/// «Бумага»: кремовый фон, жирный чёрный «играть» и красная точка «идёт запись/играет»
func drawPaper(_ S: CGFloat) {
    paper.setFill(); NSRect(x: 0, y: 0, width: S, height: S).fill()
    let tri = playPath(cx: S * 0.47, cy: S * 0.47, s: S * 0.42)
    ink.setFill(); ink.setStroke(); tri.fill(); tri.stroke()
    red.setFill(); circle(S * 0.74, S * 0.74, S * 0.085).fill()
}

/// «Свечение»: чёрный фон с мягкими красно-розово-оранжевыми пятнами и белый «играть»
func drawGlow(_ S: CGFloat, into rep: NSBitmapImageRep) {
    ink.setFill(); NSRect(x: 0, y: 0, width: S, height: S).fill()
    // пятна рисуем отдельно и размываем
    let blobs = NSImage(size: NSSize(width: S, height: S))
    blobs.lockFocus()
    red.setFill(); circle(S * 0.34, S * 0.30, S * 0.34).fill()
    NSColor(red: 1.0, green: 0.30, blue: 0.62, alpha: 1).setFill(); circle(S * 0.74, S * 0.66, S * 0.30).fill()
    NSColor(red: 1.0, green: 0.62, blue: 0.20, alpha: 1).setFill(); circle(S * 0.72, S * 0.22, S * 0.20).fill()
    blobs.unlockFocus()
    let ci = CIImage(data: blobs.tiffRepresentation!)!
    let blurred = ci.clampedToExtent().applyingGaussianBlur(sigma: Double(S) * 0.11).cropped(to: ci.extent)
    let cg = CIContext().createCGImage(blurred, from: ci.extent)!
    NSImage(cgImage: cg, size: NSSize(width: S, height: S)).draw(in: NSRect(x: 0, y: 0, width: S, height: S),
        from: .zero, operation: .sourceOver, fraction: 0.95)
    let tri = playPath(cx: S * 0.515, cy: S * 0.5, s: S * 0.34)
    NSColor.white.setFill(); NSColor.white.setStroke(); tri.fill(); tri.stroke()
}

func render(_ px: Int, _ style: String) -> NSBitmapImageRep {
    let S = CGFloat(px)
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px,
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    switch style {
    case "paper": drawPaper(S)
    case "wave": drawWave(S)
    default: drawGlow(S, into: rep)
    }
    NSGraphicsContext.current = nil
    return rep
}

func save(_ rep: NSBitmapImageRep, _ path: String) {
    try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: path))
}

if style == "preview" {
    // три варианта рядом, со скруглением как на экране iPhone
    let n = 360, gap = 40, styles = ["glow", "paper", "wave"]
    let W = n * 3 + gap * 4, H = n + gap * 2
    let sheet = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: W, pixelsHigh: H, bitsPerSample: 8, samplesPerPixel: 4,
                                 hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    // сначала рисуем сами иконки (render меняет текущий холст), потом раскладываем их на листе
    let imgs = styles.map { s -> NSImage in let img = NSImage(size: NSSize(width: n, height: n)); img.addRepresentation(render(n, s)); return img }
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: sheet)
    NSColor(white: 0.85, alpha: 1).setFill(); NSRect(x: 0, y: 0, width: W, height: H).fill()
    for (i, img) in imgs.enumerated() {
        let rect = NSRect(x: gap + i * (n + gap), y: gap, width: n, height: n)
        NSGraphicsContext.saveGraphicsState()
        NSBezierPath(roundedRect: rect, xRadius: CGFloat(n) * 0.225, yRadius: CGFloat(n) * 0.225).addClip()
        img.draw(in: rect)
        NSGraphicsContext.restoreGraphicsState()
    }
    NSGraphicsContext.current = nil
    save(sheet, out)
} else {
    save(render(180, style), "\(out)/apple-touch-icon.png")
    save(render(192, style), "\(out)/icon-192.png")
    save(render(512, style), "\(out)/icon-512.png")
}
