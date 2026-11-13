#!/usr/bin/env swift
// Generates deterministic test media for the iPhone 12 simulator.
import AppKit
import CoreImage
import Foundation

let out = URL(fileURLWithPath: "build/testmedia", isDirectory: true)
try? FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)

func render(_ size: CGSize, _ draw: () -> Void) -> NSImage {
    let image = NSImage(size: size)
    image.lockFocus()
    NSGraphicsContext.current?.imageInterpolation = .high
    draw()
    image.unlockFocus()
    return image
}

func savePNG(_ image: NSImage, _ name: String) {
    guard let tiff = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let data = rep.representation(using: .png, properties: [:]) else { return }
    let url = out.appendingPathComponent(name)
    try? data.write(to: url)
    stamp(url)
}

func saveJPEG(_ image: NSImage, _ name: String, quality: CGFloat = 0.9) {
    guard let tiff = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let data = rep.representation(using: .jpeg, properties: [.compressionFactor: quality]) else { return }
    let url = out.appendingPathComponent(name)
    try? data.write(to: url)
    stamp(url)
}

func stamp(_ url: URL) {
    let date = Calendar.current.date(from: DateComponents(year: 2026, month: 11, day: 12, hour: 11)) ?? Date()
    try? FileManager.default.setAttributes(
        [.creationDate: date, .modificationDate: date],
        ofItemAtPath: url.path
    )
}

func color(_ hex: UInt32, alpha: CGFloat = 1) -> NSColor {
    NSColor(
        srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
        green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255,
        alpha: alpha
    )
}

func screenshot(title: String, kicker: String, detail: String, accent: NSColor, name: String) {
    let size = CGSize(width: 1170, height: 2532)
    let image = render(size) {
        color(0xF7F7F5).setFill()
        NSRect(origin: .zero, size: size).fill()

        // Status bar
        let status = NSAttributedString(string: "9:41", attributes: [
            .font: NSFont.systemFont(ofSize: 46, weight: .semibold),
            .foregroundColor: NSColor.black
        ])
        status.draw(at: CGPoint(x: 92, y: 2452))
        let indicator = NSBezierPath(roundedRect: NSRect(x: 830, y: 2466, width: 250, height: 34), xRadius: 17, yRadius: 17)
        NSColor.black.withAlphaComponent(0.85).setFill()
        indicator.fill()

        // Header
        NSAttributedString(string: kicker.uppercased(), attributes: [
            .font: NSFont.systemFont(ofSize: 34, weight: .semibold),
            .foregroundColor: NSColor.secondaryLabelColor,
            .kern: 2
        ]).draw(at: CGPoint(x: 92, y: 2240))

        NSAttributedString(string: title, attributes: [
            .font: NSFont.systemFont(ofSize: 92, weight: .bold),
            .foregroundColor: NSColor.black
        ]).draw(in: NSRect(x: 92, y: 1980, width: 986, height: 220))

        // Card
        let card = NSBezierPath(roundedRect: NSRect(x: 92, y: 1150, width: 986, height: 740), xRadius: 48, yRadius: 48)
        accent.setFill()
        card.fill()

        NSAttributedString(string: detail, attributes: [
            .font: NSFont.systemFont(ofSize: 54, weight: .medium),
            .foregroundColor: NSColor.white
        ]).draw(in: NSRect(x: 150, y: 1320, width: 860, height: 420))

        let footer = NSBezierPath(roundedRect: NSRect(x: 92, y: 760, width: 986, height: 260), xRadius: 40, yRadius: 40)
        NSColor.white.setFill()
        footer.fill()
        NSColor.black.withAlphaComponent(0.08).setStroke()
        footer.lineWidth = 2
        footer.stroke()

        NSAttributedString(string: "Sift demo screenshot · no personal data", attributes: [
            .font: NSFont.systemFont(ofSize: 34, weight: .regular),
            .foregroundColor: NSColor.secondaryLabelColor
        ]).draw(at: CGPoint(x: 150, y: 870))

        let home = NSBezierPath(roundedRect: NSRect(x: 430, y: 60, width: 310, height: 12), xRadius: 6, yRadius: 6)
        NSColor.black.withAlphaComponent(0.75).setFill()
        home.fill()
    }
    savePNG(image, name)
}

