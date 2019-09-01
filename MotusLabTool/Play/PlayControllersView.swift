//
//  PlayControllersView.swift
//  MotusLabTool
//
//  Created by Pierre Couprie on 01/09/2019.
//  Copyright © 2019 Pierre Couprie. All rights reserved.
//

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
    var controllersList = [ControllerItem]()
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
        
        //Add observer to detect preferences properties
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
            self.setNeedsDisplay(self.bounds)
        }
    }
    
    func convertEvents() {
        var output = [Int:[(date: Float, value: Int)]]()
        self.controllersList = []
        
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
                            self.consoleBStartId = self.controllersList.count
                        }
                    }
                    self.controllersList.append(controllerItem)
                    maxNumber = n + start
                }
            }
            return maxNumber
        }
        
        //Create indexes
        self.consoleAMaxNumber = readControllers(self.leftViewController.currentSession.consoleAControllers)
        let _ = readControllers(self.leftViewController.currentSession.consoleBControllers, start: self.consoleAMaxNumber)
        
        //Create id in controllersList {
        for n in 0..<self.controllersList.count{
            self.controllersList[n].id = n
        }
        
        //Read controllers
        for controller in self.leftViewController.windowController.midiControllerEvents {
            let newEvent = (date: controller.date, value: controller.value)
            var number = controller.number
            if controller.console == 1 {
                number += self.consoleAMaxNumber
            }
            output[number]?.append(newEvent)
        }
        
        self.controllers = output
        self.setNeedsDisplay(self.bounds)
        
    }
    
    override func draw(_ dirtyRect: NSRect) {
        
        guard self.controllers != nil && self.leftViewController != nil && self.leftViewController.windowController.midiControllerEvents != nil && self.leftViewController.windowController.midiControllerEvents.count > 0 else {
            return
        }
        
        if let context = NSGraphicsContext.current?.cgContext {
            let controllerCount = self.controllersList.filter( { $0.show == true } ).count
            let height: CGFloat = self.bounds.size.height / CGFloat(controllerCount)
            let heightTranslation: CGFloat = height
            
            var yTranslation: CGFloat = 0.0
            for n in stride(from: self.controllersList.count - 1, through: 0, by: -1) {
                let controllerItem = self.controllersList[n]
                
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
                
                self.drawPath(context: context, curveClosePath: drawingPath, color: self.selectColor(controllerItem))
                
                yTranslation += heightTranslation
            }
            
        }
    }
    
    /**
     Draw a path from a serie
     - parameter context: CGContext
     - parameter curvePath: the path to draw
     - parameter height: the height of view
     - parameter yTranslation: the y center position of serie
     */
    func drawPath(context: CGContext, curveClosePath: CGPath, color: NSColor) {
        
        context.saveGState()
        
        context.setFillColor(color.cgColor)
        context.setLineWidth(1)
        context.setLineJoin(CGLineJoin.miter)
        
        context.addPath(curveClosePath)
        context.drawPath(using: CGPathDrawingMode.fill)
        
        context.restoreGState()
        
    }
    
    /**
     Create the path to draw from data
     - parameter channel: Channel to draw, nil for mixed channels
     - returns: The path to draw
     */
    func CurvePath(frame: NSRect, controller: Int) -> CGPath? {
        
        if let leftViewController = self.leftViewController, let currentSession = leftViewController.currentSession, let controllers = self.controllers {
            
            guard controllers[controller]!.count > 0 else {
                return nil
            }
            
            var points = [CGPoint]()
            var x: CGFloat = 0
            var y: CGFloat = frame.origin.y
            var prevX: CGFloat = -1
            var maxSlice: CGFloat = 0
            for position in controllers[controller]! {
                
                x = (CGFloat(position.date) * self.bounds.width) / CGFloat(currentSession.duration)
                y = CGFloat(MIDIValueCorrection(position.value, type: self.midiValueCorrection)) / 128
                
                if x >= prevX + 1 {
                    if y < maxSlice {
                        y = maxSlice
                    }
                    y *= frame.size.height
                    y += frame.origin.y
                    let cgPoint = CGPoint(x: x, y:  y)
                    points.append(cgPoint)
                    prevX = x
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
            
            y = CGFloat(controllers[controller]!.first!.value) / 128
            y *= frame.size.height
            y += frame.origin.y
            x = frame.minX
            var cgFirstPoint = CGPoint(x: x, y: y)
            points.insert(cgFirstPoint, at: 0)
            cgFirstPoint = CGPoint(x: x, y: frame.origin.y)
            points.insert(cgFirstPoint, at: 0)
            
            let closingPath: CGMutablePath = CGMutablePath()
            closingPath.addLines(between: points)
            
            return closingPath
            
        }
        
        return nil
        
    }
    
    func selectColor(_ controller: ControllerItem) -> NSColor {
        
        if !controller.enable {
            return NSColor.gray
        }
        
        if let windowController = self.leftViewController.windowController {
            if controller.console == 0 {
                return windowController.consoleAControllerColors[controller.number]!
            } else if controller.console == 1 {
                return windowController.consoleBControllerColors[controller.number]!
            }
        }
        
        return NSColor.gray
        
    }
    
}
