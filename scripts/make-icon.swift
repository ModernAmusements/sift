#!/usr/bin/env swift
// Draws the Sift app icon: a quiet colander, one line, three dots.
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let size = 1024
let colorSpace = CGColorSpaceCreateDeviceRGB()
guard let ctx = CGContext(
    data: nil, width: size, height: size,
    bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else { fatalError("context") }

// Warm paper background.
ctx.setFillColor(CGColor(red: 0.969, green: 0.965, blue: 0.945, alpha: 1))
ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))

let ink = CGColor(red: 0.055, green: 0.055, blue: 0.06, alpha: 1)
ctx.setStrokeColor(ink)
ctx.setFillColor(ink)
ctx.setLineCap(.round)
ctx.setLineJoin(.round)

// Lip of the colander.
ctx.setLineWidth(52)
ctx.move(to: CGPoint(x: 286, y: 648))
ctx.addLine(to: CGPoint(x: 738, y: 648))
ctx.strokePath()

// Bowl.
ctx.setLineWidth(52)
ctx.beginPath()
ctx.addArc(center: CGPoint(x: 512, y: 648), radius: 218,
           startAngle: .pi, endAngle: 0, clockwise: true)
ctx.strokePath()

// Particles inside the bowl.
for x in [430.0, 512.0, 594.0] {
    ctx.fillEllipse(in: CGRect(x: x - 25, y: 528 - 25, width: 50, height: 50))
}

guard let image = ctx.makeImage() else { fatalError("image") }
let out = URL(fileURLWithPath: "Sift/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png")
guard let dest = CGImageDestinationCreateWithURL(out as CFURL, UTType.png.identifier as CFString, 1, nil) else {
    fatalError("destination")
}
CGImageDestinationAddImage(dest, image, nil)
guard CGImageDestinationFinalize(dest) else { fatalError("write") }
print("wrote \(out.path)")
