//
//  VideoManager.swift
//  VideoEditing
//
//  Created by jaba odishelashvili on 6/2/18.
//  Copyright © 2018 Jabson. All rights reserved.
//

import AVFoundation
import UIKit

class VideoManager: NSObject {
    // MARK: - Properties
    private static var sharedInstance: VideoManager = {
        let networkManager = VideoManager()
        return networkManager
    }()
    
    // MARK: - Accessors
    class func shared() -> VideoManager {
        return sharedInstance
    }

    // MARK: - User Interface Methods
    func extractAudioFromVideo(url: URL, completion: @escaping (URL?, Error?) -> ()) {
        guard let asset = try? AVAsset(url: url).asset(of: .audio) else {
            completion(nil, nil)
            return
        }
        
        let url = urlFromCacheDirectory(for: .audio)
        //we can't save asset at the url if file already exist, so remove it
        removeFile(from: url)
            
        //saving...
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
            completion(nil, nil)
            return
        }
        
        exportSession.outputFileType = .m4a
        exportSession.outputURL  = url
        exportSession.shouldOptimizeForNetworkUse = true
        
        exportSession.exportAsynchronously {
            switch exportSession.status {
            case .completed:
                DispatchQueue.main.async {
                    completion(exportSession.outputURL, exportSession.error)
                }
            case .failed, .cancelled:
                completion(nil, exportSession.error)
            default:
                break
            }
        }
    }
    
    func removeAudioFromVideo(url: URL, completion: @escaping (URL?, Error?) -> ()) {
        guard let asset = try? AVAsset(url: url).asset(of: .video) else {
            completion(nil, nil)
            return
        }
        
        let url = urlFromCacheDirectory(for: .video)
        //we can't save asset at the url if file already exist, so remove it
        removeFile(from: url)
            
        //saving...
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetMediumQuality) else {
            completion(nil, nil)
            return
        }
        
        exportSession.outputFileType = .mp4 
        exportSession.outputURL = url
        exportSession.shouldOptimizeForNetworkUse = true
        
        exportSession.exportAsynchronously {
            switch exportSession.status {
            case .completed:
                DispatchQueue.main.async {
                    completion(exportSession.outputURL, exportSession.error)
                }
            case .failed, .cancelled:
                completion(nil, exportSession.error)
            default:
                break
            }
        }
    }
    
    func merge(videoURL: URL, audioURL: URL, watermark: Watermark, completion: @escaping (URL?, Error?) -> ()) {
        // create video & audio assets
        let videoAsset = AVURLAsset(url: videoURL)
        let audioAsset = AVURLAsset(url: audioURL)
        
        //get track from video asset
        guard let videoAssetTrack = videoAsset.tracks(withMediaType: .video).first else {
            print("Can't get video asset track")
            completion(nil, nil)
            return
        }
        
        //get track from audio asset
        guard let audioAssetTrack = audioAsset.tracks(withMediaType: .audio).first else {
            print("Can't get audio asset track")
            completion(nil, nil)
            return
        }
        
        //create main composition and add video and audio track
        let composition = AVMutableComposition()
        guard let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            print("Can't add video track")
            completion(nil, nil)
            return
        }
        guard let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            print("Can't add audio track")
            completion(nil, nil)
            return
        }
        
        //inserts time ranges for tracks
        do {
            try videoTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, videoAsset.duration),
                                           of: videoAssetTrack, at: kCMTimeZero)
            try audioTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, audioAsset.duration),
                                           of: audioAssetTrack, at: kCMTimeZero)
        } catch {
            completion(nil, error)
            return
        }
        
        
        videoTrack.preferredTransform = videoAssetTrack.preferredTransform
        let videoSize = videoAssetTrack.naturalSize.applying(videoTrack.preferredTransform).abs()
        
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
        layerInstruction.setTransform(videoAssetTrack.preferredTransform, at: kCMTimeZero)
        
        let videoCompositionInstruction = AVMutableVideoCompositionInstruction()
        videoCompositionInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, max(videoAsset.duration, audioAsset.duration))
        videoCompositionInstruction.layerInstructions = [layerInstruction]

        
        let videoComposition = AVMutableVideoComposition()
        addWatermark(watermark: watermark, to: videoComposition,
                     videoSize: videoSize, videoDuration: CMTimeGetSeconds(videoAsset.duration))
        videoComposition.instructions = [videoCompositionInstruction]
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        videoComposition.renderSize = videoSize

        
        let url = urlFromCacheDirectory(for: .video)
        removeFile(from: url)
        
        //saving...
        guard  let exportSession = SDAVAssetExportSession(asset: composition) else {
            print("Can't create exportSession")
            return
        }
        
        exportSession.outputFileType = "public.mpeg-4"
        exportSession.outputURL = url
        exportSession.videoComposition = videoComposition
        
        exportSession.videoSettings = [
            AVVideoCodecKey: AVVideoCodecH264,
            AVVideoWidthKey: 1080,
            AVVideoHeightKey: 1920,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: 6000000,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264High40
            ]
        ]
        
        exportSession.audioSettings = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVNumberOfChannelsKey: 2,
            AVSampleRateKey: 44100,
            AVEncoderBitRateKey: 128000,
        ]
        
        exportSession.exportAsynchronously {
            switch exportSession.status {
            case .completed:
                DispatchQueue.main.async {
                    completion(exportSession.outputURL, exportSession.error)
                }
            case .cancelled, .failed:
                print(exportSession.error)
                completion(nil, exportSession.error)
            default: break
            }
        }

        
