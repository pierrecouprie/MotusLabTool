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
    
    var consoleAMidiMessageObservation: NSKeyValueObservation?
    var consoleBMidiMessageObservation: NSKeyValueObservation?
    
    @IBOutlet weak var consoleALed: NSLevelIndicator!
    @IBOutlet weak var consoleAMessage: NSTextField!
    @IBOutlet weak var consoleBLed: NSLevelIndicator!
    @IBOutlet weak var consoleBMessage: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.midiInputDevices = MIDIInputDevices()
        self.midiOutputDevices = MIDIOutputDevices()
        
        //Observers
        let ledPath = \MIDIParameters.led
        self.consoleAMidiMessageObservation = self.windowController.consoleAParameters.observe(ledPath) { [unowned self] object, change in
            self.consoleALed.doubleValue = self.windowController.consoleAParameters.led
            self.consoleAMessage.stringValue = self.windowController.consoleAParameters.message
        }
        self.consoleBMidiMessageObservation = self.windowController.consoleBParameters.observe(ledPath) { [unowned self] object, change in
            self.consoleBLed.doubleValue = self.windowController.consoleBParameters.led
            self.consoleBMessage.stringValue = self.windowController.consoleBParameters.message
        }
    }
    
}
