#!/usr/bin/env swift
import CoreGraphics
import Foundation
import ImageIO

let dir = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "build/testmedia", isDirectory: true)
let files = try FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
    .filter { ["jpg", "jpeg", "png"].contains($0.pathExtension.lowercased()) }
    .sorted { $0.lastPathComponent < $1.lastPathComponent }

func load(_ url: URL) -> CGImage? {
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
    return CGImageSourceCreateImageAtIndex(source, 0, nil)
}

func fineHash(_ image: CGImage) -> [UInt64] {
    let w = 17, h = 16
    var pixels = [UInt8](repeating: 0, count: w * h)
    guard let ctx = CGContext(data: &pixels, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w, space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue) else { return [0,0,0,0] }
    ctx.interpolationQuality = .high
    ctx.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
    var words = [UInt64](repeating: 0, count: 4)
    var bit = 0
    for y in 0..<h {
        for x in 0..<(w - 1) {
            if pixels[y*w+x] > pixels[y*w+x+1] {
                words[bit / 64] |= 1 << UInt64(bit % 64)
            }
            bit += 1
        }
    }
    return words
}

func distance(_ a: [UInt64], _ b: [UInt64]) -> Int {
    zip(a, b).reduce(0) { $0 + ($1.0 ^ $1.1).nonzeroBitCount }
}

var items: [(String, [UInt64])] = []
for url in files {
    guard let image = load(url) else { continue }
    items.append((url.lastPathComponent, fineHash(image)))
}

print("fine hash 256 bits")
for i in 0..<items.count {
    for j in (i+1)..<items.count {
        let d = distance(items[i].1, items[j].1)
        let n = Double(d) / 256.0
        if n < 0.42 {
            print(String(format: "%.3f (%3d)  %@ ↔ %@", n, d, items[i].0, items[j].0))
        }
    }
}
