import AppKit
import AVFoundation
import CoreVideo

let width = 1920
let height = 1080
let fps: Int32 = 24
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let intermediate = root.appendingPathComponent("assets/receipts-kinetic-render.mp4")
let output = root.appendingPathComponent("assets/receipts-kinetic-product-demo.mp4")
let narration = root.appendingPathComponent("assets/receipts-90-second-voiceover.aiff")
let paper = NSColor(red: 0.98, green: 0.976, blue: 0.965, alpha: 1)
let ink = NSColor(red: 0.11, green: 0.10, blue: 0.09, alpha: 1)
let stone = NSColor(red: 0.91, green: 0.90, blue: 0.88, alpha: 1)
let teal = NSColor(red: 0.04, green: 0.24, blue: 0.21, alpha: 1)
let brick = NSColor(red: 0.66, green: 0.23, blue: 0.20, alpha: 1)

enum Scene { case words(String, String), product(String, String, String, NSColor), architecture }
struct Beat { let scene: Scene; let seconds: Double }
let beats: [Beat] = [
  Beat(scene: .words("Can I trust the agent?", "receipts.  Independent verification for coding-agent claims."), seconds: 8),
  Beat(scene: .product("The agent says tests passed.", "Now ask the repository.", "assets/demo-live-input.png", teal), seconds: 12),
  Beat(scene: .product("The command is green.", "The repository disagrees.  FIX.", "assets/demo-live-fix-viewport.png", brick), seconds: 30),
  Beat(scene: .architecture, seconds: 12),
  Beat(scene: .product("A sensitive path changed.", "The claim held.  ESCALATE.", "assets/demo-live-escalate-viewport.png", brick), seconds: 14),
  Beat(scene: .words("One question before merge.", "Claim  →  Evidence  →  Decision"), seconds: 8),
  Beat(scene: .words("AI agents tell stories.", "Receipts checks whether repository evidence supports them."), seconds: 6)
]

func label(_ value: String, _ size: CGFloat, _ color: NSColor, _ weight: NSFont.Weight = .regular) -> NSAttributedString {
  NSAttributedString(string: value, attributes: [.font: NSFont.systemFont(ofSize: size, weight: weight), .foregroundColor: color])
}

func withGraphics(_ context: CGContext, _ block: () -> Void) {
  NSGraphicsContext.saveGraphicsState(); NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false); block(); NSGraphicsContext.restoreGraphicsState()
}

func backdrop(_ context: CGContext, progress: Double) {
  context.setFillColor(paper.cgColor); context.fill(CGRect(x: 0, y: 0, width: width, height: height))
  context.setFillColor(teal.withAlphaComponent(0.055).cgColor); context.fillEllipse(in: CGRect(x: -280 + 120 * progress, y: 720, width: 780, height: 780))
  context.setFillColor(brick.withAlphaComponent(0.045).cgColor); context.fillEllipse(in: CGRect(x: 1460 - 100 * progress, y: -230, width: 600, height: 600))
  withGraphics(context) { label("receipts.", 28, teal, .bold).draw(at: NSPoint(x: 92, y: 985)); label("EVIDENCE FOR AGENT CLAIMS", 15, NSColor(calibratedWhite: 0.45, alpha: 1), .medium).draw(at: NSPoint(x: 92, y: 945)) }
}

func drawCard(_ imagePath: String, accent: NSColor, progress: Double, in context: CGContext) {
  guard let image = NSImage(contentsOf: root.appendingPathComponent(imagePath)) else { return }
  let scale = 0.90 + min(progress * 2, 1) * 0.10
  let card = NSRect(x: 238, y: 125, width: 1444, height: 812)
  context.saveGState(); context.translateBy(x: card.midX, y: card.midY); context.rotate(by: CGFloat((1 - min(progress * 2, 1)) * -0.028)); context.scaleBy(x: scale, y: scale); context.translateBy(x: -card.midX, y: -card.midY)
  context.setShadow(offset: CGSize(width: 0, height: -20), blur: 42, color: NSColor.black.withAlphaComponent(0.13).cgColor)
  context.setFillColor(NSColor.white.cgColor); context.fill(card)
  context.setShadow(offset: .zero, blur: 0, color: nil); context.setStrokeColor(stone.cgColor); context.setLineWidth(2); context.stroke(card)
  withGraphics(context) { image.draw(in: card.insetBy(dx: 4, dy: 4), from: .zero, operation: .sourceOver, fraction: 1) }
  context.setFillColor(accent.cgColor); context.fill(CGRect(x: card.minX, y: card.maxY - 7, width: card.width * min(progress * 1.6, 1), height: 7))
  context.restoreGState()
}

