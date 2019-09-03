//
//  MIDIRecorder.swift
//  MotusLabTool
//
//  Created by Pierre Couprie on 31/08/2019.
//  Copyright © 2019 Pierre Couprie. All rights reserved.
//

import Cocoa
import CoreMIDI

extension MIDIPacketList: Sequence {
    public func makeIterator() -> AnyIterator<MIDIPacket> {
        var iterator: MIDIPacket?
        var nextIndex: UInt32 = 0
        
        return AnyIterator {
            nextIndex += 1
            if nextIndex > self.numPackets { return nil }
            if iterator != nil {
                iterator = withUnsafePointer(to: &iterator!) { MIDIPacketNext($0).pointee }
            } else {
                iterator = self.packet;
            }
            return iterator
        }
    }
}

extension MIDIPacket {
    public var asArray: [UInt8] {
        let mirror = Mirror(reflecting: self.data)
        let length = Int(self.length)
        
        var result = [UInt8]()
        result.reserveCapacity(length)
        
        for (n, child) in mirror.children.enumerated() {
            if n == length {
                break
            }
            result.append(child.value as! UInt8)
        }
        return result
    }
}

class MIDIRecorder: NSObject {
    
    weak var leftViewController: LeftViewController!
    weak var consoleParameters: MIDIParameters!
    
    var midiClient = MIDIClientRef()
    var inputPort = MIDIPortRef()
    var timer: Timer!
    
    init(leftViewController: LeftViewController, consoleParameters: MIDIParameters) {
        super.init()
        
        self.leftViewController = leftViewController
        self.consoleParameters = consoleParameters
        
        let notifyBlock: MIDINotifyBlock = self.midiNotifyBlock
        var status = MIDIClientCreateWithBlock("com.motuslabrecorder.MIDIClient" as CFString, &self.midiClient, notifyBlock)
        if status != noErr {
            Swift.print("MIDIRecorder: init Error creating client : \(status)")
        }
        
        //Open inputPort
        let readBlock: MIDIReadBlock = self.midiReadBlock
        if status == noErr {
            status = MIDIInputPortCreateWithBlock(self.midiClient, "com.motuslabrecorder.MIDIInputPort" as CFString, &self.inputPort, readBlock)
        }
        
        self.initializeSourceConnection(index: 0, disconnect: false)
    }
    
    func initializeSourceConnection(index: Int, disconnect: Bool = true) {
        let sourceCount = MIDIGetNumberOfSources()
        
        //Disconnect sources
        if disconnect {
            for srcIndex in 0..<sourceCount {
                let midiEndPoint = MIDIGetSource(srcIndex)
                let status = MIDIPortDisconnectSource(self.inputPort,
                                                      midiEndPoint)
                if status != noErr {
                    Swift.print("MIDIRecorder: init Error disconnecting source : \(status)")
                }
            }
        }
        
        //Connect new sources
        for srcIndex in 0..<sourceCount {
            if index == 0 || index == srcIndex + 1 {
                //Swift.print("connect = \(srcIndex)")
                let midiEndPoint = MIDIGetSource(srcIndex)
                let status = MIDIPortConnectSource(self.inputPort,
                                                   midiEndPoint,
                                                   nil)
                if status != noErr {
                    Swift.print("MIDIRecorder: init Error connecting source A : \(status)")
                }
            }
        }
        
        self.consoleParameters.setValue("No message", forKey: "message")
    }
    
    func midiNotifyBlock(midiNotification: UnsafePointer<MIDINotification>) {
        print("\ngot a MIDINotification!")
    }
    
    func midiReadBlock(packetList: UnsafePointer<MIDIPacketList>, srcConnRefCon: UnsafeMutableRawPointer?) -> Swift.Void {
        let packets: MIDIPacketList = packetList.pointee
        for packet in packets.makeIterator() {
            let packetArray = packet.asArray
            
            for n in stride(from: 0, to: packetArray.count - 1, by: 3) {
                let end = n+2
                let slice = packetArray[n...end]
                let singlePacket = Array(slice)
                self.midiParser(singlePacket)
            }
        }
    }
    
    //var timerRun = false
    @objc func midiIntputOff() {
        DispatchQueue.main.async {
            self.consoleParameters.setValue(0.0, forKey: "led")
        }
    }
    
    func midiParser(_ packet: [UInt8]) {
        
        guard self.consoleParameters.enable else {
            return
        }
        
        let status = packet[0]
        let number = Int(packet[1])
        let value = Int(packet[2])
        let rawStatus = status & 0xF0 // without channel
        let channel = Int(status & 0x0F) + 1 //+ 1 because channels are numeroted 0-15
        
        var newEvent: MIDIControllerEvent!
        if rawStatus == 0xB0 && self.channelValidation(channel) && (self.consoleParameters.filterControllers[number] || self.consoleParameters.learn == .on || self.consoleParameters.learnAll == .on) { //Only controller messages
            newEvent = MIDIControllerEvent(date: self.leftViewController.windowController.timePosition,
                                           console: self.consoleParameters.console,
                                           channel: channel,
                                           number: number,
                                           value: value)
            
            //used for acousmonium representation
            DispatchQueue.main.async {
                if self.consoleParameters.console == 0 {
                    let message = ConsoleLastMidiMessage(number: number, value: value)
                    self.leftViewController.setValue(message, forKey: "consoleALastMidiMessage")
                } else {
                    let message = ConsoleLastMidiMessage(number: number, value: value)
                    self.leftViewController.setValue(message, forKey: "consoleBLastMidiMessage")
                }
            }
        }
        
        if let event = newEvent {
            //Display led and message
            self.consoleParameters.midiControllerEvent = event
            self.consoleParameters.controllerValues[event.number] = event.value
            
            DispatchQueue.main.async {
                self.leftViewController.updateControllerView()
                self.consoleParameters.message = event.feedback
                self.consoleParameters.setValue(1, forKey: "led")
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: {
                self.consoleParameters.setValue(0.0, forKey: "led")
            })
            
            //Record event
            if self.leftViewController.windowController.currentMode == Mode.recording {
                self.leftViewController.windowController.midiControllerEvents.append(event)
            }
        }
    }
    
    func channelValidation(_ channel: Int) -> Bool {
        if self.consoleParameters.channel == 0 || self.consoleParameters.channel == channel {
            return true
        }
        
        return false
    }
    
}
