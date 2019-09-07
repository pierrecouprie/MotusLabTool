//
//  AddMarkerPopoverViewController.swift
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

