//
//  MIDIPlayer.swift
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
import CoreMIDI

let kMIDIPrecision: Int = 10

class MIDIPlayer: NSObject {
    
    weak var leftViewController: LeftViewController!
    
    let preferences = UserDefaults.standard
    
    var consoleAMidiClient = MIDIClientRef()
    var consoleAOutputPort = MIDIPortRef()
    var consoleADestinationEndpointRef = MIDIEndpointRef()
    
    var consoleBMidiClient = MIDIClientRef()
    var consoleBOutputPort = MIDIPortRef()
    var consoleBDestinationEndpointRef = MIDIEndpointRef()
    
    var consoleCMidiClient = MIDIClientRef()
    var consoleCOutputPort = MIDIPortRef()
    var consoleCDestinationEndpointRef = MIDIEndpointRef()
    
    var timePositionObservation: NSKeyValueObservation?
    var consoleAOutputDeviceObservation: NSKeyValueObservation?
    var consoleBOutputDeviceObservation: NSKeyValueObservation?
    var consoleCOutputDeviceObservation: NSKeyValueObservation?
    
    var timeTableLenght: Int = 1000
    var midiTimeTable: [Int]!
    var consoleAMidiControllerTable: [[Int]]!
    var consoleBMidiControllerTable: [[Int]]!
    var consoleCMidiControllerTable: [[Int]]!
    
    var prevTimePosition: Float = 0
    var isPlaying = false
    var currentEventIndex: Int = -1
    
    init(_ leftViewController: LeftViewController) {
        super.init()
        
        self.leftViewController = leftViewController
        
        // Initialize devices and outputs
        self.initializeConsoleA()
        self.initializeConsoleB()
        self.initializeConsoleC()
        
        // Initialize observers
        let timePositionPath = \WindowController.timePosition
        self.timePositionObservation = self.leftViewController.windowController.observe(timePositionPath) { [unowned self] object, change in
            if self.leftViewController.windowController.displayedView == 2 {
                if self.midiTimeTable != nil {
                    if self.isPlaying && (self.leftViewController.windowController.timePosition -  self.prevTimePosition).magnitude < 1 {
                        self.updateTimePosition()
                    } else {
                        self.goToTimePosition()
                    }
                }
                self.prevTimePosition = self.leftViewController.windowController.timePosition
            }
        }
        
        let consoleAOutputDevicePath = \LeftViewController.consoleAOutputDevice
        self.consoleAOutputDeviceObservation = self.leftViewController.observe(consoleAOutputDevicePath) { [unowned self] object, change in
            self.initializeConsoleA()
        }
        let consoleBOutputDevicePath = \LeftViewController.consoleBOutputDevice
        self.consoleBOutputDeviceObservation = self.leftViewController.observe(consoleBOutputDevicePath) { [unowned self] object, change in
            self.initializeConsoleB()
        }
        let consoleCOutputDevicePath = \LeftViewController.consoleCOutputDevice
        self.consoleCOutputDeviceObservation = self.leftViewController.observe(consoleCOutputDevicePath) { [unowned self] object, change in
            self.initializeConsoleC()
        }
    }
    
    //MARK: - Create devices and output ports
    
    /// Initialize output device of console A
    func initializeConsoleA() {
        
        var status = MIDIClientCreateWithBlock("com.motuslabrecorder.MIDIClient" as CFString, &self.consoleAMidiClient, nil)
        if status != noErr {
            Swift.print("MIDIPlayer: initializeConsoleA Error creating client : \(status)")
        }
        
        let deviceIndex = self.leftViewController.consoleAOutputDevice
        self.consoleADestinationEndpointRef = MIDIGetDestination(deviceIndex)
        
        status = MIDIOutputPortCreate(self.consoleAMidiClient, "com.motuslabrecorder.MIDIClient" as CFString, &self.consoleAOutputPort)
        if status != noErr {
            Swift.print("MIDIPlayer: initializeConsoleA Error creating output port : \(status)")
        }
        
    }
    
    /// Initialize output device of console B
    func initializeConsoleB() {
        
        var status = MIDIClientCreateWithBlock("com.motuslabrecorder.MIDIClient" as CFString, &self.consoleBMidiClient, nil)
        if status != noErr {
            Swift.print("MIDIPlayer: initializeConsoleB Error creating client : \(status)")
        }
        
        let deviceIndex = self.leftViewController.consoleBOutputDevice
        self.consoleBDestinationEndpointRef = MIDIGetDestination(deviceIndex)
        status = MIDIOutputPortCreate(self.consoleBMidiClient, "com.motuslabrecorder.MIDIClient" as CFString, &self.consoleBOutputPort)
        if status != noErr {
            Swift.print("MIDIPlayer: initializeConsoleB Error creating output port : \(status)")
        }
        
    }
    
