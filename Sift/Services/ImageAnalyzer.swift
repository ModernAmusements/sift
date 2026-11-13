import CoreGraphics
import UIKit
import Vision

struct ImageSignature {
    let dHash: UInt64
    let sharpness: Double
    let featurePrint: VNFeaturePrintObservation?
    /// 8×8 RGB thumbprint, used when Vision feature prints are unavailable.
    let colorGrid: [UInt8]
}

enum ImageAnalyzer {
    /// Difference hash: resize to 9×8 grayscale, one bit per horizontal neighbour comparison.
    static func dHash(_ image: CGImage) -> UInt64 {
        let width = 9
        let height = 8
        guard let pixels = grayscale(image, width: width, height: height) else { return 0 }

        var hash: UInt64 = 0
        var bit = 0
        for y in 0..<height {
            for x in 0..<(width - 1) {
                if pixels[y * width + x] > pixels[y * width + x + 1] {
                    hash |= (1 << UInt64(bit))
                }
                bit += 1
            }
        }
        return hash
    }

    /// Variance of the Laplacian on a 160×160 grayscale copy. Low values mean soft focus.
    static func sharpness(_ image: CGImage, side: Int = 160) -> Double {
        guard let pixels = grayscale(image, width: side, height: side) else { return 0 }

        var sum = 0.0
        var sumSquares = 0.0
        var count = 0
        for y in 1..<(side - 1) {
            for x in 1..<(side - 1) {
                let index = y * side + x
                let value = 4 * Int(pixels[index])
                    - Int(pixels[index - 1])
                    - Int(pixels[index + 1])
                    - Int(pixels[index - side])
                    - Int(pixels[index + side])
                let magnitude = Double(abs(value))
                sum += magnitude
                sumSquares += magnitude * magnitude
                count += 1
            }
        }
        guard count > 0 else { return 0 }
        let mean = sum / Double(count)
        return max(sumSquares / Double(count) - mean * mean, 0)
    }

    static func featurePrint(_ image: CGImage) -> VNFeaturePrintObservation? {
        let request = VNGenerateImageFeaturePrintRequest()
        request.imageCropAndScaleOption = .centerCrop
        let handler = VNImageRequestHandler(cgImage: image, orientation: .up, options: [:])
        do {
            try handler.perform([request])
            return request.results?.first
        } catch {
            return nil
        }
    }

    static func signature(for image: UIImage) -> ImageSignature? {
        guard let cgImage = image.cgImage else { return nil }
        return ImageSignature(
            dHash: dHash(cgImage),
            sharpness: sharpness(cgImage),
            featurePrint: featurePrint(cgImage),
            colorGrid: colorGrid(cgImage)
        )
    }

    /// A tiny center-cropped color mosaic. Cheap, deterministic and good enough to
    /// separate scenes on devices where Vision feature prints are unavailable.
    static func colorGrid(_ image: CGImage, side: Int = 8) -> [UInt8] {
        let count = side * side * 4
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: count)
        buffer.initialize(repeating: 0, count: count)
        defer { buffer.deallocate() }

        guard let context = CGContext(
            data: buffer,
            width: side,
            height: side,
            bitsPerComponent: 8,
            bytesPerRow: side * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ) else { return Array(repeating: 0, count: count) }
        context.interpolationQuality = .high

        let edge = min(image.width, image.height)
        let crop = CGRect(
            x: CGFloat(image.width - edge) / 2,
            y: CGFloat(image.height - edge) / 2,
            width: CGFloat(edge),
            height: CGFloat(edge)
        )
        if let square = image.cropping(to: crop) {
            context.draw(square, in: CGRect(x: 0, y: 0, width: side, height: side))
        }
        return Array(UnsafeBufferPointer(start: buffer, count: count))
    }

    private static func grayscale(_ image: CGImage, width: Int, height: Int) -> [UInt8]? {
        let count = width * height
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: count)
        buffer.initialize(repeating: 0, count: count)
        defer { buffer.deallocate() }

        guard let context = CGContext(
            data: buffer,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else { return nil }

        context.interpolationQuality = .medium
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        return Array(UnsafeBufferPointer(start: buffer, count: count))
    }
}
