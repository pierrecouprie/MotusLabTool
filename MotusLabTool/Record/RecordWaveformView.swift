//
//  RecordWaveformView.swift
//  MotusLabTool
//
//  Created by Pierre Couprie on 08/09/2019.
//  Copyright © 2019 Pierre Couprie. All rights reserved.
//

import Cocoa

class RecordWaveformView: NSView {
    
    var windowController: WindowController!
    var leftViewController: LeftViewController! {
        didSet {
            self.playPlayheadView.leftViewController = self.leftViewController
        }
    }
    
    var playWaveformView: PlayWaveformView!
    var playPlayheadView: PlayPlayheadView!
    var playTimeRulerView: PlayTimeRulerView!
    
    var playlistIndexObservation: NSKeyValueObservation?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor(named: "paneBackground")!.cgColor
        
        // Create subviews
        self.playWaveformView = PlayWaveformView(frame: self.bounds, color: 1)
        self.addSubview(self.playWaveformView)
        self.playTimeRulerView = PlayTimeRulerView(frame: self.bounds)
        self.addSubview(self.playTimeRulerView)
        self.playPlayheadView = PlayPlayheadView(frame: self.bounds)
        self.addSubview(self.playPlayheadView)
        
        // hide/show views
        self.playPlayheadView.updateColor()
        
        // Add contraints to subviews
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
    }
    
    func initialize(_ windowController: WindowController) {
        self.windowController = windowController
        self.leftViewController = windowController.leftViewController
        
        self.playPlayheadView.playlistPlayhead = true
        self.playPlayheadView.leftViewController = self.leftViewController
        
        //Initialize observers
        let playlistIndexPath = \WindowController.playlistSelectedFileIndex
        self.playlistIndexObservation = self.leftViewController.windowController.observe(playlistIndexPath) { [unowned self] object, change in
            self.loadPlaylistFile()
        }
    }
    
    func loadPlaylistFile() {
        if let playlistFileIndex = self.windowController.playlistSelectedFileIndex, let firstIndex = playlistFileIndex.first {
            let selectedPlaylistFile = self.windowController.playlistFiles[firstIndex]
            
            let waveformURL = self.windowController.playlistFilesFolderPathUrl.appendingPathComponent(selectedPlaylistFile.id).appendingPathExtension(FileExtension.waveform)
            
            do {
                let data = try Data(contentsOf: waveformURL)
                let waveformData = NSKeyedUnarchiver.unarchiveObject(with: data) as! [[Float]]
                self.playWaveformView.waveform = waveformData
                self.playTimeRulerView.duration = selectedPlaylistFile.duration
                self.playTimeRulerView.setNeedsDisplay(self.playTimeRulerView.bounds)
            } catch let error as NSError {
                Swift.print("RecordWaveformView: loadPlaylistFile() Error opening waveform to url \(String(describing: waveformURL)), context: " + error.localizedDescription)
            }
            
        }
    }
    
}
