import Foundation
import ImageIO
import UniformTypeIdentifiers

guard CommandLine.arguments.count == 3 else {
    fatalError("usage: make_gif.swift FRAME_DIR OUTPUT.gif")
}

let framesDirectory = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let outputURL = URL(fileURLWithPath: CommandLine.arguments[2])
let frameURLs = try FileManager.default.contentsOfDirectory(
    at: framesDirectory,
    includingPropertiesForKeys: nil
).filter { $0.pathExtension.lowercased() == "png" }.sorted { $0.lastPathComponent < $1.lastPathComponent }

guard !frameURLs.isEmpty else { fatalError("no PNG frames") }
guard let destination = CGImageDestinationCreateWithURL(
    outputURL as CFURL,
    UTType.gif.identifier as CFString,
    frameURLs.count,
    nil
) else { fatalError("could not create GIF destination") }

let loopProperties: [CFString: Any] = [kCGImagePropertyGIFLoopCount: 0]
CGImageDestinationSetProperties(
    destination,
    [kCGImagePropertyGIFDictionary: loopProperties] as CFDictionary
)

for frameURL in frameURLs {
    guard let source = CGImageSourceCreateWithURL(frameURL as CFURL, nil),
          let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
        fatalError("could not read \(frameURL.path)")
    }
    let isEndpointHold = frameURL.lastPathComponent < "frame-005.png" || frameURL.lastPathComponent > "frame-044.png"
    let delay = isEndpointHold ? 0.18 : 0.10
    let frameProperties: [CFString: Any] = [
        kCGImagePropertyGIFDelayTime: delay,
        kCGImagePropertyGIFUnclampedDelayTime: delay,
    ]
    CGImageDestinationAddImage(
        destination,
        image,
        [kCGImagePropertyGIFDictionary: frameProperties] as CFDictionary
    )
}

guard CGImageDestinationFinalize(destination) else {
    fatalError("could not finalize GIF")
}

print("gif_frames=\(frameURLs.count)")
