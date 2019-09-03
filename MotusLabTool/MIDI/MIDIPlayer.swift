//
//  MIDIPlayer.swift
//  MotusLabTool
//
//  Created by Pierre Couprie on 01/09/2019.
//  Copyright © 2019 Pierre Couprie. All rights reserved.
//

import Foundation
import CoreMIDI

let kMIDIPrecision: Int = 100

class MIDIPlayer: NSObject {
    
    weak var leftViewController: LeftViewController!
    
    let preferences = UserDefaults.standard
    
    var consoleAMidiClient = MIDIClientRef()
    var consoleAOutputPort = MIDIPortRef()
    var consoleADestinationEndpointRef = MIDIEndpointRef()
    
    var consoleBMidiClient = MIDIClientRef()
    var consoleBOutputPort = MIDIPortRef()
    var consoleBDestinationEndpointRef = MIDIEndpointRef()
    
    var timePositionObservation: NSKeyValueObservation?
    var consoleAOutputDeviceObservation: NSKeyValueObservation?
    var consoleBOutputDeviceObservation: NSKeyValueObservation?
    
    var timeTableLenght: Int = 1000
    var midiTimeTable: [Int]!
    var consoleAMidiControllerTable: [[Int]]!
    var consoleBMidiControllerTable: [[Int]]!
    
    var prevTimePosition: Float = 0
    var isPlaying = false
    var currentEventIndex: Int = -1
    
    init(_ leftViewController: LeftViewController) {
        super.init()
        
        self.leftViewController = leftViewController
        
        //Initialize devices and outputs
        self.initializeConsoleA()
        self.initializeConsoleB()
        
        //Add observers
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
    }
    
    //MARK: - Create devices and output ports
    
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
    
    func initializeConsoleB() {
        
        var status = MIDIClientCreateWithBlock("com.motuslabrecorder.MIDIClient" as CFString, &self.consoleBMidiClient, nil)
        if status != noErr {
            Swift.print("MIDIPlayer: initializeConsoleA Error creating client : \(status)")
        }
        
        let deviceIndex = self.leftViewController.consoleBOutputDevice
        self.consoleBDestinationEndpointRef = MIDIGetDestination(deviceIndex)
        
        status = MIDIOutputPortCreate(self.consoleAMidiClient, "com.motuslabrecorder.MIDIClient" as CFString, &self.consoleBOutputPort)
        if status != noErr {
            Swift.print("MIDIPlayer: initializeConsoleA Error creating output port : \(status)")
        }
        
    }
    
    //MARK: - load session
    
    func loadSession() {
        
        Swift.print("MIDIPlayer > loadSession()")
        
        //Swift.print("\(self.playViewController.midiControllerEvents.count) MIDI events")
        
        self.timeTableLenght = Int(self.leftViewController.currentSession.duration) * kMIDIPrecision
        
        self.midiTimeTable = [Int](repeating: 0, count: self.timeTableLenght)
        self.consoleAMidiControllerTable = [[Int]](repeating: [], count: self.timeTableLenght)
        self.consoleBMidiControllerTable = [[Int]](repeating: [], count: self.timeTableLenght)
        
        let duration = self.leftViewController.currentSession.duration
        let timeStep = duration / Float(self.timeTableLenght)
        
        var eventIndex: Int = 0
        var consoleATotalControllers = [Int](repeating: 0, count: 129)
        var consoleBTotalControllers = [Int](repeating: 0, count: 129)
        for n in 0..<self.midiTimeTable.count {
            let tableTimePosition = Float(n) * timeStep
            
            for m in eventIndex..<self.leftViewController.windowController.midiControllerEvents.count {
                let event = self.leftViewController.windowController.midiControllerEvents[m]
                let date = event.date
                if event.console == 0 {
                    consoleATotalControllers[event.number] = event.value
                } else {
                    consoleBTotalControllers[event.number] = event.value
                }
                if date > tableTimePosition {
                    
                    //Save index in midiControllerEvent
                    self.midiTimeTable[n] = m
                    
                    //Save last position of controller (to use with goToTimePosition)
                    self.consoleAMidiControllerTable[n] = consoleATotalControllers
                    self.consoleBMidiControllerTable[n] = consoleBTotalControllers
                    
                    eventIndex = m
                    
                    break
                }
            }
        }
        
    }
    
    //MARK: - MIDI Player
    
