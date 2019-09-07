//
//  PlayPlayheadView.swift
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

let kPlayheadWidth: CGFloat = 2

class PlayPlayheadView: NSView {
    
    @objc dynamic weak var leftViewController: LeftViewController! {
        didSet {
            //Add Observer for timePosition
            let timePositionPath = \WindowController.timePosition
            self.timePositionObservation = self.leftViewController.windowController.observe(timePositionPath) { [unowned self] object, change in
                self.updateTimePosition()
            }
        }
    }
    
    var timePositionObservation: NSKeyValueObservation?
    var playheadView: PlayheadView!
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        
        self.playheadView = PlayheadView(frame: self.bounds)
        self.addSubview(self.playheadView)
        self.playheadView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint(item: self.playheadView!, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: 0.0).isActive = true
        NSLayoutConstraint(item: self.playheadView!, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: 0.0).isActive = true
        self.updateTimePosition()
        self.updateColor()
    }
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
    }
    
    override func resize(withOldSuperviewSize oldSize: NSSize) {
        self.updateTimePosition()
    }
    
    func updateTimePosition() {
        if let leftViewController = self.leftViewController, let currentSession = leftViewController.currentSession {
            if leftViewController.windowController.displayedView == 2 {
                let x = (CGFloat(leftViewController.windowController.timePosition) * self.bounds.size.width) / CGFloat(currentSession.duration)
                let frame = CGRect(x: x, y: 0, width: kPlayheadWidth, height: self.bounds.size.height)
                self.playheadView.frame = frame
            }
        } else {
            self.playheadView.frame = CGRect(x: 0, y: 0, width: kPlayheadWidth, height: self.bounds.size.height)
        }
    }
    
    func updateColor() {
        let preferences = UserDefaults.standard
        self.playheadView.layer?.backgroundColor = preferences.data(forKey: PreferenceKey.playPlayheadColor)?.color.cgColor
    }
    
}

class PlayheadView: NSView {
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        
        self.wantsLayer = true
        self.layer!.backgroundColor = NSColor.red.cgColor
    }
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
    }
    
}
