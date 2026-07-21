import AVFoundation
import Foundation

// Preserve the existing visual track and replace only its audio track.
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let sourceURL = root.appendingPathComponent("assets/receipts-live-scroll-narrated-demo.mp4")
let audioURL = root.appendingPathComponent("assets/receipts-live-scroll-voiceover.aiff")
let outputURL = root.appendingPathComponent("assets/receipts-live-scroll-narrated-demo-replacement.mp4")

let source = AVURLAsset(url: sourceURL)
let narration = AVURLAsset(url: audioURL)
guard let sourceVideo = source.tracks(withMediaType: .video).first else { fatalError("The source video track is unavailable.") }
guard let sourceAudio = narration.tracks(withMediaType: .audio).first else { fatalError("The replacement audio track is unavailable.") }

let composition = AVMutableComposition()
let video = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)!
video.preferredTransform = sourceVideo.preferredTransform
try video.insertTimeRange(CMTimeRange(start: .zero, duration: source.duration), of: sourceVideo, at: .zero)
let audio = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)!
try audio.insertTimeRange(CMTimeRange(start: .zero, duration: min(narration.duration, source.duration)), of: sourceAudio, at: .zero)

try? FileManager.default.removeItem(at: outputURL)
let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality)!
exporter.outputURL = outputURL
exporter.outputFileType = .mp4
let completed = DispatchSemaphore(value: 0)
exporter.exportAsynchronously { completed.signal() }
completed.wait()
guard exporter.status == .completed else { fatalError(exporter.error?.localizedDescription ?? "Audio replacement export failed.") }
print(outputURL.path)
