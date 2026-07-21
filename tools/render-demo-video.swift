import AppKit
import AVFoundation
import CoreVideo

let width = 1920
let height = 1080
let fps: Int32 = 24
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let output = root.appendingPathComponent("assets/receipts-90-second-render.mp4")
let audioURL = root.appendingPathComponent("assets/receipts-90-second-voiceover.aiff")

struct Slide {
  let title: String
  let body: String
  let image: String?
  let accent: NSColor
  let seconds: Double
}

let slides = [
  Slide(title: "Checkout task complete.", body: "✓ Tests passed\n✓ npm test exited successfully", image: nil, accent: NSColor(red: 0.02, green: 0.47, blue: 0.34, alpha: 1), seconds: 4),
  Slide(title: "Prove it.", body: "\nreceipts.", image: nil, accent: NSColor(red: 0.66, green: 0.23, blue: 0.20, alpha: 1), seconds: 4),
  Slide(title: "Does the repository agree?", body: "Frozen replay · Weakened test\n\nVerify the summary", image: nil, accent: NSColor(red: 0.04, green: 0.24, blue: 0.21, alpha: 1), seconds: 9),
  Slide(title: "✓ npm test executed successfully", body: "BUT\n\ntest.skip('adds tax'...)\nAssertion removed\n\nFIX", image: "assets/lied-test-run-fix.png", accent: NSColor(red: 0.66, green: 0.23, blue: 0.20, alpha: 1), seconds: 10),
  Slide(title: "Agent claim  →  Repository evidence", body: "✓ npm test executed successfully\n\nBUT\n\ntest.skip(...)\nremoved assertion\n\nFIX", image: "assets/live-codex-fix-reveal.gif", accent: NSColor(red: 0.66, green: 0.23, blue: 0.20, alpha: 1), seconds: 18),
  Slide(title: "GPT-5.6     │     Repository evidence", body: "Extracts the claim.     │     Determines the recommendation.\n\nThe trust chain breaks here.", image: nil, accent: NSColor(red: 0.04, green: 0.24, blue: 0.21, alpha: 1), seconds: 10),
  Slide(title: "Sensitive path changed.", body: "auth/session.mjs\n\nThe command claim held.\n\nESCALATE", image: "assets/blast-radius-escalate.jpg", accent: NSColor(red: 0.66, green: 0.23, blue: 0.20, alpha: 1), seconds: 10),
  Slide(title: "Narrative  →  Claims", body: "Evidence  →  Decision", image: nil, accent: NSColor(red: 0.04, green: 0.24, blue: 0.21, alpha: 1), seconds: 7),
  Slide(title: "What Receipts does not do", body: "Code review  ·  Correctness proof  ·  CI replacement  ·  Security guarantee", image: nil, accent: NSColor(red: 0.29, green: 0.27, blue: 0.25, alpha: 1), seconds: 5),
  Slide(title: "Built for engineers merging agent work.", body: "A calm, evidence-backed decision before merge.", image: "assets/clean-run-merge.jpg", accent: NSColor(red: 0.04, green: 0.24, blue: 0.21, alpha: 1), seconds: 5),
  Slide(title: "AI agents tell stories.", body: "Receipts checks whether repository evidence supports them.\n\nreceipts.", image: nil, accent: NSColor(red: 0.66, green: 0.23, blue: 0.20, alpha: 1), seconds: 8)
]

func attributed(_ text: String, size: CGFloat, color: NSColor, weight: NSFont.Weight = .regular) -> NSAttributedString {
  NSAttributedString(string: text, attributes: [.font: NSFont.systemFont(ofSize: size, weight: weight), .foregroundColor: color])
}