    /// Initialize output device of console C
    func initializeConsoleC() {
        
        var status = MIDIClientCreateWithBlock("com.motuslabrecorder.MIDIClient" as CFString, &self.consoleCMidiClient, nil)
        if status != noErr {
            Swift.print("MIDIPlayer: initializeConsoleC Error creating client : \(status)")
        }
        
        let deviceIndex = self.leftViewController.consoleCOutputDevice
        self.consoleCDestinationEndpointRef = MIDIGetDestination(deviceIndex)
        
        status = MIDIOutputPortCreate(self.consoleCMidiClient, "com.motuslabrecorder.MIDIClient" as CFString, &self.consoleCOutputPort)
        if status != noErr {
            Swift.print("MIDIPlayer: initializeConsoleA Error creating output port : \(status)")
        }
        
    }
    
    //MARK: - load session
    
    /// Load a new controller session
    /// This function create a time table (midiTimeTable) from MIDI events.
    /// It is used when jump to a specific time position (goToTimePosition).
    /// The time table contains 100 indexes (kMIDIPrecision) for each console with the value
    /// of each controllers (consoleAMidiControllerTable and consoleBMidiControllerTable) and
    /// the index of corresponding MIDI event
    func loadSession() {
        
        self.timeTableLenght = Int(self.leftViewController.currentSession.duration) * kMIDIPrecision
        
        self.midiTimeTable = [Int](repeating: 0, count: self.timeTableLenght)
        self.consoleAMidiControllerTable = [[Int]](repeating: [], count: self.timeTableLenght)
        self.consoleBMidiControllerTable = [[Int]](repeating: [], count: self.timeTableLenght)
        self.consoleCMidiControllerTable = [[Int]](repeating: [], count: self.timeTableLenght)
        
        let duration = self.leftViewController.currentSession.duration
        let timeStep = duration / Float(self.timeTableLenght)
        
        var eventIndex: Int = 0
        var consoleATotalControllers = [Int](repeating: 0, count: 129)
        var consoleBTotalControllers = [Int](repeating: 0, count: 129)
        var consoleCTotalControllers = [Int](repeating: 0, count: 129)
        for n in 0..<self.midiTimeTable.count {
            let tableTimePosition = Float(n) * timeStep
            if n > 0 {
                self.midiTimeTable[n] = self.midiTimeTable[n-1]
                self.consoleAMidiControllerTable[n] = self.consoleAMidiControllerTable[n-1]
                self.consoleBMidiControllerTable[n] = self.consoleBMidiControllerTable[n-1]
                self.consoleCMidiControllerTable[n] = self.consoleCMidiControllerTable[n-1]
            }
            for m in eventIndex..<self.leftViewController.windowController.midiControllerEvents.count {
                let event = self.leftViewController.windowController.midiControllerEvents[m]
                let date = event.date
                if event.console == 0 {
                    consoleATotalControllers[event.number] = event.value
                } else if event.console == 1 {
                    consoleBTotalControllers[event.number] = event.value
                } else {
                    consoleCTotalControllers[event.number] = event.value
                }
                
                if date <= tableTimePosition {
                    
                    // Save index in midiControllerEvent
                    self.midiTimeTable[n] = m
                    
                    // Save last position of controller (to use with goToTimePosition)
                    self.consoleAMidiControllerTable[n] = consoleATotalControllers
                    self.consoleBMidiControllerTable[n] = consoleBTotalControllers
                    self.consoleCMidiControllerTable[n] = consoleCTotalControllers
                    
                } else {
                    eventIndex = m
                    break
                }
                
            }
            
        }
        
    }
    
    //MARK: - MIDI Player
    
    /// Get index of consoleAMidiControllerTable in midiTimeTable for a specific time position
    func indexOfTime(_ time: Float) -> (timeTable: Int, index: Int) {
        let duration = self.leftViewController.currentSession.duration
        let indexf = (time * Float(self.midiTimeTable.count)) / duration
        var indexi = Int(floorf(indexf))
        indexi = indexi > self.timeTableLenght - 1 ? self.timeTableLenght - 1 : indexi
        
        return (indexi, self.midiTimeTable[indexi])
    }
    
