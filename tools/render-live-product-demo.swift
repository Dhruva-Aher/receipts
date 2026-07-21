import AppKit
import AVFoundation
import CoreVideo

// A silent, continuous product walk-through. The camera moves through Receipts
// screens instead of cutting between slides or interstitial title cards.
let width = 1920
let height = 1080
let fps: Int32 = 24
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let intermediate = root.appendingPathComponent("assets/receipts-live-scroll-render.mp4")
let finalURL = root.appendingPathComponent("assets/receipts-live-scroll-demo.mp4")

let paper = NSColor(red: 0.98, green: 0.976, blue: 0.965, alpha: 1)
let ink = NSColor(red: 0.11, green: 0.10, blue: 0.09, alpha: 1)
let teal = NSColor(red: 0.04, green: 0.24, blue: 0.21, alpha: 1)
let brick = NSColor(red: 0.66, green: 0.23, blue: 0.20, alpha: 1)
let border = NSColor(red: 0.88, green: 0.87, blue: 0.84, alpha: 1)

enum Moment {
  case screen(String, Double, Double, String, NSColor)
}
struct Beat { let moment: Moment; let seconds: Double }

// The full-page captures receive the longest dwell, with an intentional slow
// scroll from the agent claim to the repository evidence.
let beats: [Beat] = [
  Beat(moment: .screen("assets/demo-live-input.png", 0, 0, "AGENT REPORT", teal), seconds: 10),
  Beat(moment: .screen("assets/demo-live-fix-full-receipt.png", 0.02, 0.88, "RECEIPT · FIX", brick), seconds: 19),
  Beat(moment: .screen("assets/demo-live-escalate-proof.png", 0.03, 0.82, "RECEIPT · ESCALATE", brick), seconds: 18),
  Beat(moment: .screen("assets/demo-live-fix-proof.png", 0.08, 0.90, "EVIDENCE TRAIL", teal), seconds: 18),
  Beat(moment: .screen("assets/demo-live-ledger.png", 0.02, 0.78, "VERIFICATION LEDGER", teal), seconds: 15),
  Beat(moment: .screen("assets/demo-live-patterns.png", 0, 0, "RECURRING PATTERNS", teal), seconds: 10)
]

func label(_ value: String, _ size: CGFloat, _ color: NSColor, _ weight: NSFont.Weight = .regular) -> NSAttributedString {
  NSAttributedString(string: value, attributes: [.font: NSFont.systemFont(ofSize: size, weight: weight), .foregroundColor: color])
}

func graphics(_ context: CGContext, _ draw: () -> Void) {
  NSGraphicsContext.saveGraphicsState()
  NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
  draw()
  NSGraphicsContext.restoreGraphicsState()
}

func smooth(_ x: Double) -> CGFloat {
  let v = max(0, min(1, x))
  return CGFloat(v * v * (3 - 2 * v))
}

func backdrop(_ context: CGContext, progress: Double) {
  context.setFillColor(paper.cgColor)
  context.fill(CGRect(x: 0, y: 0, width: width, height: height))
  graphics(context) {
    label("receipts.", 25, teal, .bold).draw(at: NSPoint(x: 100, y: 1016))
    label("PRODUCT WALKTHROUGH", 13, NSColor(calibratedWhite: 0.48, alpha: 1), .medium).draw(at: NSPoint(x: 244, y: 1022))
  }
}

func drawCursor(_ point: NSPoint, pulse: Double, in context: CGContext) {
  let scale = CGFloat(0.92 + 0.08 * sin(pulse * .pi * 2))
  context.saveGState(); context.translateBy(x: point.x, y: point.y); context.scaleBy(x: scale, y: scale)
  context.setShadow(offset: CGSize(width: 3, height: -3), blur: 5, color: NSColor.black.withAlphaComponent(0.18).cgColor)
  context.setFillColor(NSColor.white.cgColor); context.setStrokeColor(ink.cgColor); context.setLineWidth(3)
  context.move(to: .zero); context.addLine(to: CGPoint(x: 0, y: 48)); context.addLine(to: CGPoint(x: 13, y: 35)); context.addLine(to: CGPoint(x: 26, y: 61)); context.addLine(to: CGPoint(x: 38, y: 55)); context.addLine(to: CGPoint(x: 25, y: 29)); context.addLine(to: CGPoint(x: 45, y: 28)); context.closePath(); context.drawPath(using: .fillStroke)
  context.restoreGState()
}

func drawScreen(_ path: String, from: Double, to: Double, section: String, accent: NSColor, progress: Double, in context: CGContext) {
  guard let image = NSImage(contentsOf: root.appendingPathComponent(path)), let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return }
  let viewport = CGRect(x: 100, y: 80, width: 1720, height: 900)
  let viewAspect = viewport.width / viewport.height
  let cropHeight = min(CGFloat(cg.height), CGFloat(cg.width) / viewAspect)
  let startY = CGFloat(cg.height) - cropHeight - CGFloat(from) * (CGFloat(cg.height) - cropHeight)
  let endY = CGFloat(cg.height) - cropHeight - CGFloat(to) * (CGFloat(cg.height) - cropHeight)
  let y = startY + (endY - startY) * smooth(progress)
  let source = CGRect(x: 0, y: y, width: CGFloat(cg.width), height: cropHeight)
  context.saveGState()
  context.setShadow(offset: CGSize(width: 0, height: -16), blur: 35, color: NSColor.black.withAlphaComponent(0.12).cgColor)
  context.setFillColor(NSColor.white.cgColor); context.fill(viewport)
  context.setShadow(offset: .zero, blur: 0, color: nil); context.saveGState(); context.clip(to: viewport); context.draw(cg, in: viewport, byTiling: false); // establishes correct color space
  // Draw the crop after clipping; Core Graphics source cropping maintains a live browser viewport feel.
  if let cropped = cg.cropping(to: source) { context.draw(cropped, in: viewport) }
  context.restoreGState(); context.setStrokeColor(border.cgColor); context.setLineWidth(2); context.stroke(viewport); context.restoreGState()
  graphics(context) { label(section, 13, accent, .bold).draw(at: NSPoint(x: 100, y: 993)) }
  context.setFillColor(accent.cgColor); context.fill(CGRect(x: 100, y: 61, width: 1720 * smooth(progress), height: 3))
  if to != from { drawCursor(NSPoint(x: 1745, y: 500 - 300 * smooth(progress)), pulse: progress, in: context) }
}

func render(_ beat: Beat, progress: Double, in context: CGContext) {
  backdrop(context, progress: progress)
  switch beat.moment { case let .screen(path, from, to, section, accent): drawScreen(path, from: from, to: to, section: section, accent: accent, progress: progress, in: context) }
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
input.markAsFinished(); let written = DispatchSemaphore(value: 0); writer.finishWriting { written.signal() }; written.wait()
try? FileManager.default.removeItem(at: finalURL)
try FileManager.default.moveItem(at: intermediate, to: finalURL)
print(finalURL.path)
