//
//  RecordCameraViewController.swift
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

import Cocoa

class RecordCameraViewController: NSViewController {
    
    weak var leftViewController: LeftViewController!
    
    @objc dynamic var videoDevices: [VideoDevice]!
    
    var name: String!
    @objc dynamic var cameraDevice: String! {
        didSet {
            if let cameraDevice = self.cameraDevice, let videoRecorder = self.leftViewController.videoRecorder, let name = self.name {
                videoRecorder.initializeVideoCamera(name, deviceId: cameraDevice, previewView: self.preview)
            } else if let videoRecorder = self.leftViewController.videoRecorder {
                videoRecorder.removeInputConnection(oldValue)
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
