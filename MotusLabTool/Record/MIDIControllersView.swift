//
//  MIDIControllersView.swift
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

class MIDIControllersView: NSView {
    
    let preferences = UserDefaults.standard
    
    weak var consoleAParameters: MIDIParameters!
    weak var consoleBParameters: MIDIParameters!
    weak var consoleCParameters: MIDIParameters!
    
    var midiValueCorrection: Int = 0
    
    weak var windowController: WindowController! {
        return self.window?.windowController as? WindowController
    }
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor(named: "paneBackground")?.cgColor
        
        // Add observer to detect preferences properties
        NotificationCenter.default.addObserver(self, selector: #selector(userDefaultsDidChange), name: UserDefaults.didChangeNotification, object: nil)
        
        self.userDefaultsDidChange(Notification(name: UserDefaults.didChangeNotification))
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func userDefaultsDidChange(_ notification: Notification) {
        self.midiValueCorrection = self.preferences.integer(forKey: PreferenceKey.valueCorrection)
        DispatchQueue.main.async {
            self.setNeedsDisplay(self.bounds)
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        if let context = NSGraphicsContext.current?.cgContext, let consoleAParameters = self.consoleAParameters, let consoleBParameters = self.consoleBParameters, let consoleCParameters = self.consoleCParameters {
            
            var controllerCount = consoleAParameters.controllerCount
            if self.consoleBParameters.enable {
                controllerCount += consoleBParameters.controllerCount
            }
            if self.consoleCParameters.enable {
                controllerCount += consoleCParameters.controllerCount
            }
            let faderWidth = self.bounds.size.width / CGFloat(controllerCount)
            var faderRect = CGRect(x: 0, y: 0, width: faderWidth, height: 0)
            
            var faderX: CGFloat = 0
            
            // Draw faders of console A
            for (index,fader) in self.consoleAParameters.filterControllers.enumerated() {
                let value = CGFloat(MIDIValueCorrection(self.consoleAParameters.controllerValues[index], type: self.midiValueCorrection))
                if fader {
                    if value > 0 {
                        context.saveGState()
                        let color = self.windowController.consoleAControllerColors[index] ?? NSColor.black
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
            
            // Draw faders of console B
            for (index,fader) in self.consoleBParameters.filterControllers.enumerated() {
                let value = CGFloat(MIDIValueCorrection(self.consoleBParameters.controllerValues[index], type: self.midiValueCorrection))
                if fader {
                    if value > 0 {
                        context.saveGState()
                        let color = self.windowController.consoleBControllerColors[index] ?? NSColor.black
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
            
            // Draw faders of console C
            for (index,fader) in self.consoleCParameters.filterControllers.enumerated() {
                let value = CGFloat(MIDIValueCorrection(self.consoleCParameters.controllerValues[index], type: self.midiValueCorrection))
                //Swift.print("value: \(value)")
                if fader {
                    if value > 0 {
                        context.saveGState()
                        let color = self.windowController.consoleCControllerColors[index] ?? NSColor.black
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
