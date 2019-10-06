//
//  PlayControllersView.swift
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

import Cocoa

struct ControllerItem {
    var id: Int = 0
    var ctl: Int = 1
    var number: Int = 0
    var enable: Bool = true
    var console: Int = 0
    var show: Bool = true
}

class PlayControllersView: NSView {
    
    weak var leftViewController: LeftViewController! 
    
    var controllers: [Int:[(date: Float, value: Int)]]!
    var consoleAMaxNumber: Int = 0
    var consoleBStartId: Int = 0
    var playCTRLColors: Int = 0
    var playCTRLAlpha: Float = 0.8
    var midiValueCorrection: Int = 0
    
    let preferences = UserDefaults.standard
    
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        
        self.wantsLayer = true
        self.alphaValue = CGFloat(self.preferences.float(forKey: PreferenceKey.playCTRLAlpha))
        
        // Add observer to detect preferences properties
        NotificationCenter.default.addObserver(self, selector: #selector(userDefaultsDidChange), name: UserDefaults.didChangeNotification, object: nil)
        
        self.userDefaultsDidChange(Notification(name: UserDefaults.didChangeNotification))
    }
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func userDefaultsDidChange(_ notification: Notification) {
        if self.preferences.float(forKey: PreferenceKey.playCTRLAlpha) != self.playCTRLAlpha {
            self.playCTRLAlpha = self.preferences.float(forKey: PreferenceKey.playCTRLAlpha)
            self.alphaValue = CGFloat(self.playCTRLAlpha)
        } else if self.preferences.integer(forKey: PreferenceKey.valueCorrection) != self.midiValueCorrection {
            self.midiValueCorrection = self.preferences.integer(forKey: PreferenceKey.valueCorrection)
        }
        self.setNeedsDisplay(self.bounds)
    }
    
    /// Concert MIDI events to list of values for each controller numbers
    func convertEvents() {
        var output = [Int:[(date: Float, value: Int)]]()
        self.leftViewController.controllersList = []
        
        func readControllers(_ consoleControllers: [Bool], start: Int = 0) -> Int {
            var maxNumber: Int = 1
            for n in 1..<consoleControllers.count {
                let controller = consoleControllers[n]
                if controller {
                    output[n + start] = [(date: Float, value: Int)]()
                    var controllerItem = ControllerItem(id: 0, ctl: n, number: n + start, enable: true, console: 0, show: true)
                    if start > 0 {
                        controllerItem.console = 1
                        if n == 1 {
                            self.consoleBStartId = self.leftViewController.controllersList.count
                        }
                    }
                    self.leftViewController.controllersList.append(controllerItem)
                    maxNumber = n + start
                }
            }
            return maxNumber
        }
        
        // Create indexes
        self.consoleAMaxNumber = readControllers(self.leftViewController.currentSession.consoleAControllers)
        if self.preferences.bool(forKey: PreferenceKey.consoleBActivate) {
            let _ = readControllers(self.leftViewController.currentSession.consoleBControllers, start: self.consoleAMaxNumber)
        }
        
        // Create id in controllersList {
        for n in 0..<self.leftViewController.controllersList.count{
            self.leftViewController.controllersList[n].id = n
        }
        
        // Read controllers
        for controller in self.leftViewController.windowController.midiControllerEvents {
            let newEvent = (date: controller.date, value: controller.value)
            var number = controller.number
            if controller.console == 1 {
                number += self.consoleAMaxNumber
            }
            output[number]?.append(newEvent)
        }
        
        self.controllers = output
        
    }
    
