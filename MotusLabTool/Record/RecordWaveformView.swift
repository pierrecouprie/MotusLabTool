//
//  RecordWaveformView.swift
//  MotusLabTool
//
//  Created by Pierre Couprie on 08/09/2019.
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
                let waveformData = try NSKeyedUnarchiver.unarchive(data: data,
                                                                   of: NSArray.self) as? [[Float]]
                self.playWaveformView.waveform = waveformData!
                self.playTimeRulerView.duration = selectedPlaylistFile.duration
                self.playTimeRulerView.setNeedsDisplay(self.playTimeRulerView.bounds)
            } catch let error as NSError {
                Swift.print("RecordWaveformView: loadPlaylistFile() Error opening waveform to url \(String(describing: waveformURL)), context: " + error.localizedDescription)
            }
            
        }
    }
    
    override func mouseDown(with event: NSEvent) {
        let mouse = self.convert(event.locationInWindow, from: nil)
        if let playlistFileIndex = self.windowController.playlistSelectedFileIndex, let firstIndex = playlistFileIndex.first {
            let selectedPlaylistFile = self.windowController.playlistFiles[firstIndex]
            let timePosition = (Float(mouse.x) * selectedPlaylistFile.duration) / Float(self.bounds.size.width)
            if self.leftViewController.windowController.currentMode == Mode.playlist {
                self.leftViewController.recordAudioPlayer.audioPlayer.currentTime = Double(timePosition)
            } else {
                self.leftViewController.windowController.timePosition = timePosition
            }
        }
    }
    
}
