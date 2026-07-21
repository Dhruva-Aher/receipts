import AVFoundation
import AppKit
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let source = root.appendingPathComponent("assets/receipts-live-scroll-demo.mp4")
let output = URL(fileURLWithPath: "/private/tmp/receipts-video-frames")
try? FileManager.default.removeItem(at: output)
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
let generator = AVAssetImageGenerator(asset: AVURLAsset(url: source))
generator.appliesPreferredTrackTransform = true
for second in [0, 18, 39, 60, 81, 89] {
  let image = try generator.copyCGImage(at: CMTime(seconds: Double(second), preferredTimescale: 600), actualTime: nil)
  let representation = NSBitmapImageRep(cgImage: image)
  try representation.representation(using: .png, properties: [:])!.write(to: output.appendingPathComponent("frame-\(second).png"))
}
print(output.path)
