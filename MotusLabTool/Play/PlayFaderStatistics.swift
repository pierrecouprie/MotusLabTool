//
//  PlayFaderStatistics.swift
//  MotusLabTool
//
//  Created by Pierre Couprie on 13/09/2019.
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

class PlayFaderStatistics: NSView {
    
    weak var leftViewController: LeftViewController!
    let preferences = UserDefaults.standard
    var statistics: Statistics!
    var midiValueCorrection: Int = 0
    
    init(frame frameRect: NSRect, leftViewController: LeftViewController) {
        super.init(frame: frameRect)
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor(calibratedRed: 1, green: 1, blue: 1, alpha: 0.75).cgColor
        
        self.leftViewController = leftViewController
        
        //Add observer to detect preferences properties
        NotificationCenter.default.addObserver(self, selector: #selector(userDefaultsDidChange), name: UserDefaults.didChangeNotification, object: nil)
        
        self.userDefaultsDidChange(Notification(name: UserDefaults.didChangeNotification))
        
        self.midiValueCorrection = self.preferences.integer(forKey: PreferenceKey.valueCorrection)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func userDefaultsDidChange(_ notification: Notification) {
        self.midiValueCorrection = self.preferences.integer(forKey: PreferenceKey.valueCorrection)
        self.setNeedsDisplay(self.bounds)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func computeStatistics(_ midiControllerEvents: [MIDIControllerEvent]) {
        self.statistics = Statistics(midiControllerEvents, duration: self.leftViewController.currentSession.duration)
        self.statistics.compute()
        self.setNeedsDisplay(self.bounds)
    }
    
    override func draw(_ dirtyRect: NSRect) {
        if let consoleAParameters = leftViewController.windowController.consoleAParameters, let consoleBParameters = leftViewController.windowController.consoleBParameters, let statistics = self.statistics  {
            var controllerCount = consoleAParameters.controllerCount
            if consoleBParameters.enable {
                controllerCount += consoleBParameters.controllerCount
            }
            let faderWidth = self.bounds.size.width / CGFloat(controllerCount)
            
            if self.preferences.bool(forKey: PreferenceKey.statisticsMax) {
                self.drawGraph(statistics.consoleAmax, consoleBValues: statistics.consoleBmax , maxValue: 128, faderWidth: faderWidth, color: NSColor.red)
            }
            
            if self.preferences.bool(forKey: PreferenceKey.statisticsMin) {
                self.drawGraph(statistics.consoleAmin, consoleBValues: statistics.consoleBmin , maxValue: 128, faderWidth: faderWidth, color: NSColor.blue)
            }
            
            if self.preferences.bool(forKey: PreferenceKey.statisticsAMean) {
                self.drawGraph(statistics.consoleAarithmeticMean, consoleBValues: statistics.consoleBarithmeticMean , maxValue: 128, faderWidth: faderWidth, color: NSColor.orange)
            }
            
            if self.preferences.bool(forKey: PreferenceKey.statisticsQMean) {
                self.drawGraph(statistics.consoleAquadraticMean, consoleBValues: statistics.consoleBquadraticMean , maxValue: 128, faderWidth: faderWidth, color: NSColor.cyan)
            }
            
            if self.preferences.bool(forKey: PreferenceKey.statisticsVariance) {
                let maxValue = max(statistics.consoleAvariance.max()!,statistics.consoleBvariance.max()!)
                self.drawGraph(statistics.consoleAvariance, consoleBValues: statistics.consoleBvariance , maxValue: maxValue, faderWidth: faderWidth, color: NSColor.magenta, valueCorrection: false)
            }
            
            if self.preferences.bool(forKey: PreferenceKey.statisticsFrequency) {
                let maxValue = max(statistics.consoleAfrequency.max()!,statistics.consoleBfrequency.max()!)
                Swift.print("statisticsFrequency \(maxValue)")
                self.drawGraph(statistics.consoleAfrequency, consoleBValues: statistics.consoleBfrequency , maxValue: maxValue, faderWidth: faderWidth, color: NSColor.purple, valueCorrection: false)
            }
            
            if self.preferences.bool(forKey: PreferenceKey.statisticsDuration) {
                let maxValue = max(statistics.consoleAdurations.max()!,statistics.consoleBdurations.max()!)
                Swift.print("statisticsDuration \(maxValue)")
                self.drawGraph(statistics.consoleAdurations, consoleBValues: statistics.consoleBdurations , maxValue: maxValue, faderWidth: faderWidth, color: NSColor.gray, valueCorrection: false)
            }
            
        }
    }
    
    func drawGraph(_ consoleAValues: [Float], consoleBValues: [Float], maxValue: Float, faderWidth: CGFloat,  color: NSColor, valueCorrection: Bool = true) {
        if let context = NSGraphicsContext.current?.cgContext, let leftViewController = self.leftViewController, let consoleAParameters = leftViewController.windowController.consoleAParameters, let consoleBParameters = leftViewController.windowController.consoleBParameters  {
            
            context.saveGState()
            context.setStrokeColor(color.cgColor)
            context.setLineWidth(2)
            context.setLineCap(.round)
            
            var faderX: CGFloat = faderWidth / 2
            var firstPoint = true
            for (index,fader) in consoleAParameters.filterControllers.enumerated() {
                if fader {
                    var value = CGFloat(consoleAValues[index])
                    if value.isNaN {
                        continue
                    }
                    if valueCorrection {
                        value = CGFloat(MIDIValueCorrection(Int(value), type: self.midiValueCorrection))
                    }
                    value = (value * self.bounds.size.height) / CGFloat(maxValue)
                    
                    value = value < 1 ? 1 : value
                    value = value > self.bounds.size.height - 1 ? self.bounds.size.height - 1 : value
                    
                    if firstPoint {
                        context.move(to: CGPoint(x: faderX, y: value))
                    } else {
                        context.addLine(to: CGPoint(x: faderX, y: value))
                    }
                    firstPoint = false
                    faderX += faderWidth
                }
            }
            
            for (index,fader) in consoleBParameters.filterControllers.enumerated() {
                if fader {
                    var value = CGFloat(consoleBValues[index])
                    if value.isNaN {
                        continue
                    }
                    if valueCorrection {
                        value = CGFloat(MIDIValueCorrection(Int(value), type: self.midiValueCorrection))
                    }
                    value = (value * self.bounds.size.height) / CGFloat(maxValue)
                    
                    value = value < 1 ? 1 : value
                    value = value > self.bounds.size.height - 1 ? self.bounds.size.height - 1 : value
                    
                    context.addLine(to: CGPoint(x: faderX, y: value))
                    faderX += faderWidth
                }
            }
            
            context.drawPath(using: .stroke)
            context.restoreGState()
            
        }
        
    }
    
}
