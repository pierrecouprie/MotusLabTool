//
//  AddMarkerPopoverViewController.swift
//  MotusLabTool
//
//  Created by Pierre Couprie on 31/08/2019.
//  Copyright © 2019 Pierre Couprie. All rights reserved.
//

import Cocoa

class AddMarkerPopoverViewController: NSViewController {
    
    weak var motusLabFile: MotusLabFile!
    var timePosition: Float = 0
    
    @IBOutlet weak var dateTextField: NSTextField!
    @IBOutlet weak var titleTextField: NSTextField!
    
    func createMarker(_ motusLabFile: MotusLabFile, timePosition: Float) {
        self.motusLabFile = motusLabFile
        self.timePosition = timePosition
    }
    
    override func viewDidLoad() {
        self.titleTextField.stringValue = "Untitled"
        self.dateTextField.stringValue = self.timePosition.floatToTime()
    }
    
    @IBAction func cancel(_ sender: Any) {
        self.dismiss(sender)
    }
    
    @IBAction func save(_ sender: Any) {
        self.dismiss(sender)
        if let lastSession = self.motusLabFile.sessions.last {
            let marker = Marker(title: self.titleTextField.stringValue,
                                date: self.timePosition)
            lastSession.addMarker(marker)
        }
    }
    
}

