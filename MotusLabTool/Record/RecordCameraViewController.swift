//
//  RecordCameraViewController.swift
//  MotusLabTool
//
//  Created by Pierre Couprie on 01/09/2019.
//  Copyright © 2019 Pierre Couprie. All rights reserved.
//

import Cocoa

class RecordCameraViewController: NSViewController {
    
    weak var leftViewController: LeftViewController!
    
    @objc dynamic var videoDevices: [VideoDevice]!
    
    var name: String!
    @objc dynamic var cameraDevice: String! {
        didSet {
            if let videoRecorder = self.leftViewController.videoRecorder, let name = self.name {
                videoRecorder.initializeVideoCamera(name, deviceId: self.cameraDevice, previewView: self.preview)
            }
        }
    }
    
    @IBOutlet weak var preview: RecordCameraView!
    
    init(nibName nibNameOrNil: NSNib.Name?, bundle nibBundleOrNil: Bundle?, leftViewController: LeftViewController, name: String) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        self.leftViewController = leftViewController
        self.name = name
        self.videoDevices = VideoCaptureDeviceList()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    @IBAction func removeCamera(_ sender: Any) {
        self.leftViewController.removeCamera(self.name)
    }
    
}
