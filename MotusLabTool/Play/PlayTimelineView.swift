//
//  PlayTimelineView.swift
//  MotusLabTool
//
//  Created by Pierre Couprie on 01/09/2019.
//  Copyright © 2019 Pierre Couprie. All rights reserved.
//

import Cocoa

let kHRulerSize: CGFloat = 15

class PlayTimelineView: NSView {
    
    var leftViewController: LeftViewController! {
        didSet {
            self.playControllersView.leftViewController = self.leftViewController
            self.playMarkersView.leftViewController = self.leftViewController
            self.playPlayheadView.leftViewController = self.leftViewController
        }
    }
    
    var playWaveformView: PlayWaveformView!
    var playControllersView: PlayControllersView!
    var playMarkersView: PlayMarkersView!
    var playPlayheadView: PlayPlayheadView!
    var playTimeRulerView: PlayTimeRulerView!
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        self.wantsLayer = true
        
        //Create subviews
        self.playWaveformView = PlayWaveformView(frame: self.bounds)
        self.addSubview(self.playWaveformView)
        self.playTimeRulerView = PlayTimeRulerView(frame: self.bounds)
        self.addSubview(self.playTimeRulerView)
        self.playControllersView = PlayControllersView(frame: self.bounds)
        self.addSubview(self.playControllersView)
        self.playMarkersView = PlayMarkersView(frame: self.bounds)
        self.addSubview(self.playMarkersView)
        self.playPlayheadView = PlayPlayheadView(frame: self.bounds)
        self.addSubview(self.playPlayheadView)
        
        //hide/show views
        self.updatePreferencesProperties()
        
        //Add contraints to subviews
        for subview in self.subviews {
            subview.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint(item: self, attribute: .left, relatedBy: .equal, toItem: subview, attribute: .left, multiplier: 1.0, constant:0.0).isActive = true
            NSLayoutConstraint(item: self, attribute: .right, relatedBy: .equal, toItem: subview, attribute: .right, multiplier: 1.0, constant: 0.0).isActive = true
            if let _ = subview as? PlayTimeRulerView {
                NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: .equal, toItem: subview, attribute: .bottom, multiplier: 1.0, constant: 0.0).isActive = true
                NSLayoutConstraint(item: subview, attribute: .height, relatedBy: .equal, toItem: .none, attribute: .notAnAttribute, multiplier: 1.0, constant: kHRulerSize).isActive = true
            } else {
                NSLayoutConstraint(item: self, attribute: .top, relatedBy: .equal, toItem: subview, attribute: .top, multiplier: 1.0, constant: 0.0).isActive = true
                NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: .equal, toItem: subview, attribute: .bottom, multiplier: 1.0, constant: kHRulerSize).isActive = true
            }
        }
        
        //Add observer to detect preferences properties
        NotificationCenter.default.addObserver(self, selector: #selector(userDefaultsDidChange), name: UserDefaults.didChangeNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func userDefaultsDidChange(_ notification: Notification) {
        self.updatePreferencesProperties()
    }
    
    func updatePreferencesProperties() {
        let preferences = UserDefaults.standard
        self.playWaveformView.isHidden = !preferences.bool(forKey: PreferenceKey.playTimelineWaveform)
        self.playControllersView.isHidden = !preferences.bool(forKey: PreferenceKey.playTimelineControllers)
        self.playMarkersView.isHidden = !preferences.bool(forKey: PreferenceKey.playTimelineMarkers)
        self.playMarkersView.setNeedsDisplay(self.playMarkersView.bounds)
        self.playPlayheadView.isHidden = !preferences.bool(forKey: PreferenceKey.playTimelinePlayhead)
        self.playPlayheadView.updateColor()
    }
    
    override func draw(_ dirtyRect: NSRect) {
        self.layer?.backgroundColor = NSColor(named: "paneBackground")!.cgColor
    }
    
    override func mouseDown(with event: NSEvent) {
        let mouse = self.convert(event.locationInWindow, from: nil)
        let position = (Float(mouse.x) * self.leftViewController.currentSession.duration) / Float(self.bounds.width)
        self.leftViewController.goToTime(position)
    }
}

