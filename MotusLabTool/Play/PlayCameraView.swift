//
//  PlayCameraView.swift
//  MotusLabTool
//
//  Created by Pierre Couprie on 01/09/2019.
//  Copyright © 2019 Pierre Couprie. All rights reserved.
//

import Cocoa
import AVFoundation

class PlayCameraView: NSView {
    
    weak var avPlayer: AVPlayer!
    var avPlayerLayer: AVPlayerLayer!
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.wantsLayer = true
    }
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
    }
    
    func loadAVPlayer(_ avPlayer: AVPlayer?) {
        if let avp = avPlayer {
            self.avPlayer = avPlayer
            self.avPlayerLayer = AVPlayerLayer(player: avp)
            self.avPlayerLayer.frame = self.bounds
            self.avPlayerLayer.videoGravity = .resizeAspect
            self.layer = CALayer()
            self.layer!.addSublayer(self.avPlayerLayer)
            self.avPlayerLayer.addInLayerContraints(superlayer: self.layer!)
            self.layer!.layoutManager = CAConstraintLayoutManager()
        } else {
            if let subLayer = self.layer?.sublayers?.first {
                subLayer.removeFromSuperlayer()
            }
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
