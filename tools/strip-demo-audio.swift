import AVFoundation
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let source = root.appendingPathComponent("assets/receipts-live-scroll-narrated-demo.mp4")
let output = root.appendingPathComponent("assets/receipts-live-scroll-narrated-demo-silent.mp4")
let asset = AVURLAsset(url: source)
let composition = AVMutableComposition()
guard let sourceTrack = asset.tracks(withMediaType: .video).first else { fatalError("Source video track is unavailable") }
let destinationTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)!
try destinationTrack.insertTimeRange(CMTimeRange(start: .zero, duration: asset.duration), of: sourceTrack, at: .zero)
try? FileManager.default.removeItem(at: output)
let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetPassthrough)!
exporter.outputURL = output
exporter.outputFileType = .mp4
exporter.shouldOptimizeForNetworkUse = true
let completed = DispatchSemaphore(value: 0)
exporter.exportAsynchronously { completed.signal() }
completed.wait()
guard exporter.status == .completed else { fatalError(exporter.error?.localizedDescription ?? "Audio-strip export failed") }
print(output.path)