    /// Send MIDI message to output device
    func sendMessage(_ console: Int, number: Int, value: Int) {
        let controller = self.controllerEnabled(number, console: console)
        if console == 0 {
            if controller.enabled && self.leftViewController.windowController.enableSendMIDI {
                var channel = self.leftViewController.windowController.consoleAParameters.channel
                channel = channel == 0 ? channel : channel - 1
                var midiPacketList = self.createMidiPacketList(status: (0xB0 + channel), val1: number, val2: value)
                MIDISend(self.consoleAOutputPort, self.consoleADestinationEndpointRef, &midiPacketList)
            }
            if controller.all {
                let message = ConsoleLastMidiMessage(number: number, value: value)
                self.leftViewController.setValue(message, forKey: "consoleALastMidiMessage")
            }
        } else if console == 1 && self.preferences.bool(forKey: PreferenceKey.consoleBActivate) {
            if controller.enabled && self.leftViewController.windowController.enableSendMIDI {
                var channel = self.leftViewController.windowController.consoleBParameters.channel
                channel = channel == 0 ? channel : channel - 1
                var midiPacketList = self.createMidiPacketList(status: (0xB0 + channel), val1: number, val2: value)
                MIDISend(self.consoleBOutputPort, self.consoleBDestinationEndpointRef, &midiPacketList)
            }
            if controller.all {
                let message = ConsoleLastMidiMessage(number: number, value: value)
                self.leftViewController.setValue(message, forKey: "consoleBLastMidiMessage")
            }
        } else if console == 2 && self.preferences.bool(forKey: PreferenceKey.consoleCActivate) {
            if controller.enabled && self.leftViewController.windowController.enableSendMIDI {
                var channel = self.leftViewController.windowController.consoleCParameters.channel
                channel = channel == 0 ? channel : channel - 1
                var midiPacketList = self.createMidiPacketList(status: (0xB0 + channel), val1: number, val2: value)
                MIDISend(self.consoleCOutputPort, self.consoleCDestinationEndpointRef, &midiPacketList)
            }
            if controller.all {
                let message = ConsoleLastMidiMessage(number: number, value: value)
                self.leftViewController.setValue(message, forKey: "consoleCLastMidiMessage")
            }
        }
    }
    
    /// Create a MIDI packet
    func createMidiPacketList(status: Int, val1: Int, val2 :Int) -> MIDIPacketList {
        var midipacket = MIDIPacket()
        
        midipacket.timeStamp = 0
        midipacket.length = 3
        midipacket.data.0 = UInt8(status)
        midipacket.data.1 = UInt8(val1)
        midipacket.data.2 = UInt8(val2)
        
        return MIDIPacketList(numPackets: 1, packet: midipacket)
    }
    
    /// Get if controller is enabled (See toobar menu)
    func controllerEnabled(_ number: Int, console: Int) -> (all: Bool, enabled: Bool) {
        if let index = self.leftViewController.controllersList.firstIndex(where: { $0.ctl == number && $0.console == console} ) {
            return (true, self.leftViewController.controllersList[index].enable)
        }
        return (false, false)
    }
    
    /// Go to current time position saved in WindowController > timePosition
    /// Used when user jump to a specific time position
    func goToTimePosition() {
        guard self.consoleAMidiControllerTable.count > 0 &&
                self.leftViewController.windowController.displayedView == 2 else {
            return
        }
        let timePosition = self.leftViewController.windowController.timePosition
        let indexes = self.indexOfTime(timePosition)
        if self.consoleAMidiControllerTable[indexes.timeTable].count > 1 {
            for n in 1..<self.consoleAMidiControllerTable[indexes.timeTable].count {
                self.sendMessage(0, number: n, value: self.consoleAMidiControllerTable[indexes.timeTable][n])
            }
        }
        if self.consoleBMidiControllerTable[indexes.timeTable].count > 1 {
            for n in 1..<self.consoleBMidiControllerTable[indexes.timeTable].count {
                self.sendMessage(1, number: n, value: self.consoleBMidiControllerTable[indexes.timeTable][n])
            }
        }
        if self.consoleCMidiControllerTable[indexes.timeTable].count > 1 {
            for n in 1..<self.consoleCMidiControllerTable[indexes.timeTable].count {
                self.sendMessage(2, number: n, value: self.consoleCMidiControllerTable[indexes.timeTable][n])
            }
        }
        self.currentEventIndex = indexes.index
    }
    
    /// Read MIDI event from the last sent to the new one
    func updateTimePosition() {
        guard self.leftViewController.windowController.displayedView == 2 else {
            return
        }
        
        // Compute current index of MIDI event which is just before timePosition
        let timePosition = self.leftViewController.windowController.timePosition
        let indexes = self.indexOfTime(timePosition)
        let index = indexes.index
        if index > self.currentEventIndex {
            
            // Compute index positions
            var startIndex = self.currentEventIndex
            startIndex = startIndex < 0 ? 0 : startIndex
            let endIndex = index
            if endIndex <= startIndex {
                return
            }
            
            //Send array of MIDI messages
            for n in stride(from: startIndex, through: endIndex, by: 1) {
                self.sendMessage(self.leftViewController.windowController.midiControllerEvents[n].console,
                                 number: self.leftViewController.windowController.midiControllerEvents[n].number,
                                 value: self.leftViewController.windowController.midiControllerEvents[n].value)
            }
            self.currentEventIndex = index
        }
    }
    
    func startPlaying() {
        self.isPlaying = true
    }
    
    func stopPlaying() {
        self.isPlaying = false
    }

}
