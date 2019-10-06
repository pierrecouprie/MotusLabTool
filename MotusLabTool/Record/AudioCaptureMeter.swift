//
//  AudioCaptureMeter.swift
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

class AudioCaptureMeter: NSObject, AVCaptureAudioDataOutputSampleBufferDelegate {
    
    var session: AVCaptureSession!
    
    //var meterLevels: (left: Float, right: Float) = (-100,-100) //From -100 to +6 dB
    
    var meterLevels: [Float]!
    
    override init() {
        super.init()
        
        let meterCount = UserDefaults.standard.integer(forKey: PreferenceKey.channelNumber)
        self.meterLevels = [Float](repeating: -100, count: meterCount)
        
        // Open session
        self.session = AVCaptureSession()
        
        // Create connection from default audio input selected in sound system preferences to preview
        if let audioDevice = AVCaptureDevice.default(for: AVMediaType.audio) {
            do {
                let audioInput = try AVCaptureDeviceInput(device: audioDevice)
                self.session.addInput(audioInput)
                
                let output = AVCaptureAudioDataOutput()
                output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "com.motusLabRecorder.audioMeterQueue"))
                self.session.addOutput(output)
                self.session.startRunning()
                
            } catch let error as NSError {
                Swift.print("AudioCaptureMeter: init() Error create capture device " + error.localizedDescription)
            }
        } else {
             Swift.print("AudioCaptureMeter: init() Error get default device")
        }
        
    }
    
    // Capture frame of audio input
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if connection.audioChannels.count > 1 {
            for index in 0..<self.meterLevels.count {
                let channel: AVCaptureAudioChannel = connection.audioChannels[index]
                self.meterLevels[index] = channel.averagePowerLevel
            }
            /*let channel1: AVCaptureAudioChannel = connection.audioChannels[0]
            let channel2: AVCaptureAudioChannel = connection.audioChannels[1]
            meterLevels = (channel1.averagePowerLevel, channel2.averagePowerLevel)*/
        }
        
    }
    
}
