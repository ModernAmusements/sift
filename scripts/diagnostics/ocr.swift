import AppKit
import Vision

let path = CommandLine.arguments.dropFirst().first ?? "build/home-native.png"
guard let image = NSImage(contentsOfFile: path),
      let tiff = image.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let cg = rep.cgImage else {
    print("cannot read", path)
    exit(1)
}

let request = VNRecognizeTextRequest()
request.recognitionLevel = .accurate
request.usesLanguageCorrection = false
let handler = VNImageRequestHandler(cgImage: cg, options: [:])
try? handler.perform([request])
for observation in (request.results ?? []).sorted(by: { $0.boundingBox.maxY > $1.boundingBox.maxY }) {
    if let candidate = observation.topCandidates(1).first {
        print(String(format: "%.2f %.2f  %@", observation.boundingBox.minX, observation.boundingBox.minY, candidate.string))
    }
}