func scene(sunX: CGFloat, mountainShift: CGFloat, name: String, quality: CGFloat = 0.9) {
    let size = CGSize(width: 1600, height: 1200)
    let image = render(size) {
        let sky = NSGradient(colors: [color(0xBFD9E8), color(0xE9E4D6)])!
        sky.draw(in: NSRect(origin: .zero, size: size), angle: -90)

        let sunRect = NSRect(x: sunX, y: 760, width: 260, height: 260)
        color(0xF2E3C2).setFill()
        NSBezierPath(ovalIn: sunRect).fill()

        let sea = NSBezierPath()
        sea.move(to: CGPoint(x: 0, y: 470))
        sea.line(to: CGPoint(x: 1600, y: 440))
        sea.line(to: CGPoint(x: 1600, y: 0))
        sea.line(to: CGPoint(x: 0, y: 0))
        sea.close()
        color(0x8CA9B4).setFill()
        sea.fill()

        let mountains = NSBezierPath()
        mountains.move(to: CGPoint(x: 0, y: 470))
        mountains.line(to: CGPoint(x: 240 + mountainShift, y: 790))
        mountains.line(to: CGPoint(x: 520 + mountainShift, y: 520))
        mountains.line(to: CGPoint(x: 760 + mountainShift, y: 850))
        mountains.line(to: CGPoint(x: 1080 + mountainShift, y: 500))
        mountains.line(to: CGPoint(x: 1360 + mountainShift, y: 760))
        mountains.line(to: CGPoint(x: 1600, y: 520))
        mountains.line(to: CGPoint(x: 1600, y: 0))
        mountains.line(to: CGPoint(x: 0, y: 0))
        mountains.close()
        color(0x4C5A5C).setFill()
        mountains.fill()

        for index in 0..<9 {
            let x = CGFloat(index) * 200 + mountainShift
            let bar = NSBezierPath(roundedRect: NSRect(x: x, y: 250, width: 90, height: 6), xRadius: 3, yRadius: 3)
            NSColor.white.withAlphaComponent(0.22).setFill()
            bar.fill()
        }
    }
    saveJPEG(image, name, quality: quality)
}

func blurred(_ source: NSImage, radius: Double, name: String) {
    guard let tiff = source.tiffRepresentation,
          let ci = CIImage(data: tiff),
          let filter = CIFilter(name: "CIGaussianBlur") else { return }
    filter.setValue(ci, forKey: kCIInputImageKey)
    filter.setValue(radius, forKey: kCIInputRadiusKey)
    guard let output = filter.outputImage,
          let cg = CIContext().createCGImage(output, from: ci.extent) else { return }
    saveJPEG(NSImage(cgImage: cg, size: source.size), name)
}

screenshot(
    title: "Boarding pass",
    kicker: "Lufthansa · LH 1984",
    detail: "FRA → BER\n12 Nov · Seat 14A\nGate A22 · 18:40",
    accent: color(0x2A2A2E),
    name: "Screenshot-boarding.png"
)
screenshot(
    title: "Order confirmed",
    kicker: "Coffee · Pickup",
    detail: "Flat white · Oat milk\nTable 12 · 10:15\nOrder #4821",
    accent: color(0x7A6A52),
    name: "Screenshot-order.png"
)
screenshot(
    title: "Train ticket",
    kicker: "Deutsche Bahn",
    detail: "Bielefeld → Berlin\nICE 543 · Platform 3\nCoach 8 · Seat 42",
    accent: color(0x3E4C59),
    name: "Screenshot-train.png"
)

scene(sunX: 1010, mountainShift: 0, name: "Photo-beach-1.jpg")
scene(sunX: 1040, mountainShift: 26, name: "Photo-beach-2.jpg")
scene(sunX: 1080, mountainShift: 8, name: "Photo-beach-3.jpg")
scene(sunX: 300, mountainShift: 120, name: "Photo-hills-1.jpg")
scene(sunX: 330, mountainShift: 140, name: "Photo-hills-2.jpg")

let beach = NSImage(contentsOf: out.appendingPathComponent("Photo-beach-1.jpg"))!
blurred(beach, radius: 22, name: "Photo-blurry-1.jpg")
blurred(beach, radius: 34, name: "Photo-blurry-2.jpg")

// Byte-identical duplicate for exact-duplicate detection.
try? FileManager.default.copyItem(
    at: out.appendingPathComponent("Photo-hills-1.jpg"),
    to: out.appendingPathComponent("Photo-hills-duplicate.jpg")
)

print("test media written to \(out.path)")