    func indexOfTime(_ time: Float) -> (timeTable: Int, index: Int) {
        let duration = self.leftViewController.currentSession.duration
        let indexf = (time * Float(self.midiTimeTable.count)) / duration
        var indexi = Int(floorf(indexf))
        indexi = indexi > self.timeTableLenght - 1 ? self.timeTableLenght - 1 : indexi
        
        return (indexi, self.midiTimeTable[indexi])
    }
    
    func sendMessage(_ console: Int, number: Int, value: Int) {
        let controller = self.controllerEnabled(number, console: console)
        //Swift.print("MIDIPlayer > sendMessage console: \(console), number: \(number), value: \(value)")
        if console == 0 {
            if controller.enabled {
                var channel = self.leftViewController.windowController.consoleAParameters.channel
                channel = channel == 0 ? channel : channel - 1
                var midiPacketList = createMidiPacketList(status: (0xB0 + channel), val1: number, val2: value)
                MIDISend(self.consoleAOutputPort, self.consoleADestinationEndpointRef, &midiPacketList)
            }
            if controller.all {
                let message = ConsoleLastMidiMessage(number: number, value: value)
                self.leftViewController.setValue(message, forKey: "consoleALastMidiMessage")
            }
        } else if self.preferences.bool(forKey: PreferenceKey.consoleBActivate) {
            if controller.enabled {
                var channel = self.leftViewController.windowController.consoleBParameters.channel
                channel = channel == 0 ? channel : channel - 1
                var midiPacketList = createMidiPacketList(status: (0xB0 + channel), val1: number, val2: value)
                MIDISend(self.consoleBOutputPort, self.consoleBDestinationEndpointRef, &midiPacketList)
            }
            if controller.all {
                let message = ConsoleLastMidiMessage(number: number, value: value)
                self.leftViewController.setValue(message, forKey: "consoleBLastMidiMessage")
            }
        }
    }
    
    func controllerEnabled(_ number: Int, console: Int) -> (all: Bool, enabled: Bool) {
        if let index = self.leftViewController.controllersList.firstIndex(where: { $0.ctl == number && $0.console == console} ) {
            return (true, self.leftViewController.controllersList[index].enable)
        }
        return (false, false)
    }
    
    func createMidiPacketList(status: Int, val1: Int, val2 :Int) -> MIDIPacketList {
        var midipacket = MIDIPacket()
        
        midipacket.timeStamp = 0
        midipacket.length = 3
        midipacket.data.0 = UInt8(status)
        midipacket.data.1 = UInt8(val1)
        midipacket.data.2 = UInt8(val2)
        
        return MIDIPacketList(numPackets: 1, packet: midipacket)
    }
    
    func goToTimePosition() {
        guard self.leftViewController.windowController.displayedView == 2 else {
            return
        }
        //Swift.print("MIDIPlayer > goToTimePosition")
        let timePosition = self.leftViewController.windowController.timePosition
        let indexes = self.indexOfTime(timePosition)
        if self.consoleAMidiControllerTable[indexes.timeTable].count > 1 && self.consoleBMidiControllerTable[indexes.timeTable].count > 1 {
            /*Swift.print("Console A ======")
            Swift.print(self.consoleAMidiControllerTable[indexes.timeTable])
            Swift.print("Console B ======")
            Swift.print(self.consoleBMidiControllerTable[indexes.timeTable])*/
            for n in 1..<self.consoleAMidiControllerTable[indexes.timeTable].count {
                self.sendMessage(0, number: n, value: self.consoleAMidiControllerTable[indexes.timeTable][n])
            }
            for n in 1..<self.consoleBMidiControllerTable[indexes.timeTable].count {
                self.sendMessage(1, number: n, value: self.consoleBMidiControllerTable[indexes.timeTable][n])
            }
        }
        self.currentEventIndex = indexes.index
    }
    
    func updateTimePosition() {
        guard self.leftViewController.windowController.displayedView == 2 else {
            return
        }
        //Swift.print("MIDIPlayer > updateTimePosition")
        let timePosition = self.leftViewController.windowController.timePosition
        let indexes = self.indexOfTime(timePosition)
        let index = indexes.index
        if index > self.currentEventIndex {
            var startIndex = self.currentEventIndex
            startIndex = startIndex < 0 ? 0 : startIndex
            var endIndex = index
            endIndex = endIndex <= startIndex ? startIndex + 1 : endIndex
            for n in startIndex..<endIndex {
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
