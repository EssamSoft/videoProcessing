//
//  MergerViewController.swift
//  VideoEditing
//
//  Created by jaba odishelashvili on 6/2/18.
//  Copyright © 2018 Jabson. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit
import Photos

class MergerViewController: UIViewController {

    @IBOutlet var exportButton: UIButton!
    var mergedURL: URL?
    
    // MARK: - ViewController Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: - User Interface Methods
    @IBAction func mergeAndPlay(_ sender: Any) {
        //create video and audio url from bundle
        guard let videoPath = Bundle.main.path(forResource: "IMG_2417", ofType: "MOV") else { return }
        guard let audioPath = Bundle.main.path(forResource: "audio", ofType: "m4a") else { return }
        
        let videoURL = URL(fileURLWithPath: videoPath)
        let audioURL = URL(fileURLWithPath: audioPath)
        
        //create animable watermark
        var animableImages: [UIImage] = []
        let mainBundle = Bundle.main
        for i in 0...15 {
            guard let imagePath = mainBundle.path(forResource: "bird-\(i)", ofType: "png") else { continue }
            guard let image = UIImage(contentsOfFile: imagePath) else { continue }
            animableImages.append(image)
        }
        let animationDuration: Double = 1
        let animationPositionOnVideo = CGPoint(x: 0.5, y: 0.2) // from 0.0 to 1.0
        let animationRepeatCount: Float = Float.infinity
        let animableWatermark = AnimableWatermark(images: animableImages,
                                                  duration: animationDuration,
                                                  position: animationPositionOnVideo,
                                                  repeatCount: animationRepeatCount)
        
        //create text watermark
        let text = "Hello World"
        let font = UIFont(name: "Helvetica-Bold", size: 36)!
        let textColor = UIColor.white
        let bgColor = UIColor.clear
        let textPositionOnVideo = CGPoint(x: 0.5, y: 0.8) // from 0.0 to 1.0
        let opacity: Float = 0.8;
        let shadowOpacity: Float = 1.0
        let shadowOffset = CGSize(width: 1, height: -1)
        let shadowColor = UIColor.red
        let animation: TextWatermark.Animation = .Move //use .Fade for fade animation or .None to remove any animation
        
        //for text move animation
        let textWatermark = TextWatermark(string: text, font: font,
                                          color: textColor, bgColor: bgColor,
                                          position: textPositionOnVideo, opacity: opacity,
                                          shadowOpacity: shadowOpacity, shadowOffset: shadowOffset,
                                          shadowColor: shadowColor, animation: animation)
        
        
        //create watermark object which contains both, text and animable watermarks
        let watermark = Watermark(animableWatermark: animableWatermark,
                                  textWatermark: textWatermark)
        
        
        VideoManager.shared().merge(videoURL: videoURL, audioURL: audioURL, watermark: watermark) { (url, error) in
            if let url = url {
                self.mergedURL = url
                self.exportButton.isEnabled = true
                
                let player = AVPlayer(url: url)
                let playerViewController = AVPlayerViewController()
                playerViewController.player = player
                self.present(playerViewController, animated: true) {
                    playerViewController.player!.play()
                }
            }
        }
    }
    
    @IBAction func saveToLibrary(_ sender: Any) {
        guard let url = mergedURL else { return }
        let authorizationStatus = PHPhotoLibrary.authorizationStatus()

        switch authorizationStatus {
        case .denied:
            // show alert about not permission
            return
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization({ [weak self] newStatus in
                DispatchQueue.main.async {
                    if (newStatus == PHAuthorizationStatus.authorized) {
                        self?.saveToLibrary(sender)
                    } else {
                        // show alert about not permission
                    }
                }
            })
            return
        default: break
        }
        
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
        }) { saved, error in
            if saved {
                DispatchQueue.main.async {
                    //do whatever you want
                }
            }
        }
    }
}
