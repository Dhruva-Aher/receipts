import AppKit
import AVFoundation
import CoreVideo

let width = 1920
let height = 1080
let fps: Int32 = 24
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let intermediate = root.appendingPathComponent("assets/receipts-three-minute-render.mp4")
let output = root.appendingPathComponent("assets/receipts-3-minute-hackathon-demo.mp4")

let paper = NSColor(red: 0.98, green: 0.976, blue: 0.965, alpha: 1)
let ink = NSColor(red: 0.11, green: 0.10, blue: 0.09, alpha: 1)
let stone = NSColor(red: 0.91, green: 0.90, blue: 0.88, alpha: 1)
let teal = NSColor(red: 0.04, green: 0.24, blue: 0.21, alpha: 1)
let brick = NSColor(red: 0.66, green: 0.23, blue: 0.20, alpha: 1)

enum Scene { case screen(String, String, String), words(String, String, NSColor), black }
struct Beat { let scene: Scene; let seconds: Double }

let beats: [Beat] = [
  Beat(scene: .screen("The agent made a claim.", "Does the repository support it?", "assets/demo-live-input.png"), seconds: 8),
  Beat(scene: .words("Prove it.", "", brick), seconds: 5),
  Beat(scene: .screen("One summary. One decision.", "Choose the evidence replay, then verify what was claimed.", "assets/demo-live-input.png"), seconds: 11),
  Beat(scene: .screen("The command was green.", "The repository evidence was not.  FIX BEFORE MERGE.", "assets/demo-live-fix-viewport.png"), seconds: 20),
  Beat(scene: .words("GPT-5.6 extracts the claim.", "Repository evidence determines the recommendation.\n\nThe model leaves the trust chain here.", teal), seconds: 10),
  Beat(scene: .screen("The claim held. The path changed.", "A sensitive authentication path requires a human decision.  ESCALATE.", "assets/demo-live-escalate-viewport.png"), seconds: 18),
  Beat(scene: .screen("A receipt keeps both facts visible.", "The claim, the command result, the skipped test, and the removed assertion.", "assets/demo-live-fix-full-receipt.png"), seconds: 14),
  Beat(scene: .screen("Receipts has memory.", "The Verification Ledger preserves every claim, evidence set, and recommendation.", "assets/demo-live-ledger.png"), seconds: 16),
  Beat(scene: .screen("Receipts sees where trust breaks.", "Claim Patterns state the retained evidence as facts — never a confidence score.", "assets/demo-live-patterns.png"), seconds: 16),
  Beat(scene: .words("Narrative.\nClaims.\nEvidence.\nDecision.", "", teal), seconds: 8),
  Beat(scene: .words("Receipts does not review code quality.\nIt does not prove correctness.\nIt does not replace CI.\nIt does not guarantee security.", "Its scope is narrow by design.", ink), seconds: 10),
  Beat(scene: .screen("One question before merge.", "Does the repository support what the agent said?", "assets/demo-live-input.png"), seconds: 12),
  Beat(scene: .words("AI agents tell stories.", "Receipts checks whether they’re true.", brick), seconds: 10),
  Beat(scene: .black, seconds: 22)
]

func text(_ value: String, _ size: CGFloat, _ color: NSColor, _ weight: NSFont.Weight = .regular) -> NSAttributedString {
  NSAttributedString(string: value, attributes: [.font: NSFont.systemFont(ofSize: size, weight: weight), .foregroundColor: color])
}

func graphics(_ context: CGContext, _ draw: () -> Void) {
  NSGraphicsContext.saveGraphicsState()
  NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
  draw()
  NSGraphicsContext.restoreGraphicsState()
}

func drawPaper(_ context: CGContext) {
  context.setFillColor(paper.cgColor)
  context.fill(CGRect(x: 0, y: 0, width: width, height: height))
  graphics(context) {
    text("✓", 25, teal, .bold).draw(at: NSPoint(x: 96, y: 987))
    text("receipts.", 29, ink, .bold).draw(at: NSPoint(x: 130, y: 985))
    text("EVIDENCE-BASED AGENT VERIFICATION", 14, NSColor(calibratedWhite: 0.46, alpha: 1), .medium).draw(at: NSPoint(x: 98, y: 946))
  }
}

