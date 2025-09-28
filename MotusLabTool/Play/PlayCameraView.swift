//
//  PlayCameraView.swift
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
import AVFoundation

class PlayCameraView: NSView {
    
    weak var avPlayer: AVPlayer!
    var avPlayerLayer: AVPlayerLayer!
    var videoIsFlipped: Bool = false
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.wantsLayer = true
    }
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
    }
    
    func loadAVPlayer(_ avPlayer: AVPlayer?) {
        if let avp = avPlayer {
            
            // Add AVPlayerLayer
            self.avPlayer = avPlayer
            self.avPlayerLayer = AVPlayerLayer(player: avp)
            self.avPlayerLayer.frame = self.bounds
            self.avPlayerLayer.videoGravity = .resizeAspect
            self.layer = CALayer()
            self.layer!.addSublayer(self.avPlayerLayer)
            self.avPlayerLayer.addInLayerContraints(superlayer: self.layer!)
            self.layer!.layoutManager = CAConstraintLayoutManager()
            
            // Add button to flip video
            let button = NSButton(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
            button.bezelStyle = .regularSquare
            //button.image = NSImage(systemSymbolName: "arrow.trianglehead.up.and.down.righttriangle.up.righttriangle.down", accessibilityDescription: nil)
            button.image = NSImage(systemSymbolName: "arrow.up.arrow.down.square", accessibilityDescription: nil)
            button.imageScaling = .scaleNone
            button.setButtonType(.onOff)
            button.target = self
            button.action = #selector(self.flipVideo)
            self.addSubview(button)
            button.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint(item: self, attribute: .top, relatedBy: .equal, toItem: button, attribute: .top, multiplier: 1.0, constant: -10.0).isActive = true
            NSLayoutConstraint(item: self, attribute: .left, relatedBy: .equal, toItem: button, attribute: .left, multiplier: 1.0, constant:-10.0).isActive = true
            NSLayoutConstraint(item: button, attribute: .width, relatedBy: .equal, toItem: .none, attribute: .notAnAttribute, multiplier: 1.0, constant: 24).isActive = true
            NSLayoutConstraint(item: button, attribute: .height, relatedBy: .equal, toItem: .none, attribute: .notAnAttribute, multiplier: 1.0, constant: 24).isActive = true
        } else {
            if let subLayer = self.layer?.sublayers?.first {
                subLayer.removeFromSuperlayer()
            }
        }
    }
    
    /// Flip video in vertical axis
    @objc func flipVideo() {
        self.videoIsFlipped.toggle()
        if self.videoIsFlipped {
            self.avPlayerLayer.transform = CATransform3DMakeAffineTransform(CGAffineTransformMakeRotation(CGFloat.pi))
        } else {
            self.avPlayerLayer.transform = CATransform3DMakeAffineTransform(CGAffineTransformMakeRotation(0))
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        self.layer?.backgroundColor = NSColor(named: "paneBackground")!.cgColor
    }
    
    override func mouseDown(with event: NSEvent) {
        self.enterFullScreen()
    }
    
    /// Create a new view in fullscreen mode (avoid issue with constraints)
    func enterFullScreen() {
        let _ = PreviewCameraView(originView: self, avPlayer: self.avPlayer)
    }
    
}
