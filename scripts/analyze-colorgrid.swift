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

func grid(_ image: CGImage, side: Int = 8) -> [UInt8] {
    var pixels = [UInt8](repeating: 0, count: side * side * 4)
    guard let ctx = CGContext(data: &pixels, width: side, height: side, bitsPerComponent: 8, bytesPerRow: side * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else { return pixels }
    ctx.interpolationQuality = .high
    // Match PHImageManager's aspect-fill thumbnail: crop to a centered square first.
    let sideLength = min(image.width, image.height)
    let crop = CGRect(
        x: CGFloat(image.width - sideLength) / 2,
        y: CGFloat(image.height - sideLength) / 2,
        width: CGFloat(sideLength),
        height: CGFloat(sideLength)
    )
    if let square = image.cropping(to: crop) {
        ctx.draw(square, in: CGRect(x: 0, y: 0, width: side, height: side))
    }
    return pixels
}

func distance(_ a: [UInt8], _ b: [UInt8]) -> Double {
    var total = 0.0
    var count = 0
    for index in 0..<a.count where index % 4 != 3 {
        total += abs(Double(a[index]) - Double(b[index]))
        count += 1
    }
    return total / (Double(count) * 255)
}

var items: [(String, [UInt8])] = []
for url in files {
    guard let image = load(url) else { continue }
    items.append((url.lastPathComponent, grid(image)))
}

print("color grid 8x8 mean absolute RGB distance")
for i in 0..<items.count {
    for j in (i+1)..<items.count {
        let d = distance(items[i].1, items[j].1)
        if d < 0.24 {
            print(String(format: "%.3f  %@ ↔ %@", d, items[i].0, items[j].0))
        }
    }
}
