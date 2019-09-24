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

/// This view contains the playhead as a subview
class PlayPlayheadView: NSView {
    
    @objc dynamic weak var leftViewController: LeftViewController! {
        didSet {
            // Add Observer for timePosition
            let timePositionPath = \WindowController.timePosition
            self.timePositionObservation = self.leftViewController.windowController.observe(timePositionPath) { [unowned self] object, change in
                self.updateTimePosition()
            }
        }
    }
    
    var playlistPlayhead = false
    
    var timePositionObservation: NSKeyValueObservation?
    var playheadView: PlayheadView!
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        
        self.playheadView = PlayheadView(frame: self.bounds)
        self.addSubview(self.playheadView)
        self.playheadView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint(item: self.playheadView!, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: 0.0).isActive = true
        NSLayoutConstraint(item: self.playheadView!, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: 0.0).isActive = true
        
        //Initilialize properties
        self.updateTimePosition()
        self.updateColor()
        
        //Add observer to detect changes in preference properties
        NotificationCenter.default.addObserver(self, selector: #selector(userDefaultsDidChange), name: UserDefaults.didChangeNotification, object: nil)
    }
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    /// Preference properties changes
    @objc func userDefaultsDidChange(_ notification: Notification) {
        self.updateColor()
    }
    
    override func resize(withOldSuperviewSize oldSize: NSSize) {
        self.updateTimePosition()
    }
    
    func updateTimePosition() {
        
        if let leftViewController = self.leftViewController {
            
            if leftViewController.windowController.displayedView == 1 && self.playlistPlayhead && UserDefaults.standard.bool(forKey: PreferenceKey.usePlaylist) {
                
                if leftViewController.windowController.currentMode == Mode.recording {
                    
                    if let currentSession = leftViewController.currentSession {
                        let x = (CGFloat(leftViewController.windowController.timePosition) * self.bounds.size.width) / CGFloat(currentSession.duration)
                        let frame = CGRect(x: x, y: 0, width: kPlayheadWidth, height: self.bounds.size.height)
                        self.playheadView.frame = frame
                    }
                    
                } else if leftViewController.windowController.currentMode == Mode.playlist || leftViewController.windowController.currentMode == Mode.none {
                    if let recordAudioPlayer = leftViewController.recordAudioPlayer, let audioPlayer = recordAudioPlayer.audioPlayer {
                        let x = (CGFloat(leftViewController.windowController.timePosition) * self.bounds.size.width) / CGFloat(audioPlayer.duration)
                        let frame = CGRect(x: x, y: 0, width: kPlayheadWidth, height: self.bounds.size.height)
                        self.playheadView.frame = frame
                    }
                }
                
            } else if leftViewController.windowController.displayedView == 2 {
                
                if let currentSession = leftViewController.currentSession {
                    let x = (CGFloat(leftViewController.windowController.timePosition) * self.bounds.size.width) / CGFloat(currentSession.duration)
                    let frame = CGRect(x: x, y: 0, width: kPlayheadWidth, height: self.bounds.size.height)
                    self.playheadView.frame = frame
                }
                
            }
            
        } else {

            self.playheadView.frame = CGRect(x: 0, y: 0, width: kPlayheadWidth, height: self.bounds.size.height)
            
        }
        
        /*if let leftViewController = self.leftViewController, let currentSession = leftViewController.currentSession {
            if leftViewController.windowController.displayedView == 2 || (leftViewController.windowController.displayedView == 1 && self.playlistPlayhead && UserDefaults.standard.bool(forKey: PreferenceKey.usePlaylist)) {
                let x = (CGFloat(leftViewController.windowController.timePosition) * self.bounds.size.width) / CGFloat(currentSession.duration)
                let frame = CGRect(x: x, y: 0, width: kPlayheadWidth, height: self.bounds.size.height)
                self.playheadView.frame = frame
            }*/
        
        /*if let leftViewController = self.leftViewController, let currentSession = leftViewController.currentSession {
            Swift.print("1 update \(self.leftViewController.windowController.timePosition)")
            if leftViewController.windowController.displayedView == 2 {
                let x = (CGFloat(leftViewController.windowController.timePosition) * self.bounds.size.width) / CGFloat(currentSession.duration)
                let frame = CGRect(x: x, y: 0, width: kPlayheadWidth, height: self.bounds.size.height)
                self.playheadView.frame = frame
            }
        } else if let leftViewController = self.leftViewController {
            Swift.print("2 update \(self.leftViewController.windowController.timePosition)")
            if leftViewController.windowController.displayedView == 1 && self.playlistPlayhead && UserDefaults.standard.bool(forKey: PreferenceKey.usePlaylist) {
                let x = (CGFloat(leftViewController.windowController.timePosition) * self.bounds.size.width) / CGFloat(self.leftViewController.recordAudioPlayer.audioPlayer.duration)
                let frame = CGRect(x: x, y: 0, width: kPlayheadWidth, height: self.bounds.size.height)
                self.playheadView.frame = frame
            }
        } else {
            Swift.print("3 update")
            self.playheadView.frame = CGRect(x: 0, y: 0, width: kPlayheadWidth, height: self.bounds.size.height)
        }*/
    }
    
    func updateColor() {
        self.playheadView.layer?.backgroundColor = UserDefaults.standard.data(forKey: PreferenceKey.playPlayheadColor)?.color.cgColor
    }
    
}

/// Playhead subview
class PlayheadView: NSView {
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        
        self.wantsLayer = true
    }
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
    }
    
}
