//
//  PlayMarkersView.swift
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

let kMarkerLabelSize: CGFloat = 12

class PlayMarkersView: NSView {
    
    weak var leftViewController: LeftViewController! 
    
    let preferences = UserDefaults.standard
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        
        self.wantsLayer = true
    }
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
    }
    
    override var isFlipped: Bool {
        return true
    }
    
    override func draw(_ dirtyRect: NSRect) {
        if let context = NSGraphicsContext.current?.cgContext, let leftViewController = self.leftViewController, let color = preferences.data(forKey: PreferenceKey.playMarkerColor)?.color {
            
            context.saveGState()
            context.setStrokeColor(color.cgColor)
            
            for marker in leftViewController.currentSession.markers {
                
                let x = (CGFloat(marker.date) * self.bounds.size.width) / CGFloat(self.leftViewController.currentSession.duration)
                context.move(to: CGPoint(x: x, y: 0))
                context.addLine(to: CGPoint(x: x, y: self.bounds.size.height))
                
                self.drawLabel(context, label: marker.title, x: x, color: color)
                
            }
            
            context.drawPath(using: .stroke)
            context.restoreGState()
        }
    }
    
    func drawLabel(_ context: CGContext, label: String, x: CGFloat, color: NSColor) {
        
        context.saveGState()
        
        var textRect = self.frame
        textRect.origin.x = x + 4
        textRect.origin.y += 5
        
        let font = NSFont.systemFont(ofSize: kMarkerLabelSize)
        
        let textStyle = NSMutableParagraphStyle()
        textStyle.alignment = .left
        
        let textFontAttributes = [
            NSAttributedString.Key.font: font,
            NSAttributedString.Key.foregroundColor: color,
            NSAttributedString.Key.paragraphStyle: textStyle,
        ]
        
        label.draw(in: textRect, withAttributes: textFontAttributes)
        
        context.restoreGState()
    }
}