//        exportSession.outputURL = url
//        exportSession.outputFileType = .mov
//        exportSession.shouldOptimizeForNetworkUse = false
//        exportSession.videoComposition = videoComposition;
//
//        exportSession.exportAsynchronously {
//            switch exportSession.status {
//            case .completed:
//                DispatchQueue.main.async {
//                    completion(exportSession.outputURL, exportSession.error)
//                }
//            case .cancelled, .failed:
//                print(exportSession.error)
//                completion(nil, exportSession.error)
//            default: break
//            }
//        }
    }
    
    private func addWatermark(watermark: Watermark,
                              to videoComposition: AVMutableVideoComposition,
                              videoSize: CGSize, videoDuration: Double) {
        //create overlay for text and animable images
        let overlayLayer = CALayer()
        overlayLayer.frame = CGRect(x: 0, y: 0, width: videoSize.width, height: videoSize.height)
        overlayLayer.masksToBounds = true
        
        //add text watermark if exist
        if let textWatermark = watermark.textWatermark {
            let text = textWatermark.string
            let font = textWatermark.font
            let color = textWatermark.color.cgColor
            let bgColor = textWatermark.bgColor.cgColor
            let position = CGPoint(x: videoSize.width * textWatermark.position.x,
                                   y: videoSize.height * textWatermark.position.y)
            let size = CGSize(width: text.width(withConstrainedHeight: videoSize.height, font: font),
                              height: text.height(withConstrainedWidth: videoSize.width, font: font))
            let opacity = textWatermark.opacity
            let shadowOpacity = textWatermark.shadowOpacity
            let shadowOffset = textWatermark.shadowOffset
            let shadowColor = textWatermark.shadowColor.cgColor
            let animation = textWatermark.animation
            let animationDuration = textWatermark.animationDuration
            
            let textLayer = CATextLayer()
            textLayer.font = font.fontName as CFTypeRef
            textLayer.fontSize = font.pointSize
            textLayer.frame = CGRect(origin: position, size: size)
            textLayer.position = position
            textLayer.string = text
            textLayer.alignmentMode = kCAAlignmentCenter
            textLayer.foregroundColor = color
            textLayer.backgroundColor = bgColor
            textLayer.opacity = opacity
            textLayer.shadowOpacity = shadowOpacity
            textLayer.shadowOffset = shadowOffset
            textLayer.shadowColor = shadowColor
            textLayer.setNeedsDisplay()
            
            if animation == .Fade {
                let fadeInAndOut = CAKeyframeAnimation(keyPath: "opacity")
                fadeInAndOut.duration = videoDuration
                fadeInAndOut.autoreverses = false
                fadeInAndOut.beginTime = 0.01
                fadeInAndOut.keyTimes = [0, animationDuration/videoDuration, (videoDuration-animationDuration)/videoDuration, 1] as [NSNumber]
                fadeInAndOut.values = [0, 1, 1, 0] as [NSNumber]
                fadeInAndOut.isRemovedOnCompletion = false
                fadeInAndOut.fillMode = kCAFillModeBoth
                textLayer.add(fadeInAndOut, forKey: nil)
            } else if animation == .Move {
                textLayer.position = CGPoint(x: position.x, y: videoSize.height + size.height)
                let moveFromPosition = NSValue(cgPoint: textLayer.position)
                let moveToPosition = NSValue(cgPoint: position)

                let moveDownAnim = CASpringAnimation(keyPath: "position")
                moveDownAnim.duration = videoDuration
                moveDownAnim.autoreverses = false
                moveDownAnim.beginTime = 0.01
                moveDownAnim.fromValue = moveFromPosition
                moveDownAnim.toValue = moveToPosition
                moveDownAnim.isRemovedOnCompletion = false
                
                let moveUpAnim = CASpringAnimation(keyPath: "position")
                moveUpAnim.duration = videoDuration
                moveUpAnim.autoreverses = false
                moveUpAnim.beginTime = videoDuration - animationDuration
                moveUpAnim.fromValue = moveToPosition
                moveUpAnim.toValue = moveFromPosition
                moveUpAnim.isRemovedOnCompletion = false
                
                let group = CAAnimationGroup()
                group.beginTime = 0.01
                group.duration = videoDuration //videoDuration
                group.animations = [moveDownAnim, moveUpAnim]
                group.isRemovedOnCompletion = false
                group.fillMode = kCAFillModeBoth
                textLayer.add(group, forKey: nil)
            }
            
            overlayLayer.addSublayer(textLayer)
        }
        
        //add animable watermark if exist
        if let animableWatermark = watermark.animableWatermark {
            var images: [CGImage] = []
            for image in animableWatermark.images {
                if let cgImage = image.cgImage {
                    images.append(cgImage)
                }
            }
            let duration = animableWatermark.duration
            let position = CGPoint(x: videoSize.width * animableWatermark.position.x,
                                   y: videoSize.height * animableWatermark.position.y)
            let repeatCount = animableWatermark.repeatCount
            
            
            let animation = CAKeyframeAnimation(keyPath: "contents")
            animation.calculationMode = kCAAnimationLinear
            animation.autoreverses = false
            animation.duration = duration
            animation.values = images
            animation.beginTime = AVCoreAnimationBeginTimeAtZero
            animation.isRemovedOnCompletion = false
            animation.fillMode = kCAFillModeForwards
            animation.repeatCount = repeatCount
            
            let animationLayer = CALayer()
            animationLayer.add(animation, forKey: "contents")
            if let size = animableWatermark.images.first?.size {
                animationLayer.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            }
            animationLayer.position = position
            overlayLayer.addSublayer(animationLayer)
        }
        
        let parentLayer = CALayer()
        let videoLayer = CALayer()
        parentLayer.frame = CGRect(x: 0, y: 0, width: videoSize.width, height: videoSize.height)
        videoLayer.frame = CGRect(x: 0, y: 0, width: videoSize.width, height: videoSize.height)
        parentLayer.addSublayer(videoLayer)
        parentLayer.addSublayer(overlayLayer)
        
        videoComposition.animationTool = AVVideoCompositionCoreAnimationTool.init(postProcessingAsVideoLayer: videoLayer, in: parentLayer)
    }
    
    // MARK: - private methods
    private func urlFromCacheDirectory(for mediaType: AVMediaType) -> URL {
        let cacheDirectory = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]
        let fileName = mediaType == .audio ? "audio.m4a" : "video.mp4"
        let filePath = cacheDirectory + "/" + fileName
        
        return URL(fileURLWithPath: filePath)
    }
    
    private func removeFile(from url: URL) {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: url.path) {
            try? fileManager.removeItem(at: url)
        }
    }
}

extension AVAsset {
    func asset(of type: AVMediaType) throws -> AVAsset {
        let composition = AVMutableComposition()
        let tracks      = self.tracks(withMediaType: type)
        
        for track in tracks {
            let compositionTrack = composition.addMutableTrack(withMediaType: type, preferredTrackID: kCMPersistentTrackID_Invalid)
            try compositionTrack?.insertTimeRange(track.timeRange, of: track, at: track.timeRange.start)
            compositionTrack?.preferredTransform = track.preferredTransform
        }
        
        return composition
    }
}

extension CGSize {
    func abs() -> CGSize {
        return CGSize(width: fabs(width), height: fabs(height))
    }
}

extension String {
    func height(withConstrainedWidth width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect,
                                            options: .usesLineFragmentOrigin,
                                            attributes: [.font : font], context: nil)
        
        return ceil(boundingBox.height)
    }
    
    func width(withConstrainedHeight height: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = self.boundingRect(with: constraintRect,
                                            options: .usesLineFragmentOrigin,
                                            attributes: [.font : font], context: nil)
        
        return ceil(boundingBox.width)
    }
}
