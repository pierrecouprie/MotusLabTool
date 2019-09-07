//
//  AudioRecorder.swift
//  MotusLabTool
//
//  Created by Pierre Couprie on 31/08/2019.
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

class AudioRecorder: NSObject, AVAudioRecorderDelegate {
    
    weak var leftViewController: LeftViewController!
    var recorder:AVAudioRecorder!
    var url: URL!
    var audioFormat: String!
    
    var timePosition: Double {
        if let recorder = self.recorder {
            return recorder.currentTime
        }
        return 0
    }
    
    init(_ url: URL, audioFormat: String, leftViewController: LeftViewController) {
        super.init()
        self.url = url
        self.audioFormat = audioFormat
        self.leftViewController = leftViewController
    }
    
    func createAudioRecorder() {
        
        guard self.leftViewController.currentSession != nil else {
            return
        }
        
        var settings: [String: Any]!
        var fileUrl: URL!
        let sessionId = self.leftViewController.currentSession.id
        
        if self.audioFormat == AudioFormat.aac {
            settings = [AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                        AVSampleRateKey: 44100,
                        AVNumberOfChannelsKey: 2,
                        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue]
            fileUrl = self.url.appendingPathComponent(sessionId!).appendingPathExtension(AudioFormat.aac)
            self.leftViewController.currentSession.audioFormat = AudioFormat.aac
        } else if self.audioFormat == AudioFormat.pcm {
            settings = [AVFormatIDKey: kAudioFormatLinearPCM,
                        AVSampleRateKey: 44100.0,
                        AVNumberOfChannelsKey: 2,
                        AVLinearPCMBitDepthKey: 16,
                        AVLinearPCMIsNonInterleaved: false,
                        AVLinearPCMIsBigEndianKey: false,
                        AVLinearPCMIsFloatKey: false]
            fileUrl = self.url.appendingPathComponent(sessionId!).appendingPathExtension(AudioFormat.pcm)
            self.leftViewController.currentSession.audioFormat = AudioFormat.pcm
        }
        
        do {
            recorder = try AVAudioRecorder(url: fileUrl, settings: settings)
            recorder?.delegate = self
            recorder?.isMeteringEnabled = true
            recorder?.prepareToRecord()
        } catch let error as NSError {
            Swift.print("AudioRecorder: createAudioRecorder() Creation of AVAudioRecorder failed, context: " + error.localizedDescription)
        }
    }
    
    
    func startRecord() {
        if let recorder = self.recorder {
            recorder.record()
        }
    }
    
    func stopRecord() {
        if let recorder = self.recorder {
            recorder.stop()
        }
    }
    
}