func drawSlide(_ slide: Slide, time: Double, in context: CGContext) {
  context.setFillColor(NSColor(red: 0.98, green: 0.976, blue: 0.965, alpha: 1).cgColor)
  context.fill(CGRect(x: 0, y: 0, width: width, height: height))
  context.setFillColor(slide.accent.cgColor)
  context.fill(CGRect(x: 0, y: height - 18, width: width, height: 18))
  let graphics = NSGraphicsContext(cgContext: context, flipped: false)
  NSGraphicsContext.saveGraphicsState()
  NSGraphicsContext.current = graphics
  attributed("✓  receipts.", size: 30, color: slide.accent, weight: .bold).draw(at: NSPoint(x: 112, y: 970))
  attributed("INDEPENDENT AGENT VERIFICATION", size: 16, color: NSColor(calibratedWhite: 0.42, alpha: 1), weight: .medium).draw(at: NSPoint(x: 112, y: 925))
  let titleRect = NSRect(x: 112, y: 660, width: slide.image == nil ? 1450 : 810, height: 240)
  attributed(slide.title, size: 76, color: NSColor(calibratedWhite: 0.12, alpha: 1), weight: .bold).draw(in: titleRect)
  let bodyRect = NSRect(x: 118, y: 390, width: slide.image == nil ? 1140 : 730, height: 250)
  attributed(slide.body, size: 31, color: NSColor(calibratedWhite: 0.28, alpha: 1)).draw(in: bodyRect)
  if let imagePath = slide.image, let image = NSImage(contentsOf: root.appendingPathComponent(imagePath)) {
    let frame = NSRect(x: 940, y: 170, width: 820, height: 680)
    context.setFillColor(NSColor.white.cgColor)
    context.fill(frame.insetBy(dx: -10, dy: -10))
    image.draw(in: frame, from: .zero, operation: .sourceOver, fraction: 1)
  }
  let progress = min(1, max(0, time / slide.seconds))
  context.setFillColor(slide.accent.withAlphaComponent(0.18).cgColor)
  context.fill(CGRect(x: 112, y: 92, width: 1696, height: 5))
  context.setFillColor(slide.accent.cgColor)
  context.fill(CGRect(x: 112, y: 92, width: 1696 * progress, height: 5))
  NSGraphicsContext.restoreGraphicsState()
}

try? FileManager.default.removeItem(at: output)
let writer = try AVAssetWriter(outputURL: output, fileType: .mp4)
let settings: [String: Any] = [AVVideoCodecKey: AVVideoCodecType.h264, AVVideoWidthKey: width, AVVideoHeightKey: height]
let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
let attrs: [String: Any] = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB, kCVPixelBufferWidthKey as String: width, kCVPixelBufferHeightKey as String: height]
let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: attrs)
writer.add(input)
writer.startWriting()
writer.startSession(atSourceTime: .zero)
var frame: Int64 = 0
var cursor = 0.0
for slide in slides {
  let frames = Int((slide.seconds * Double(fps)).rounded())
  for localFrame in 0..<frames {
    while !input.isReadyForMoreMediaData { Thread.sleep(forTimeInterval: 0.002) }
    var pixelBuffer: CVPixelBuffer?
    CVPixelBufferPoolCreatePixelBuffer(nil, adaptor.pixelBufferPool!, &pixelBuffer)
    guard let buffer = pixelBuffer else { fatalError("Could not allocate video frame") }
    CVPixelBufferLockBaseAddress(buffer, [])
    let base = CVPixelBufferGetBaseAddress(buffer)!
    let bytes = CVPixelBufferGetBytesPerRow(buffer)
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let context = CGContext(data: base, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytes, space: colorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)!
    drawSlide(slide, time: Double(localFrame) / Double(fps), in: context)
    CVPixelBufferUnlockBaseAddress(buffer, [])
    adaptor.append(buffer, withPresentationTime: CMTime(value: frame, timescale: fps))
    frame += 1
  }
  cursor += slide.seconds
}
input.markAsFinished()
let videoDone = DispatchSemaphore(value: 0)
writer.finishWriting { videoDone.signal() }
videoDone.wait()

let composition = AVMutableComposition()
let rendered = AVURLAsset(url: output)
let videoTrack = rendered.tracks(withMediaType: .video).first!
let compositionVideo = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)!
try compositionVideo.insertTimeRange(CMTimeRange(start: .zero, duration: rendered.duration), of: videoTrack, at: .zero)
if FileManager.default.fileExists(atPath: audioURL.path) {
  let audio = AVURLAsset(url: audioURL)
  if let audioTrack = audio.tracks(withMediaType: .audio).first {
    let compositionAudio = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)!
    try compositionAudio.insertTimeRange(CMTimeRange(start: .zero, duration: min(audio.duration, rendered.duration)), of: audioTrack, at: .zero)
  }
}
let finalURL = root.appendingPathComponent("assets/receipts-90-second-product-demo.mp4")
try? FileManager.default.removeItem(at: finalURL)
let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality)!
exporter.outputURL = finalURL
exporter.outputFileType = .mp4
let exportDone = DispatchSemaphore(value: 0)
exporter.exportAsynchronously { exportDone.signal() }
exportDone.wait()
guard exporter.status == .completed else { fatalError(exporter.error?.localizedDescription ?? "Video export failed") }
try? FileManager.default.removeItem(at: output)
print(finalURL.path)
