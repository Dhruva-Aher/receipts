import AVFoundation
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let sources = [
  root.appendingPathComponent("assets/receipts-90-second-product-demo.mp4"),
  root.appendingPathComponent("assets/receipts-kinetic-product-demo.mp4")
]
let output = root.appendingPathComponent("assets/receipts-3-minute-hackathon-demo.mp4")
let composition = AVMutableComposition()
let destination = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)!
var cursor = CMTime.zero
let ninetySeconds = CMTime(seconds: 90, preferredTimescale: 600)

for source in sources {
  let asset = AVURLAsset(url: source)
  guard let track = asset.tracks(withMediaType: .video).first else { fatalError("Missing video track: \(source.lastPathComponent)") }
  let duration = min(asset.duration, ninetySeconds)
  try destination.insertTimeRange(CMTimeRange(start: .zero, duration: duration), of: track, at: cursor)
  cursor = CMTimeAdd(cursor, duration)
}

try? FileManager.default.removeItem(at: output)
let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality)!
exporter.outputURL = output
exporter.outputFileType = .mp4
let completed = DispatchSemaphore(value: 0)
exporter.exportAsynchronously { completed.signal() }
completed.wait()
guard exporter.status == .completed else { fatalError(exporter.error?.localizedDescription ?? "Composition export failed") }
print("\(output.path) · \(cursor.seconds) seconds")
