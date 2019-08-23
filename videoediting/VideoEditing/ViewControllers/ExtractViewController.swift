//
//  ExtractViewController.swift
//  VideoEditing
//
//  Created by jaba odishelashvili on 6/2/18.
//  Copyright © 2018 Jabson. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit
import MobileCoreServices

class ExtractViewController: UIViewController {
    var audioPlayer: AVPlayer?
    
    // MARK: - ViewController Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: - User Interface Methods
    @IBAction func playOriginalVideo(_ sender: Any) {
        guard let videoPath = Bundle.main.path(forResource: "FullVideo", ofType: "MOV") else { return }
        
        let videoURL = URL(fileURLWithPath: videoPath)
        let player = AVPlayer(url: videoURL)
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        self.present(playerViewController, animated: true) {
            playerViewController.player!.play()
        }
    }
    
    @IBAction func extractVideoAndPlay(_ sender: Any) {
        guard let videoPath = Bundle.main.path(forResource: "FullVideo", ofType: "MOV") else { return }
        let videoURL = URL(fileURLWithPath: videoPath)
        
        VideoManager.shared().removeAudioFromVideo(url: videoURL) { (url, error) in
            if let url = url {
                let player = AVPlayer(url: url)
                let playerViewController = AVPlayerViewController()
                playerViewController.player = player
                self.present(playerViewController, animated: true) {
                    playerViewController.player!.play()
                }
            }
        }
    }
    
    @IBAction func extractAudioAndPlay(_ sender: Any) {
        guard let videoPath = Bundle.main.path(forResource: "FullVideo", ofType: "MOV") else { return }
        let videoURL = URL(fileURLWithPath: videoPath)
        
        
        VideoManager.shared().extractAudioFromVideo(url: videoURL) { [weak self] (url, error) in
            if let url = url {
                self?.audioPlayer = AVPlayer(url: url)
                self?.audioPlayer?.play()
            }
        }
    }
    
    @IBAction func openLibrary(_ sender: Any) {
        let imagePickerController = UIImagePickerController()
        imagePickerController.sourceType = .photoLibrary
        imagePickerController.delegate = self
        imagePickerController.mediaTypes = [kUTTypeMovie as String]
        present(imagePickerController, animated: true, completion: nil)
    }
}

extension ExtractViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        self.dismiss(animated: true, completion: nil)
        guard let url = info[UIImagePickerControllerMediaURL] as? URL else { return }
        
        // you can use this url to pass VideoManager functions
        //for example: to extract audio
        /*
        VideoManager.shared().extractAudioFromVideo(url: url) { [weak self] (url, error) in
            if let url = url {
                self?.audioPlayer = AVPlayer(url: url)
                self?.audioPlayer?.play()
            }
        }
         */
        
        
        //or for merge this video to another audio
        /*
        let audioURL = //here is your audio url
        let watermark = Watermark(animableWatermark: nil, textWatermark: nil)
        VideoManager.shared().merge(videoURL: url, audioURL: audioURL, watermark: watermark) { (url, error) in
            if let url = url {
                let player = AVPlayer(url: url)
                let playerViewController = AVPlayerViewController()
                playerViewController.player = player
                self.present(playerViewController, animated: true) {
                    playerViewController.player!.play()
                }
            }
        }
        */
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: nil)
    }
}
