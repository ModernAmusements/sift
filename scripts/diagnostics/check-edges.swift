import AppKit

let path = CommandLine.arguments.dropFirst().first ?? "build/home-new.png"
guard let image = NSImage(contentsOfFile: path),
      let tiff = image.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff) else {
    print("cannot read", path)
    exit(1)
}

let w = rep.pixelsWide
let h = rep.pixelsHigh
func rgb(_ x: Int, _ y: Int) -> (Int, Int, Int) {
    guard let c = rep.colorAt(x: x, y: y)?.usingColorSpace(.sRGB) else { return (0, 0, 0) }
    return (Int(c.redComponent * 255), Int(c.greenComponent * 255), Int(c.blueComponent * 255))
}
func diff(_ a: (Int, Int, Int), _ b: (Int, Int, Int)) -> Int {
    max(abs(a.0 - b.0), max(abs(a.1 - b.1), abs(a.2 - b.2)))
}

let bg = rgb(w / 2, h / 2)
print("size \(w)x\(h) center \(bg)")
for x in [0, 1, 2, w - 3, w - 2, w - 1] {
    var runs: [(Int, Int)] = []
    var start: Int?
    for y in 120..<(h - 60) {
        let outside = diff(rgb(x, y), bg) > 18
        if outside, start == nil { start = y }
        if !outside, let s = start { runs.append((s, y - 1)); start = nil }
    }
    if let s = start { runs.append((s, h - 61)) }
    let total = runs.reduce(0) { $0 + ($1.1 - $1.0 + 1) }
    print("x \(x): \(total) px in \(runs.count) runs \(runs.prefix(6))")
}
