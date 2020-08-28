//
//  PlayFadersView.swift
//  MotusLabTool
//
//  Created by Pierre Couprie on 02/09/2019.
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

class PlayFadersView: NSView {
    
    let preferences = UserDefaults.standard
    
    var midiValueCorrection: Int = 0
    
    weak var windowController: WindowController!
    
    var consoleALastValues: [Int]!
    var consoleBLastValues: [Int]!
    var consoleCLastValues: [Int]!
    
    var playFaderStatistics: PlayFaderStatistics!
    
    var consoleALastMidiMessageObservation: NSKeyValueObservation?
    var consoleBLastMidiMessageObservation: NSKeyValueObservation?
    var consoleCLastMidiMessageObservation: NSKeyValueObservation?
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor(named: "paneBackground")?.cgColor
        
        self.consoleALastValues = [Int](repeating: 0, count: 129)
        self.consoleBLastValues = [Int](repeating: 0, count: 129)
        self.consoleCLastValues = [Int](repeating: 0, count: 129)
        
        //Add observer to detect preferences properties
        NotificationCenter.default.addObserver(self, selector: #selector(userDefaultsDidChange), name: UserDefaults.didChangeNotification, object: nil)
        
        self.userDefaultsDidChange(Notification(name: UserDefaults.didChangeNotification))
        
        self.midiValueCorrection = self.preferences.integer(forKey: PreferenceKey.valueCorrection)
    }
    
    func addObservers(windowController: WindowController) {
        self.windowController = windowController
        
        //Add statistcs view
        self.playFaderStatistics = PlayFaderStatistics(frame: self.bounds, leftViewController: self.windowController.leftViewController)
        self.addSubview(self.playFaderStatistics)
        self.playFaderStatistics.isHidden = !UserDefaults.standard.bool(forKey: PreferenceKey.statisticsShow)
        self.playFaderStatistics.addInViewConstraints(superView: self)
        
        // Add observer to detect last MIDI message in each console
        let consoleALastMidiMessagePath = \LeftViewController.consoleALastMidiMessage
        self.consoleALastMidiMessageObservation = self.windowController.leftViewController.observe(consoleALastMidiMessagePath) { [unowned self] object, change in
            if let message = self.windowController.leftViewController.consoleALastMidiMessage {
                self.consoleALastValues[message.number] = message.value
                self.setNeedsDisplay(self.bounds)
            }
        }
        let consoleBLastMidiMessagePath = \LeftViewController.consoleBLastMidiMessage
        self.consoleBLastMidiMessageObservation = self.windowController.leftViewController.observe(consoleBLastMidiMessagePath) { [unowned self] object, change in
            //Swift.print("self.windowController.leftViewController.consoleBLastMidiMessage : \(self.windowController.leftViewController.consoleBLastMidiMessage )")
            if let message = self.windowController.leftViewController.consoleBLastMidiMessage {
                self.consoleBLastValues[message.number] = message.value
                //Swift.print("message.value: \(message.value)")
                self.setNeedsDisplay(self.bounds)
            }
        }
        let consoleCLastMidiMessagePath = \LeftViewController.consoleCLastMidiMessage
        self.consoleCLastMidiMessageObservation = self.windowController.leftViewController.observe(consoleCLastMidiMessagePath) { [unowned self] object, change in
            if let message = self.windowController.leftViewController.consoleCLastMidiMessage {
                self.consoleCLastValues[message.number] = message.value
                self.setNeedsDisplay(self.bounds)
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func userDefaultsDidChange(_ notification: Notification) {
        self.midiValueCorrection = self.preferences.integer(forKey: PreferenceKey.valueCorrection)
        self.setNeedsDisplay(self.bounds)
        
        if let playFaderStatistics = self.playFaderStatistics {
            playFaderStatistics.isHidden = !UserDefaults.standard.bool(forKey: PreferenceKey.statisticsShow)
            playFaderStatistics.setNeedsDisplay(self.playFaderStatistics.bounds)
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        if let context = NSGraphicsContext.current?.cgContext, let windowController = self.windowController, let consoleAParameters = windowController.consoleAParameters, let consoleBParameters = windowController.consoleBParameters, let consoleCParameters = windowController.consoleCParameters {
            
            var controllerCount = consoleAParameters.controllerCount
            if consoleBParameters.enable {
                controllerCount += consoleBParameters.controllerCount
            }
            if consoleCParameters.enable {
                controllerCount += consoleCParameters.controllerCount
            }
            let faderWidth = self.bounds.size.width / CGFloat(controllerCount)
            var faderRect = CGRect(x: 0, y: 0, width: faderWidth, height: 0)
            
            var faderX: CGFloat = 0
            
            // Draw faders of console A
            for (index,fader) in consoleAParameters.filterControllers.enumerated() {
                let value = CGFloat(MIDIValueCorrection(self.consoleALastValues[index], type: self.midiValueCorrection))
                if fader {
                    if value > 0 {
                        context.saveGState()
                        let color = windowController.leftViewController.controllerColor(from: index, console: 0)
                        context.setFillColor(color.cgColor)
                        faderRect.origin.x = faderX
                        faderRect.size.height = (value * self.bounds.size.height) / 127
                        context.addRect(faderRect)
                        context.drawPath(using: .fill)
                        context.restoreGState()
                    }
                    faderX += faderWidth
                }
            }
            
            //Swift.print(" consoleBParameters.filterControllers: \(consoleBParameters.filterControllers)")
            
            // Draw faders of console B
            for (index,fader) in consoleBParameters.filterControllers.enumerated() {
                let value = CGFloat(MIDIValueCorrection(self.consoleBLastValues[index], type: self.midiValueCorrection))
                //Swift.print("value: \(value)")
                if fader {
                    if value > 0 {
                        context.saveGState()
                        let color = windowController.leftViewController.controllerColor(from: index, console: 1)
                        context.setFillColor(color.cgColor)
                        faderRect.origin.x = faderX
                        faderRect.size.height = (value * self.bounds.size.height) / 127
                        context.addRect(faderRect)
                        context.drawPath(using: .fill)
                        context.restoreGState()
                        
                        //Swift.print("console B index: \(index), faderRect: \(faderRect)")
                    }
                    faderX += faderWidth
                }
            }
            
            // Draw faders of console C
            for (index,fader) in consoleCParameters.filterControllers.enumerated() {
                let value = CGFloat(MIDIValueCorrection(self.consoleCLastValues[index], type: self.midiValueCorrection))
                if fader {
                    if value > 0 {
                        context.saveGState()
                        let color = windowController.leftViewController.controllerColor(from: index, console: 2)
                        context.setFillColor(color.cgColor)
                        faderRect.origin.x = faderX
                        faderRect.size.height = (value * self.bounds.size.height) / 127
                        context.addRect(faderRect)
                        context.drawPath(using: .fill)
                        context.restoreGState()
                    }
                    faderX += faderWidth
                }
            }
            
        }
        
    }
    
}
