//
//  VideoRecorder.swift
//  MotusLabTool
//
//  Created by Pierre Couprie on 01/09/2019.
//  Copyright © 2019 Pierre Couprie. All rights reserved.
//

import Cocoa
import AVFoundation

struct VideoSize {
    static let vga640x480 = "vga640x480"
    static let qHD960x540 = "qHD960x540"
    static let hd1280x720 = "hd1280x720"
    
    static func presetFrom(tag: Int) -> String {
        switch tag {
        case 0:
            return VideoSize.vga640x480
        case 1:
            return VideoSize.qHD960x540
        default:
            break
        }
        return VideoSize.hd1280x720
    }
    
    static func sizeFromTag(tag: Int) -> (width: Float, height: Float) {
        switch tag {
        case 0:
            return (640,480)
        case 1:
            return (960,540)
        default:
            break
        }
        return (1280,720)
    }
    
}

/// used to save name and id of input video devices
@objcMembers
class VideoDevice : NSObject {
    var name: String;
    var id: String;
    
    init(name: String, id: String) {
        self.name = name;
        self.id = id;
    }
}

/// Get input video devices
///
/// - Returns: Array of devices
func VideoCaptureDeviceList() -> [VideoDevice] {
    var videoDevices = [VideoDevice]()
    let devices = AVCaptureDevice.devices()
    for device in devices {
        if device.hasMediaType(AVMediaType.video) {
            let newDevice = VideoDevice(name: device.localizedName, id: device.uniqueID)
            videoDevices.append(newDevice)
        }
    }
    return videoDevices
}

