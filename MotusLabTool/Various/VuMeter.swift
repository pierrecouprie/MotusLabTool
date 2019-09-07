//
//  VuMeter.swift
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

class VuMeter: NSView {
    
    var channels: Int = 2
    let min: Float = 0
    let max: Float = 100
    let warning: Float = 98 // Orange limit
    let critical: Float = 99 // Red limit
    
    // Array of channel values
    var levels: [Float] = [0,0] {
        didSet {
            self.updateLevels()
        }
    }
    
    var channelViews = [NSView]()
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        self.wantsLayer = true
        
        self.updateChannels()
        self.updateLevels()
    }
    
    func updateChannels() {
        self.subviews.removeAll()
        
        let width: CGFloat = self.bounds.size.width / CGFloat(self.channels)
        var channelFrame = CGRect(x: 0, y: 0, width: width, height: 1)
        for n in 0..<self.channels {
            channelFrame.origin.x = CGFloat(n) * width
            let channelView = NSView(frame: channelFrame)
            self.addSubview(channelView)
        }
        
    }
    
    func updateLevels() {
        for (index,level) in self.levels.enumerated() {
            let height = (CGFloat(level) * self.bounds.size.height) / (CGFloat(max) - CGFloat(min))
            var frame = self.subviews[index].frame
            frame.size.height = height
            self.subviews[index].frame = frame
            self.updateColor(self.subviews[index], value: level)
        }
    }
    
    func updateColor(_ level: NSView, value: Float) {
        var color = NSColor.green
        if value >= self.critical {
            color = NSColor.red
        } else if value >= self.warning {
            color = NSColor.orange
        }
        level.layer?.backgroundColor = color.cgColor
    }
    
    override func resizeSubviews(withOldSize oldSize: NSSize) {
        self.updateLevels()
    }
    
    override func draw(_ dirtyRect: NSRect) {
        self.layer?.backgroundColor = NSColor(named: "paneBackground")!.cgColor
    }
    
}
