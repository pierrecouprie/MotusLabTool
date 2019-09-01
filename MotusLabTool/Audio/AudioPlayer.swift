//
//  AudioPlayer.swift
//  MotusLabTool
//
//  Created by Pierre Couprie on 01/09/2019.
//  Copyright © 2019 Pierre Couprie. All rights reserved.
//

import Foundation
import AVFoundation

class AudioPlayer: NSObject, AVAudioPlayerDelegate {
    
    weak var leftViewController: LeftViewController!
    var audioPlayer: AVAudioPlayer!
    
    var timePosition: Double {
        if let audioPlayer = self.audioPlayer {
            return audioPlayer.currentTime
        }
        return 0
    }
    
    var meterValue: (left: Float, right: Float) {
        if let audioPlayer = self.audioPlayer {
            audioPlayer.updateMeters()
            return (audioPlayer.averagePower(forChannel: 0), audioPlayer.averagePower(forChannel: 1))
        }
        return (-160,-160)
    }
    
    init(_ leftViewController: LeftViewController) {
        super.init()
        self.leftViewController = leftViewController
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        self.leftViewController.endOfPlayback()
    }
    
    func createAudioPlayer(_ url: URL) {
        
        do {
            self.audioPlayer = try AVAudioPlayer(contentsOf: url)
            self.audioPlayer.delegate = self
            self.audioPlayer.isMeteringEnabled = true
        } catch let error as NSError {
            Swift.print("AudioPlayer: createAudioPlayer() Creation of AVAudioPlayer failed, context: " + error.localizedDescription)
        }
    }

    func startPlaying() {
        audioPlayer?.play()
    }
    
    func pausePlaying() {
        audioPlayer?.pause()
    }
    
    func stopPlaying() {
        audioPlayer?.stop()
    }
    
}
