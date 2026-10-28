// 앱 아이콘 그리기: swift make-icon.swift <출력.png>  (1024×1024)
// 어두운 macOS 스타일 둥근 사각형 위에 3×4 키 + 노브 2개 (레이어 색 3가지)
import AppKit

let size: CGFloat = 1024
let img = NSImage(size: NSSize(width: size, height: size))
img.lockFocus()
let ctx = NSGraphicsContext.current!.cgContext

func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: r, green: g, blue: b, alpha: a)
}
let blue = rgb(0.42, 0.56, 1.00), orange = rgb(1.00, 0.62, 0.30), green = rgb(0.32, 0.86, 0.62)

// 바탕: macOS 아이콘 격자(824pt, 여백 100)
let base = NSRect(x: 100, y: 100, width: 824, height: 824)
let basePath = NSBezierPath(roundedRect: base, xRadius: 185, yRadius: 185)
ctx.saveGState()
let shadow = NSShadow()
shadow.shadowColor = NSColor.black.withAlphaComponent(0.45)
shadow.shadowBlurRadius = 28
shadow.shadowOffset = NSSize(width: 0, height: -12)
shadow.set()
rgb(0.10, 0.105, 0.12).setFill()
basePath.fill()
ctx.restoreGState()
NSGradient(starting: rgb(0.20, 0.205, 0.235), ending: rgb(0.075, 0.08, 0.095))!.draw(in: basePath, angle: -90)
// 레이어 색 은은한 빛
NSGraphicsContext.saveGraphicsState()
basePath.addClip()
NSGradient(colors: [blue.withAlphaComponent(0.28), .clear])!
    .draw(fromCenter: NSPoint(x: 380, y: 560), radius: 0, toCenter: NSPoint(x: 380, y: 560), radius: 520, options: [])
NSGraphicsContext.restoreGraphicsState()
NSColor.white.withAlphaComponent(0.10).setStroke()
basePath.lineWidth = 4
basePath.stroke()

// 키 3줄 × 4칸
let key: CGFloat = 112, gap: CGFloat = 22
let gridX: CGFloat = 166, gridTop: CGFloat = 702
let rowColors = [blue, orange, green]
for r in 0..<3 {
    for c in 0..<4 {
        let x = gridX + CGFloat(c) * (key + gap)
        let y = gridTop - CGFloat(r + 1) * key - CGFloat(r) * gap
        let rect = NSRect(x: x, y: y, width: key, height: key)
        let p = NSBezierPath(roundedRect: rect, xRadius: 26, yRadius: 26)
        let lit = (r == 0 && c == 1) || (r == 1 && c == 3) || (r == 2 && c == 0)
        if lit {
            ctx.saveGState()
            let glow = NSShadow()
            glow.shadowColor = rowColors[r].withAlphaComponent(0.8)
            glow.shadowBlurRadius = 30
            glow.set()
            rowColors[r].setFill()
            p.fill()
            ctx.restoreGState()
            NSGradient(starting: rowColors[r].highlight(withLevel: 0.25)!, ending: rowColors[r])!.draw(in: p, angle: -90)
        } else {
            NSGradient(starting: rgb(0.27, 0.275, 0.30), ending: rgb(0.17, 0.175, 0.195))!.draw(in: p, angle: -90)
            NSColor.white.withAlphaComponent(0.09).setStroke()
            p.lineWidth = 2
            p.stroke()
        }
    }
}

// 노브 2개 (오른쪽)
for (i, cy) in [CGFloat(612), 412].enumerated() {
    let cx: CGFloat = 784, rad: CGFloat = 62
    let well = NSBezierPath(ovalIn: NSRect(x: cx - rad - 12, y: cy - rad - 12, width: (rad + 12) * 2, height: (rad + 12) * 2))
    NSColor.black.withAlphaComponent(0.4).setFill()
    well.fill()
    let k = NSBezierPath(ovalIn: NSRect(x: cx - rad, y: cy - rad, width: rad * 2, height: rad * 2))
    NSGradient(starting: rgb(0.34, 0.345, 0.37), ending: rgb(0.14, 0.145, 0.16))!.draw(in: k, angle: -60)
    NSColor.white.withAlphaComponent(0.12).setStroke()
    k.lineWidth = 3
    k.stroke()
    let mark = NSBezierPath(roundedRect: NSRect(x: cx - 6, y: cy + 18, width: 12, height: 36), xRadius: 6, yRadius: 6)
    (i == 0 ? blue : green).setFill()
    mark.fill()
}

img.unlockFocus()
let rep = NSBitmapImageRep(data: img.tiffRepresentation!)!
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
print("ICON_OK")
