//
//  AudioCaptureMeter.swift
//  MotusLabTool
//
//  Created by Pierre Couprie on 01/09/2019.
//  Copyright © 2019 Pierre Couprie. All rights reserved.
//

import Foundation
import AVFoundation

class AudioCaptureMeter: NSObject, AVCaptureAudioDataOutputSampleBufferDelegate {
    
    var session: AVCaptureSession!
    
    var meterLevels: (left: Float, right: Float) = (-100,-100) //From -100 to +6 dB
    
    override init() {
        super.init()
        
        self.session = AVCaptureSession()
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
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if connection.audioChannels.count > 1 {
            let channel1: AVCaptureAudioChannel = connection.audioChannels[0]
            let channel2: AVCaptureAudioChannel = connection.audioChannels[1]
            meterLevels = (channel1.averagePowerLevel, channel2.averagePowerLevel)
        }
        
    }
    
}
