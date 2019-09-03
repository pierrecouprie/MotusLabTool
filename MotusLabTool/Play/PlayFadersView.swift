//
//  PlayFadersView.swift
//  MotusLabTool
//
//  Created by Pierre Couprie on 02/09/2019.
//  Copyright © 2019 Pierre Couprie. All rights reserved.
//

import Cocoa

class PlayFadersView: NSView {
    
    let preferences = UserDefaults.standard
    
    var midiValueCorrection: Int = 0
    
    weak var windowController: WindowController!
    
    var consoleALastValues: [Int]!
    var consoleBLastValues: [Int]!
    
    var consoleALastMidiMessageObservation: NSKeyValueObservation?
    var consoleBLastMidiMessageObservation: NSKeyValueObservation?
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor(named: "paneBackground")?.cgColor
        
        self.consoleALastValues = [Int](repeating: 0, count: 129)
        self.consoleBLastValues = [Int](repeating: 0, count: 129)
        
        //Add observer to detect preferences properties
        NotificationCenter.default.addObserver(self, selector: #selector(userDefaultsDidChange), name: UserDefaults.didChangeNotification, object: nil)
        
        self.userDefaultsDidChange(Notification(name: UserDefaults.didChangeNotification))
    }
    
    func addObservers(windowController: WindowController) {
        self.windowController = windowController
        
        Swift.print("PlayFadersView > addObservers()")
        
        //Add observer to detect last MIDI message in each console
        let consoleALastMidiMessagePath = \LeftViewController.consoleALastMidiMessage
        self.consoleALastMidiMessageObservation = self.windowController.leftViewController.observe(consoleALastMidiMessagePath) { [unowned self] object, change in
            if let message = self.windowController.leftViewController.consoleALastMidiMessage {
                self.consoleALastValues[message.number] = message.value
                self.setNeedsDisplay(self.bounds)
            }
        }
        let consoleBLastMidiMessagePath = \LeftViewController.consoleBLastMidiMessage
        self.consoleBLastMidiMessageObservation = self.windowController.leftViewController.observe(consoleBLastMidiMessagePath) { [unowned self] object, change in
            if let message = self.windowController.leftViewController.consoleBLastMidiMessage {
                self.consoleBLastValues[message.number] = message.value
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
    }
    
    override func draw(_ dirtyRect: NSRect) {
        if let context = NSGraphicsContext.current?.cgContext, let windowController = self.windowController, let consoleAParameters = windowController.consoleAParameters, let consoleBParameters = windowController.consoleBParameters {
            
            var controllerCount = consoleAParameters.controllerCount
            if consoleBParameters.enable {
                controllerCount += consoleBParameters.controllerCount
            }
            let faderWidth = self.bounds.size.width / CGFloat(controllerCount)
            var faderRect = CGRect(x: 0, y: 0, width: faderWidth, height: 0)
            
            var faderX: CGFloat = 0
            
            //Draw faders of console A
            for (index,fader) in consoleAParameters.filterControllers.enumerated() {
                let value = CGFloat(MIDIValueCorrection(self.consoleALastValues[index], type: self.midiValueCorrection))
                if fader {
                    if value > 0 {
                        context.saveGState()
                        //let color = windowController.consoleAControllerColors[index]!
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
            
            //Draw faders of console B
            for (index,fader) in consoleBParameters.filterControllers.enumerated() {
                let value = CGFloat(MIDIValueCorrection(self.consoleBLastValues[index], type: self.midiValueCorrection))
                if fader {
                    if value > 0 {
                        context.saveGState()
                        //let color = windowController.consoleBControllerColors[index]!
                        let color = windowController.leftViewController.controllerColor(from: index, console: 1)
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
    
    /*func controllerColor(from number: Int, console: Int) -> NSColor {
        if let windowController = self.windowController, let leftViewController = windowController.leftViewController {
            for controllerItem in leftViewController.controllersList {
                if controllerItem.ctl == number && controllerItem.console == console {
                    if controllerItem.enable {
                        if console == 0 {
                            return windowController.consoleAControllerColors[number]!
                        } else {
                            return windowController.consoleBControllerColors[number]!
                        }
                    }
                    break
                }
            }
        }
        
        return NSColor.lightGray
    }*/
    
}
