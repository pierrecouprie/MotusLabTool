//
//  MIDIControllersView.swift
//  MotusLabTool
//
//  Created by Pierre Couprie on 31/08/2019.
//  Copyright © 2019 Pierre Couprie. All rights reserved.
//

import Cocoa

class MIDIControllersView: NSView {
    
    let preferences = UserDefaults.standard
    
    weak var consoleAParameters: MIDIParameters!
    weak var consoleBParameters: MIDIParameters!
    
    var midiValueCorrection: Int = 0
    
    weak var windowController: WindowController! {
        return self.window?.windowController as? WindowController
    }
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor(named: "paneBackground")?.cgColor
        
        //Add observer to detect preferences properties
        NotificationCenter.default.addObserver(self, selector: #selector(userDefaultsDidChange), name: UserDefaults.didChangeNotification, object: nil)
        
        self.userDefaultsDidChange(Notification(name: UserDefaults.didChangeNotification))
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func userDefaultsDidChange(_ notification: Notification) {
        self.setNeedsDisplay(self.bounds)
    }
    
    override func draw(_ dirtyRect: NSRect) {
        if let context = NSGraphicsContext.current?.cgContext, let consoleAParameters = self.consoleAParameters, let consoleBParameters = self.consoleBParameters {
            
            var controllerCount = consoleAParameters.controllerCount
            if self.consoleBParameters.enable {
                controllerCount += consoleBParameters.controllerCount
            }
            let faderWidth = self.bounds.size.width / CGFloat(controllerCount)
            var faderRect = CGRect(x: 0, y: 0, width: faderWidth, height: 0)
            
            var faderX: CGFloat = 0
            
            //Draw faders of console A
            context.saveGState()
            for (index,fader) in self.consoleAParameters.filterControllers.enumerated() {
                let value = CGFloat(MIDIValueCorrection(self.consoleAParameters.controllerValues[index], type: self.midiValueCorrection))
                if fader {
                    if value > 0 {
                        let color = self.windowController.consoleAControllerColors[index]!
                        context.setFillColor(color.cgColor)
                        faderRect.origin.x = faderX
                        faderRect.size.height = (value * self.bounds.size.height) / 127
                        context.addRect(faderRect)
                    }
                    faderX += faderWidth
                }
            }
            context.drawPath(using: .fill)
            context.restoreGState()
            
            //Draw faders of console B
            context.saveGState()
            for (index,fader) in self.consoleBParameters.filterControllers.enumerated() {
                let value = CGFloat(MIDIValueCorrection(self.consoleBParameters.controllerValues[index], type: self.midiValueCorrection))
                if fader {
                    if value > 0 {
                        let color = self.windowController.consoleBControllerColors[index]!
                        context.setFillColor(color.cgColor)
                        faderRect.origin.x = faderX
                        faderRect.size.height = (value * self.bounds.size.height) / 127
                        context.addRect(faderRect)
                    }
                    faderX += faderWidth
                }
            }
            context.drawPath(using: .fill)
            context.restoreGState()
            
        }
        
    }
    
}
