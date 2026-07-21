import AVFoundation
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let videoURL = root.appendingPathComponent("assets/receipts-live-scroll-render.mp4")
let audioURL = root.appendingPathComponent("assets/receipts-live-scroll-voiceover.aiff")
let outputURL = root.appendingPathComponent("assets/receipts-live-scroll-narrated-demo.mp4")

let video = AVURLAsset(url: videoURL)
let audio = AVURLAsset(url: audioURL)
let composition = AVMutableComposition()
let videoTrack = video.tracks(withMediaType: .video).first!
let composedVideo = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)!
try composedVideo.insertTimeRange(CMTimeRange(start: .zero, duration: video.duration), of: videoTrack, at: .zero)
if let audioTrack = audio.tracks(withMediaType: .audio).first {
  let composedAudio = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)!
  try composedAudio.insertTimeRange(CMTimeRange(start: .zero, duration: min(audio.duration, video.duration)), of: audioTrack, at: .zero)
}
try? FileManager.default.removeItem(at: outputURL)
let export = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality)!
export.outputURL = outputURL
export.outputFileType = .mp4
let done = DispatchSemaphore(value: 0)
export.exportAsynchronously { done.signal() }
done.wait()
guard export.status == .completed else { fatalError(export.error?.localizedDescription ?? "Could not export video") }
print(outputURL.path)