class VideoRecorder: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    weak var leftViewController: LeftViewController!
    let preferences = UserDefaults.standard
    let captureSession = AVCaptureSession()
    let videoQueue = DispatchQueue(label: "com.motusLabRecorder.videoQueue")
    var presetTag: Int = 1
    var videoSize = VideoSize.sizeFromTag(tag: 1)
    
    var cameras = [String: (name: String, connection: AVCaptureConnection, captureInput: AVCaptureDeviceInput, captureOutput: AVCaptureConnection, assetWritter: AVAssetWriter?, assetWritterInput: AVAssetWriterInput?)]()
    
    init(leftViewController: LeftViewController) {
        super.init()
        self.leftViewController = leftViewController
        
        //Configure capture session
        self.captureSession.sessionPreset = .high
    }
    
    /// Remove an input video device and its connexions
    ///
    /// - Parameter deviceId: The id of device
    func removeInputConnection(_ deviceId: String) {
        if let camera = self.cameras[deviceId] {
            self.captureSession.removeConnection(camera.connection)
            
            for input in self.captureSession.inputs {
                if input == camera.captureInput {
                    self.captureSession.removeInput(input)
                    break
                }
            }
            for output in self.captureSession.outputs {
                if output == camera.captureOutput {
                    self.captureSession.removeOutput(output)
                    break
                }
            }
        }
    }
    
    /// Add a new input video device
    ///
    /// - Parameters:
    ///   - name: Camera item ("-A","-B","-C", or "-D"), used to create name of saved video file
    ///   - deviceId: device id
    ///   - previewView: View used to render the image of camera
    func initializeVideoCamera(_ name: String, deviceId: String, previewView: NSView) {
        
        if let device = AVCaptureDevice(uniqueID: deviceId) {
            do {
                let avCaptureInput = try AVCaptureDeviceInput(device: device)
                
                //Clean previous input, output and connexions
                self.removeInputConnection(deviceId)
                
                //Add input
                let videoPort = self.videoPort(avCaptureDeviceInput: avCaptureInput)
                if self.captureSession.canAddInput(avCaptureInput) {
                    self.captureSession.addInputWithNoConnections(avCaptureInput)
                } else {
                    Swift.print("VideoRecorder: initializeVideoCamera Cannot add input (" + deviceId + ")!")
                }
                
                //Add output
                let captureDataOutput = AVCaptureVideoDataOutput()
                captureDataOutput.setSampleBufferDelegate(self, queue: self.videoQueue)
                if self.captureSession.canAddOutput(captureDataOutput) {
                    self.captureSession.addOutputWithNoConnections(captureDataOutput)
                } else {
                    Swift.print("VideoRecorder: initializeVideoTrack Cannot add output!")
                }
                
                //Add connexion
                let outputConnexion = AVCaptureConnection(inputPorts: videoPort, output: captureDataOutput)
                if self.captureSession.canAddConnection(outputConnexion) {
                    self.captureSession.addConnection(outputConnexion)
                } else {
                    Swift.print("VideoRecorder: initializeVideoCamera Cannot add connexion!")
                }
                
                //Save references for the recording
                self.cameras[deviceId] = (name: name, connection: outputConnexion, captureInput: avCaptureInput, captureOutput: outputConnexion, assetWritter: nil, assetWritterInput: nil)
                
                //Start capture session if it's not
                if !self.captureSession.isRunning {
                    self.captureSession.startRunning()
                }
                
                //Create preview layer for the rendering
                let previewLayer = AVCaptureVideoPreviewLayer(sessionWithNoConnection: self.captureSession)
                previewView.wantsLayer = true
                if let layer = previewView.layer {
                    if let sublayers = layer.sublayers, let firstSubLayer = sublayers.first {
                        firstSubLayer.removeFromSuperlayer()
                    }
                    layer.addSublayer(previewLayer)
                    previewLayer.frame = CGRect(x: 0, y: 0, width: previewView.frame.size.width, height: previewView.frame.size.height)
                    previewLayer.addInLayerContraints(superlayer: layer)
                    layer.layoutManager = CAConstraintLayoutManager()
                }
                let previewConnexion = AVCaptureConnection(inputPort: videoPort[0], videoPreviewLayer: previewLayer)
                if self.captureSession.canAddConnection(previewConnexion) {
                    self.captureSession.addConnection(previewConnexion)
                } else {
                    Swift.print("VideoRecorder: initializeVideoCamera Cannot add preview connexion!")
                }
                
            } catch let error as NSError {
                Swift.print("VideoRecorder: initializeVideoCamera Error loading device context: " + error.localizedDescription)
            }
            
        }
    }
    
    /// Initialize the video Asset when user start recording (create the file in disk)
    ///
    /// - Parameters:
    ///   - deviceId: id of device
    ///   - session: Session
    func initializeVideoAssetWriter(_ deviceId: String, session: Session) {
        let url = self.leftViewController.windowController.fileUrl.appendingPathComponent(FilePath.movie).appendingPathComponent(session.id + "-" + self.cameras[deviceId]!.name).appendingPathExtension(FileExtension.mp4)
        
        do {
            let assetWriter = try AVAssetWriter(outputURL: url, fileType: .mp4)
            
            let outputSettings = [AVVideoCodecKey : AVVideoCodecType.h264,
                                  AVVideoWidthKey : NSNumber(value: self.videoSize.width),
                                  AVVideoHeightKey : NSNumber(value: self.videoSize.height)] as [String : Any]
            
            if assetWriter.canApply(outputSettings: outputSettings, forMediaType: .video) {
                
                let avAssetWriterInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: outputSettings)
                avAssetWriterInput.expectsMediaDataInRealTime = true
                if assetWriter.canAdd(avAssetWriterInput) {
                    assetWriter.add(avAssetWriterInput)
                    
                    self.cameras[deviceId]!.assetWritter = assetWriter
                    self.cameras[deviceId]!.assetWritterInput = avAssetWriterInput
                    
                } else {
                    Swift.print("VideoRecorder: initializeVideoAssetWriter Error adding assetWriterInput!")
                }
            } else {
                Swift.print("VideoRecorder: initializeVideoAssetWriter Error applying output settings!")
            }
        } catch let error as NSError {
            Swift.print("VideoRecorder: initializeVideoAssetWriter Error initializing assetWritter: " + error.localizedDescription)
        }
    }
    
    /// Get video port of a device to create connexions
    func videoPort(avCaptureDeviceInput: AVCaptureDeviceInput) -> [AVCaptureDeviceInput.Port] {
        var result = [AVCaptureDeviceInput.Port]()
        for port in avCaptureDeviceInput.ports {
            if port.mediaType == AVMediaType.video {
                result.append(port)
            }
        }
        return result
    }
    
    /// Add sampleBuffer to files
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard CMSampleBufferDataIsReady(sampleBuffer) && self.leftViewController.windowController.currentMode == Mode.recording else {
            return
        }
        
        //Recording
        for camera in self.cameras.enumerated() {
            
            let properties = camera.element.value
            
            if properties.connection == connection {
                
                let presentationTime: CMTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                
                if properties.assetWritter!.status == .unknown {
                    if properties.assetWritter!.startWriting() {
                        properties.assetWritter!.startSession(atSourceTime: presentationTime)
                    } else {
                        Swift.print("VideoRecorder: captureOutput: Error writing initial buffer!")
                    }
                } else if properties.assetWritter!.status == .failed {
                    Swift.print("VideoRecorder: captureOutput: Error avAssetWritter = failed, description: \(properties.assetWritter!.error.debugDescription)")
                }
                
                if properties.assetWritter!.status == .writing {
                    if properties.assetWritterInput!.isReadyForMoreMediaData {
                        if !properties.assetWritterInput!.append(sampleBuffer) {
                            Swift.print("VideoRecorder: captureOutput: Error appending buffer!")
                        }
                    }
                }
                
                break
            }
        }
        
    }
    
    func stopRecording() {
        self.videoQueue.async {
            for camera in self.cameras.enumerated() {
                let properties = camera.element.value
                properties.assetWritter?.finishWriting { }
            }
        }
    }
    
}