    override func draw(_ dirtyRect: NSRect) {
        
        guard self.controllers != nil && self.leftViewController != nil && self.leftViewController.windowController.midiControllerEvents != nil && self.leftViewController.windowController.midiControllerEvents.count > 0 else {
            return
        }
        
        if let context = NSGraphicsContext.current?.cgContext {
            let controllerCount = self.leftViewController.controllersList.filter( { $0.show == true } ).count
            let height: CGFloat = self.bounds.size.height / CGFloat(controllerCount)
            let heightTranslation: CGFloat = height
            
            // Draw controller graphs
            var yTranslation: CGFloat = 0.0
            for n in stride(from: self.leftViewController.controllersList.count - 1, through: 0, by: -1) {
                let controllerItem = self.leftViewController.controllersList[n]
                
                if !controllerItem.show {
                    continue
                }
                
                var curveFrame = dirtyRect
                curveFrame.size.height = height
                curveFrame.origin.y = yTranslation
                
                var drawingPath = CGMutablePath()
                if let curvePath = self.CurvePath(frame: curveFrame, controller: controllerItem.number) {
                    drawingPath = curvePath as! CGMutablePath
                }
                
                self.drawPath(context: context, curveClosePath: drawingPath, color: self.leftViewController.controllerColor(from: controllerItem.ctl, console: controllerItem.console))
                
                yTranslation += heightTranslation
            }
            
        }
    }
    
    /// Draw a path from a serie
    /// - parameter context: CGContext
    /// - parameter curvePath: the path to draw
    /// - parameter height: the height of view
    /// - parameter yTranslation: the y center position of serie
    func drawPath(context: CGContext, curveClosePath: CGPath, color: NSColor) {
        
        context.saveGState()
        
        context.setFillColor(color.cgColor)
        context.setLineWidth(1)
        context.setLineJoin(CGLineJoin.miter)
        
        context.addPath(curveClosePath)
        context.drawPath(using: CGPathDrawingMode.fill)
        
        context.restoreGState()
        
    }
    
    /// Create the path to draw from data
    /// - parameter channel: Channel to draw, nil for mixed channels
    /// - returns: The path to draw
    func CurvePath(frame: NSRect, controller: Int) -> CGPath? {
        
        if let leftViewController = self.leftViewController, let currentSession = leftViewController.currentSession, let controllers = self.controllers {
            
            guard controllers[controller]!.count > 0 else {
                return nil
            }
            
            var points = [CGPoint]()
            var x: CGFloat = 0
            var firstX: CGFloat = -1
            var y: CGFloat = frame.origin.y
            var prevX: CGFloat = -1
            var prevY: CGFloat = y
            var maxSlice: CGFloat = 0
            for position in controllers[controller]! {
                
                x = (CGFloat(position.date) * self.bounds.width) / CGFloat(currentSession.duration)
                y = CGFloat(MIDIValueCorrection(position.value, type: self.midiValueCorrection)) / 128
                
                if firstX == -1 {
                    firstX = x
                }
                
                if x >= prevX + 1 {
                    
                    if x > prevX +  1 {
                        let cgPoint = CGPoint(x: x, y:  prevY)
                        points.append(cgPoint)
                    }
                    
                    if y < maxSlice {
                        y = maxSlice
                    }
                    y *= frame.size.height
                    y += frame.origin.y
                    let cgPoint = CGPoint(x: x, y:  y)
                    points.append(cgPoint)
                    prevX = x
                    prevY = y
                    maxSlice = 0
                } else {
                    if y > maxSlice {
                        maxSlice = y
                    }
                    y *= frame.size.height
                    y += frame.origin.y
                }
            }
            
            var cgLastPoint = CGPoint(x: frame.maxX, y: y)
            points.append(cgLastPoint)
            cgLastPoint = CGPoint(x: frame.maxX, y: frame.origin.y)
            points.append(cgLastPoint)
            
            var cgFirstPoint = CGPoint(x: firstX, y: frame.origin.y)
            points.insert(cgFirstPoint, at: 0)
            cgFirstPoint = CGPoint(x: frame.minX, y: frame.origin.y)
            points.insert(cgFirstPoint, at: 0)
            
            let closingPath: CGMutablePath = CGMutablePath()
            closingPath.addLines(between: points)
            
            return closingPath
            
        }
        
        return nil
        
    }
    
}
