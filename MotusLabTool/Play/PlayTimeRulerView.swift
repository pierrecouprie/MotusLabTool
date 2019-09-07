//
//  PlayTimeRulerView.swift
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

class PlayTimeRulerView: NSView {
    
    var duration: Float = 10
    
    override func draw(_ dirtyRect: NSRect) {
        if let context = NSGraphicsContext.current?.cgContext {
            self.drawRuler(context: context, bounds: self.bounds, visibleRect: self.bounds)
        }
    }
    
    /**
     Draw a time ruler vwith primary and secondary divisions
     - parameter context: CGContext
     - parameter bounds: The bounds of view
     - parameter visibleRect: Draw only this frame
     - parameter duration: Main duration
     - parameter bgColor: Background color
     - parameter fgColor: Color of graduations and texts
     - parameter targetX: Start position of visibleRect (only used when export)
     */
    func drawRuler(context: CGContext, bounds: CGRect, visibleRect: CGRect, targetX: CGFloat = 0) {
        
        //Calcul de l'espace temporel minimal
        let minSpace: CGFloat = 80
        let minSpaceString = self.stringSize("00:00:000")
        let step: CGFloat = (minSpace * CGFloat(self.duration)) / bounds.width
        
        //variables de la vue
        var startX: CGFloat = visibleRect.minX
        let endX: CGFloat = visibleRect.maxX
        let width: CGFloat = bounds.size.width
        let height: CGFloat = bounds.size.height
        
        //Variables d'affichage
        let smallHeight = bounds.size.height * 0.3
        let largeHeight = bounds.size.height * 0.7
        let textY = bounds.size.height * 0.1
        let textX: CGFloat = 4.0
        
        var timeStep: CGFloat = 1.0
        var smallTimeStep: CGFloat = 1.0
        let displayTenth: Bool = false
        
        /*if step < 0.1 { //Affichage par 1 èmes -> trop lent!
         timeStep = 0.1
         smallTimeStep = 0.01
         //displayTenth = true
         } else*/
        if step < 0.5 { //Affichage par 5 èmes
            timeStep = 1.0
            smallTimeStep = 0.1
        } else if step < 1 { //Affichage par 1 seconde
            timeStep = 1.0
            smallTimeStep = 0.5
        } else if step < 5 { //Affichage par 5 secondes
            timeStep = 5.0
            smallTimeStep = 1.0
        } else if step < 10 { //Affichage par 10 secondes
            timeStep = 10.0
            smallTimeStep = 1.0
        } else if step < 15 { //Affichage par 15 secondes
            timeStep = 15.0
            smallTimeStep = 1.0
        } else if step < 30 { //Affichage par 30 secondes
            timeStep = 30.0
            smallTimeStep = 15.0
        } else if step < 60 { //Affichage par minutes
            timeStep = 60.0
            smallTimeStep = 15.0
        } else if step < 300 { //Affichage par 5 minutes
            timeStep = 300.0
            smallTimeStep = 60.0
        } else if step < 600 { //Affichage par 10 minutes
            timeStep = 600.0
            smallTimeStep = 60.0
        } else if step < 1800 { //Affichage par 30 minutes
            timeStep = 1800.0
            smallTimeStep = 900.0
        } else { //Affichage par heures
            timeStep = 3600.0
            smallTimeStep = 1800.0
        }
        
        //Dessin
        context.saveGState()
        
        //I draw background
        context.setFillColor(NSColor(named: "paneBackground")!.cgColor)
        context.addRect(bounds)
        context.drawPath(using: CGPathDrawingMode.fill)
        
        //Propriétés des traits
        context.setStrokeColor(NSColor(named: "textForeground")!.cgColor)
        context.setLineWidth(1)
        
        //To draw one primary graduation before the visibility (used when export)
        let stepX: CGFloat = (CGFloat(timeStep) * width) / CGFloat(self.duration)
        startX -= stepX
        
        var unit:CGFloat = 0
        repeat {
            
            let x: CGFloat = (CGFloat(unit) * width) / CGFloat(self.duration)
            
            if case startX..<endX = x {
                
                //Dessin des graduations principales
                let string = self.doubleToTimeRuler(CGFloat(unit), displayTenth: displayTenth)
                self.drawLine(context, x: x - targetX, y: height, size: largeHeight)
                
                if x + minSpaceString.width + 5 <= endX {
                    self.drawText(context, x: x + textX - targetX, y: textY, string: string, color: NSColor(named: "textForeground")!)
                }
                
                //Dessin des graduations secondaires
                var smallUnit: CGFloat = unit+smallTimeStep
                repeat {
                    let x: CGFloat = (CGFloat(smallUnit) * width) / CGFloat(self.duration)
                    self.drawLine(context, x: x - targetX, y: height, size: smallHeight)
                    smallUnit += smallTimeStep
                } while smallUnit < unit + timeStep
                
            }
            
            unit += timeStep
            
        } while unit < CGFloat(self.duration)
        
        context.restoreGState()
        
    }
    
    func doubleToTimeRuler(_ value: CGFloat, displayTenth: Bool) -> String {
        
        let seconds: Int = Int(floor(value).truncatingRemainder(dividingBy: 60))
        let minutes: Int = Int((floor(value)/60).truncatingRemainder(dividingBy: 60))
        let hours: Int = Int(floor(value)/3600)
        let tenth: Int = Int((value - floor(value)) * 100)
        
        let tenthStr: String = NSString(format: "%02d", tenth) as String
        let secondsStr: String = NSString(format: "%02d", seconds) as String
        let minutesStr: String = NSString(format: "%02d", minutes) as String
        let hoursStr: String = String(hours)
        
        var counterString:String = ""
        
        if hours != 0 {
            counterString += hoursStr + ":"
        }
        
        counterString += minutesStr + ":" + secondsStr
        
        if displayTenth == true {
            counterString += "." + tenthStr
        }
        
        return counterString
        
    }
    
    func drawLine(_ context: CGContext, x: CGFloat, y: CGFloat, size: CGFloat) {
        context.move(to: CGPoint(x: x, y: y))
        context.addLine(to: CGPoint(x: x, y: y-size))
        context.drawPath(using: CGPathDrawingMode.stroke)
    }
    
    func drawText(_ context: CGContext, x: CGFloat, y: CGFloat, string: String, color: NSColor) {
        let aFont = NSFont.systemFont(ofSize: 11)
        let attributs = [NSAttributedString.Key.font: aFont, NSAttributedString.Key.foregroundColor: color]
        context.setTextDrawingMode(CGTextDrawingMode.fill)
        let text = CFAttributedStringCreate(nil, string as CFString?, attributs as CFDictionary)
        let line = CTLineCreateWithAttributedString(text!)
        context.textPosition = CGPoint(x: x, y: y)
        CTLineDraw(line, context)
    }
    
    func stringSize(_ string: String) -> CGSize {
        
        let font = NSFont.systemFont(ofSize: 11)
        let textAttributes = [NSAttributedString.Key.font: font]
        let rect = string.boundingRect(with: NSSize(width: CGFloat.infinity, height: CGFloat.infinity),
                                       options: .usesLineFragmentOrigin,
                                       attributes: textAttributes)
        
        return rect.size
        
    }
    
}
