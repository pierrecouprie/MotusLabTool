//
//  MidiSettingsViewController.swift
//  MotusLabTool
//
//  Created by Pierre Couprie on 30/08/2019.
//  Copyright © 2019 Pierre Couprie. All rights reserved.
//

import Cocoa

class MidiSettingsViewController: NSViewController {
    
    @objc dynamic weak var windowController: WindowController!
    
    @objc dynamic var midiInputDevices: [MIDIDevice]!
    @objc dynamic var midiOutputDevices: [MIDIDevice]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.midiInputDevices = MIDIInputDevices()
        self.midiOutputDevices = MIDIOutputDevices()
    }
    
}
