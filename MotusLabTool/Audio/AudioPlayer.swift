//
//  AudioPlayer.swift
//  MotusLabTool
//
//  Created by Pierre Couprie on 01/09/2019.
//  Copyright © 2019 Pierre Couprie. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import AVFoundation

class AudioPlayer: NSObject, AVAudioPlayerDelegate {
    
    weak var leftViewController: LeftViewController!
    var audioPlayer: AVAudioPlayer!
    var duration: Double! {
        if let audioPlayer = self.audioPlayer {
            return audioPlayer.duration
        }
        return nil
    }
    var timePosition: Double {
        if let audioPlayer = self.audioPlayer {
            return audioPlayer.currentTime
        }
        return 0
    }
    
    var meterValue: [Float] {
        if let audioPlayer = self.audioPlayer {
            audioPlayer.updateMeters()
            let numberOfChannels = audioPlayer.numberOfChannels
            var levels = [Float]()
            for index in 0..<numberOfChannels {
                levels.append(audioPlayer.averagePower(forChannel: index))
            }
            return levels
        }
        return [-160,-160]
    }
    
    init(_ leftViewController: LeftViewController) {
        super.init()
        self.leftViewController = leftViewController
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        self.leftViewController.endOfPlayback()
    }
    
    /// Initialize audio player from URL of sound file
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