func drawScreen(_ headline: String, _ subtitle: String, _ path: String, _ progress: Double, _ context: CGContext) {
  drawPaper(context)
  let image = NSImage(contentsOf: root.appendingPathComponent(path))!
  let card = NSRect(x: 145, y: 105, width: 1630, height: 725)
  let zoom = CGFloat(1.0 + min(progress, 1) * 0.045)
  let source = NSRect(x: image.size.width * (zoom - 1) / (2 * zoom), y: image.size.height * (zoom - 1) / (2 * zoom), width: image.size.width / zoom, height: image.size.height / zoom)
  context.setFillColor(NSColor.white.cgColor)
  context.fill(card)
  context.setStrokeColor(stone.cgColor)
  context.setLineWidth(2)
  context.stroke(card)
  graphics(context) { image.draw(in: card.insetBy(dx: 3, dy: 3), from: source, operation: .sourceOver, fraction: 1) }
  let entry = CGFloat(max(0, 1 - progress * 3) * 18)
  graphics(context) {
    text(headline, 48, ink, .bold).draw(at: NSPoint(x: 150, y: 896 + entry))
    text(subtitle, 23, NSColor(calibratedWhite: 0.34, alpha: 1)).draw(in: NSRect(x: 152, y: 845 + entry, width: 1520, height: 48))
  }
}

func drawWords(_ title: String, _ subtitle: String, _ accent: NSColor, _ progress: Double, _ context: CGContext) {
  drawPaper(context)
  let entry = CGFloat(max(0, 1 - progress * 3) * 22)
  graphics(context) {
    text(title, 70, accent == ink ? ink : accent, .bold).draw(in: NSRect(x: 180, y: 545 + entry, width: 1560, height: 360))
    if !subtitle.isEmpty { text(subtitle, 30, NSColor(calibratedWhite: 0.31, alpha: 1)).draw(in: NSRect(x: 187, y: 380 + entry, width: 1460, height: 150)) }
  }
}

func render(_ beat: Beat, _ progress: Double, _ context: CGContext) {
  switch beat.scene {
  case let .screen(headline, subtitle, path): drawScreen(headline, subtitle, path, progress, context)
  case let .words(title, subtitle, accent): drawWords(title, subtitle, accent, progress, context)
  case .black:
    context.setFillColor(NSColor.black.cgColor)
    context.fill(CGRect(x: 0, y: 0, width: width, height: height))
    let opacity = CGFloat(min(1, progress * 3))
    graphics(context) {
      text("✓", 52, NSColor.white.withAlphaComponent(opacity), .bold).draw(at: NSPoint(x: 788, y: 560))
      text("receipts.", 60, NSColor.white.withAlphaComponent(opacity), .bold).draw(at: NSPoint(x: 850, y: 550))
      text("EVIDENCE-BASED AGENT VERIFICATION", 14, NSColor(calibratedWhite: 0.65, alpha: opacity), .medium).draw(at: NSPoint(x: 806, y: 505))
    }
  }
}

try? FileManager.default.removeItem(at: intermediate)
let writer = try AVAssetWriter(outputURL: intermediate, fileType: .mp4)
let input = AVAssetWriterInput(mediaType: .video, outputSettings: [AVVideoCodecKey: AVVideoCodecType.h264, AVVideoWidthKey: width, AVVideoHeightKey: height])
let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB, kCVPixelBufferWidthKey as String: width, kCVPixelBufferHeightKey as String: height])
writer.add(input)
writer.startWriting()
writer.startSession(atSourceTime: .zero)
var frame: Int64 = 0
for beat in beats {
  let frames = Int((beat.seconds * Double(fps)).rounded())
  for localFrame in 0..<frames {
    while !input.isReadyForMoreMediaData { Thread.sleep(forTimeInterval: 0.002) }
    var buffer: CVPixelBuffer?
    CVPixelBufferPoolCreatePixelBuffer(nil, adaptor.pixelBufferPool!, &buffer)
    guard let buffer else { fatalError("Frame allocation failed") }
    CVPixelBufferLockBaseAddress(buffer, [])
    let context = CGContext(data: CVPixelBufferGetBaseAddress(buffer)!, width: width, height: height, bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(buffer), space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)!
    render(beat, Double(localFrame) / Double(max(frames - 1, 1)), context)
    CVPixelBufferUnlockBaseAddress(buffer, [])
    adaptor.append(buffer, withPresentationTime: CMTime(value: frame, timescale: fps))
    frame += 1
  }
}
input.markAsFinished()
let finished = DispatchSemaphore(value: 0)
writer.finishWriting { finished.signal() }
finished.wait()
guard writer.status == .completed else { fatalError(writer.error?.localizedDescription ?? "Video render failed") }

let rendered = AVURLAsset(url: intermediate)
let composition = AVMutableComposition()
let sourceVideo = rendered.tracks(withMediaType: .video).first!
let compositionVideo = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)!
try compositionVideo.insertTimeRange(CMTimeRange(start: .zero, duration: rendered.duration), of: sourceVideo, at: .zero)
try? FileManager.default.removeItem(at: output)
let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality)!
exporter.outputURL = output
exporter.outputFileType = .mp4
let exported = DispatchSemaphore(value: 0)
exporter.exportAsynchronously { exported.signal() }
exported.wait()
guard exporter.status == .completed else { fatalError(exporter.error?.localizedDescription ?? "Final video export failed") }
try? FileManager.default.removeItem(at: intermediate)
print(output.path)
