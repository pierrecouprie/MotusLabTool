//
//  MIDITools.swift
//  MotusLabTool
//
//  Created by Pierre Couprie on 30/08/2019.
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
import CoreMIDI

@objcMembers
class MIDIDevice: NSObject {
    var id = ""
    var name = ""
    
    convenience required init(id: String, name: String) {
        self.init()
        self.id = id
        self.name = name
    }
}


/// Initialize a list of input MIDI devices
func MIDIInputDevices() -> [MIDIDevice] {
    let sourceCount = MIDIGetNumberOfSources()
    
    var inputDevices = [MIDIDevice]()
    let newDevice = MIDIDevice(id: String(-1), name: "All devices")
    inputDevices.append(newDevice)
    for srcIndex in 0..<sourceCount {
        let midiEndPoint = MIDIGetSource(srcIndex)
        let newDevice = MIDIDevice(id: String(srcIndex), name: MIDIDisplayName(midiobject: midiEndPoint))
        inputDevices.append(newDevice)
    }
    return inputDevices
}

/// Initialize a list of output MIDI devices
func MIDIOutputDevices() -> [MIDIDevice] {
    let sourceCount = MIDIGetNumberOfDestinations()
    
    var outputDevices = [MIDIDevice]()
    for destIndex in 0..<sourceCount {
        let midiDestPoint = MIDIGetDestination(destIndex)
        let newDevice = MIDIDevice(id: String(destIndex), name: MIDIDisplayName(midiobject: midiDestPoint))
        outputDevices.append(newDevice)
    }
    return outputDevices
}

/// Get the name of device in String
func MIDIDisplayName(midiobject: MIDIObjectRef) -> String {
    var name : Unmanaged<CFString>?
    let err = MIDIObjectGetStringProperty(midiobject, kMIDIPropertyDisplayName, &name)
    if err == noErr {
        return name!.takeRetainedValue() as String
    }
    return "No name"
}

@objcMembers
class MIDIParameters: NSObject {
    dynamic var enable = false
    var console: Int = 0
    var channel: Int = 0
    var learn: NSButton.StateValue = .off
    var learnAll: NSButton.StateValue = .off {
        didSet {
            if self.learnAll == .on {
                self.filterControllers = [Bool](repeating: false, count: 129)
            }
        }
    }
    var midiControllerEvent: MIDIControllerEvent! {
        didSet {
            if self.learn == .on || self.learnAll == .on {
                self.learnController(midiControllerEvent)
            }
        }
    }
    var filter = "1-128" {
        didSet {
            self.updateControllers()
            if self.console == 0 {
                self.preferences.set(self.filter, forKey: PreferenceKey.consoleAMapping)
            } else if self.console == 1 {
                self.preferences.set(self.filter, forKey: PreferenceKey.consoleBMapping)
            } else if self.console == 2 {
                self.preferences.set(self.filter, forKey: PreferenceKey.consoleCMapping)
            }
        }
    }
    var filterControllers = [Bool](repeating: true, count: 129) {
        didSet {
            let valid = self.filterControllers.filter( { $0 == true } )
            self.controllerCount = valid.count
        }
    }
    var controllerValues = [Int](repeating: 0, count: 129)
    var controllerCount: Int = 128
    var led: Double = 0
    var message = "No message"
    
    weak var windowController: WindowController!
    
    let preferences = UserDefaults.standard
    
    init(console: Int, windowController: WindowController, enable: Bool = true) {
        super.init()
        self.console = console
        self.windowController = windowController
        self.enable = enable
        self.updateControllers()
    }
    
    func updateControllers() {
        var output = [Bool](repeating: false, count: 129)
        
        let items = self.filter.components(separatedBy: " ")
        for item in items {
            if item.contains("-") {
                let subItems = item.components(separatedBy: "-")
                if subItems.count == 2 {
                    if let first = subItems.first, let last = subItems.last, let intStartValue = Int(first), let intEndValue = Int(last) {
                        for n in intStartValue..<intEndValue+1 {
                            output[n] = true
                        }
                    }
                }
            } else {
                if let intValue = Int(item) {
                    if intValue > 0 && intValue < 129 {
                        output[intValue] = true
                    }
                }
            }
        }
        self.filterControllers = output
    }
    
    func learnController(_ event: MIDIControllerEvent) {
        DispatchQueue.main.async {
            self.setValue(NSButton.StateValue.off, forKey: "learn")
            self.filterControllers[event.number] = true
            let stringList = self.cleanMidiControlList(self.filterControllers)
            self.setValue(stringList, forKey: "filter")
        }
    }
    
    func cleanMidiControlList(_ controllers: [Bool]) -> String {
        
        //Get a list of only activated controllers
        var intItems = [Int]()
        for n in 1..<controllers.count {
            let item = controllers[n]
            if item {
                intItems.append(n)
            }
        }
        
        //Create groups for sequential controllers (with '-')
        var output = ""
        var lastGroup: Int!
        var previous: Int = 0
        
        func outputEmpty() {
            if !output.isEmpty {
                output += " "
            }
        }
        
        func addGroup() {
            output += String(lastGroup) + "-" + String(previous)
            lastGroup = nil
        }
        
        for n in 1..<intItems.count+1 {
            previous = intItems[n-1]
            if n < intItems.count {
                let current = intItems[n]
                if current == previous + 1 {
                    if lastGroup == nil {
                        lastGroup = intItems[n-1]
                    }
                } else {
                    if lastGroup != nil {
                        outputEmpty()
                        addGroup()
                    } else {
                        outputEmpty()
                        output += String(previous)
                    }
                }
            } else {
                if lastGroup != nil {
                    outputEmpty()
                    addGroup()
                } else {
                    output += " " + String(previous)
                }
            }
        }
        
        return output
    }
    
}

@objcMembers
class ConsoleLastMidiMessage: NSObject {
    var number: Int = 1
    var value: Int = 0
    
    init(number: Int, value: Int) {
        super.init()
        self.number = number
        self.value = value
    }
    
    override var description: String {
        return "ConsoleLastMidiMessage number: \(self.number), value: \(self.value)"
    }
}
