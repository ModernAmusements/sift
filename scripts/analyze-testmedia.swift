#!/usr/bin/env swift
import CoreGraphics
import Foundation
import ImageIO
import Vision

let dir = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "build/testmedia", isDirectory: true)
let files = try FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
    .filter { ["jpg", "jpeg", "png"].contains($0.pathExtension.lowercased()) }
    .sorted { $0.lastPathComponent < $1.lastPathComponent }

func load(_ url: URL) -> CGImage? {
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
    return CGImageSourceCreateImageAtIndex(source, 0, nil)
}

func dHash(_ image: CGImage) -> UInt64 {
    let w = 9, h = 8
    var pixels = [UInt8](repeating: 0, count: w * h)
    guard let ctx = CGContext(data: &pixels, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w, space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue) else { return 0 }
    ctx.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
    var hash: UInt64 = 0
    var bit = 0
    for y in 0..<h { for x in 0..<(w - 1) { if pixels[y*w+x] > pixels[y*w+x+1] { hash |= 1 << UInt64(bit) }; bit += 1 } }
    return hash
}

func sharpness(_ image: CGImage) -> Double {
    let side = 160
    var pixels = [UInt8](repeating: 0, count: side * side)
    guard let ctx = CGContext(data: &pixels, width: side, height: side, bitsPerComponent: 8, bytesPerRow: side, space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue) else { return 0 }
    ctx.draw(image, in: CGRect(x: 0, y: 0, width: side, height: side))
    var sum = 0.0, sq = 0.0; var n = 0
    for y in 1..<(side-1) { for x in 1..<(side-1) {
        let i = y*side+x
        let v = 4*Int(pixels[i]) - Int(pixels[i-1]) - Int(pixels[i+1]) - Int(pixels[i-side]) - Int(pixels[i+side])
        let d = Double(abs(v)); sum += d; sq += d*d; n += 1
    }}
    let mean = sum/Double(n)
    return max(sq/Double(n) - mean*mean, 0)
}

func print_(_ image: CGImage) -> VNFeaturePrintObservation? {
    let request = VNGenerateImageFeaturePrintRequest()
    request.imageCropAndScaleOption = .centerCrop
    let handler = VNImageRequestHandler(cgImage: image, options: [:])
    try? handler.perform([request])
    return request.results?.first
}

struct Item { let name: String; let hash: UInt64; let sharp: Double; let print: VNFeaturePrintObservation }

var items: [Item] = []
for url in files {
    guard let image = load(url), let fp = print_(image) else { print("skip", url.lastPathComponent); continue }
    items.append(Item(name: url.lastPathComponent, hash: dHash(image), sharp: sharpness(image), print: fp))
}

for item in items {
    print(String(format: "%@  hash=%016llx  sharp=%.1f", item.name, item.hash, item.sharp))
}

print("\nPairwise feature-print distances (only < 0.7 shown):")
for i in 0..<items.count {
    for j in (i+1)..<items.count {
        var distance: Float = 0
        try? items[i].print.computeDistance(&distance, to: items[j].print)
        let hamming = (items[i].hash ^ items[j].hash).nonzeroBitCount
        if distance < 0.7 {
            print(String(format: "%.3f  dHash=%2d  %@ ↔ %@", distance, hamming, items[i].name, items[j].name))
        }
    }
}