func drawWords(_ title: String, _ sub: String, progress: Double, in context: CGContext) {
  let entry = CGFloat((1 - min(progress * 2, 1)) * 26)
  withGraphics(context) {
    label(title, 82, ink, .bold).draw(in: NSRect(x: 170, y: 605 + entry, width: 1580, height: 180))
    label(sub, 35, NSColor(calibratedWhite: 0.30, alpha: 1)).draw(in: NSRect(x: 176, y: 510 + entry, width: 1450, height: 110))
    label("●", 26, brick, .bold).draw(at: NSPoint(x: 176, y: 455))
  }
}

func drawArchitecture(_ progress: Double, in context: CGContext) {
  let stages = ["Agent narrative", "GPT-5.6 extracts claims", "Repository evidence", "Decision"]
  withGraphics(context) {
    label("The model interprets. Evidence decides.", 66, ink, .bold).draw(in: NSRect(x: 170, y: 770, width: 1500, height: 130))
    for (index, stage) in stages.enumerated() {
      let reveal = max(0, min(1, progress * 5 - Double(index)))
      let x = 170 + index * 420
      label(stage, 23, ink.withAlphaComponent(CGFloat(reveal)), .medium).draw(in: NSRect(x: x, y: 485, width: 320, height: 90))
      if index < stages.count - 1 { context.setStrokeColor(teal.withAlphaComponent(CGFloat(reveal)).cgColor); context.setLineWidth(3); context.move(to: CGPoint(x: x + 290, y: 515)); context.addLine(to: CGPoint(x: x + 385, y: 515)); context.strokePath() }
    }
    label("GPT-5.6 leaves the trust chain here.", 25, brick, .medium).draw(at: NSPoint(x: 600, y: 390))
  }
}

func render(_ beat: Beat, progress: Double, in context: CGContext) {
  backdrop(context, progress: progress)
  switch beat.scene {
  case let .words(title, sub): drawWords(title, sub, progress: progress, in: context)
  case let .product(title, sub, image, accent):
    withGraphics(context) { label(title, 53, ink, .bold).draw(at: NSPoint(x: 238, y: 965)); label(sub, 24, accent, .medium).draw(at: NSPoint(x: 242, y: 925)) }
    drawCard(image, accent: accent, progress: progress, in: context)
  case .architecture: drawArchitecture(progress, in: context)
  }
}

try? FileManager.default.removeItem(at: intermediate)
let writer = try AVAssetWriter(outputURL: intermediate, fileType: .mp4)
let input = AVAssetWriterInput(mediaType: .video, outputSettings: [AVVideoCodecKey: AVVideoCodecType.h264, AVVideoWidthKey: width, AVVideoHeightKey: height])
let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB, kCVPixelBufferWidthKey as String: width, kCVPixelBufferHeightKey as String: height])
writer.add(input); writer.startWriting(); writer.startSession(atSourceTime: .zero)
var index: Int64 = 0
for beat in beats {
  let frames = Int((beat.seconds * Double(fps)).rounded())
  for local in 0..<frames {
    while !input.isReadyForMoreMediaData { Thread.sleep(forTimeInterval: 0.002) }
    var buffer: CVPixelBuffer?; CVPixelBufferPoolCreatePixelBuffer(nil, adaptor.pixelBufferPool!, &buffer); guard let buffer else { fatalError("Frame allocation failed") }
    CVPixelBufferLockBaseAddress(buffer, [])
    let context = CGContext(data: CVPixelBufferGetBaseAddress(buffer)!, width: width, height: height, bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(buffer), space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)!
    render(beat, progress: Double(local) / Double(max(frames - 1, 1)), in: context)
    CVPixelBufferUnlockBaseAddress(buffer, []); adaptor.append(buffer, withPresentationTime: CMTime(value: index, timescale: fps)); index += 1
  }
}
input.markAsFinished(); let writingDone = DispatchSemaphore(value: 0); writer.finishWriting { writingDone.signal() }; writingDone.wait()
let video = AVURLAsset(url: intermediate); let audio = AVURLAsset(url: narration); let composition = AVMutableComposition(); let sourceVideo = video.tracks(withMediaType: .video).first!; let compVideo = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)!; try compVideo.insertTimeRange(CMTimeRange(start: .zero, duration: video.duration), of: sourceVideo, at: .zero)
if let sourceAudio = audio.tracks(withMediaType: .audio).first { let compAudio = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)!; try compAudio.insertTimeRange(CMTimeRange(start: .zero, duration: min(audio.duration, video.duration)), of: sourceAudio, at: .zero) }
try? FileManager.default.removeItem(at: output)
let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality)!; exporter.outputURL = output; exporter.outputFileType = .mp4; let exported = DispatchSemaphore(value: 0); exporter.exportAsynchronously { exported.signal() }; exported.wait(); guard exporter.status == .completed else { fatalError(exporter.error?.localizedDescription ?? "Export failed") }
try? FileManager.default.removeItem(at: intermediate)
print(output.path)
