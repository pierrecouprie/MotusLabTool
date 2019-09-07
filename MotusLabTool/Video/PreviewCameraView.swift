//
//  PreviewCameraView.swift
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

class PreviewCameraView: NSView {
    
    weak var originView: NSView!
    var recordPreview: Bool = true
    
    /// Launch fullscreen view in record mode
    ///
    /// - Parameter originView: The original view
    convenience init(originView: NSView) {
        self.init(frame: originView.frame)
        
        self.originView = originView
        if let layer = originView.layer, let sublayers = layer.sublayers, let previewLayer = sublayers.first {
            self.layer?.addSublayer(previewLayer)
            self.enterFullScreenMode(NSScreen.main!, withOptions: nil)
            previewLayer.frame = self.bounds
        }
    }
    
    /// Launch fullscreen view in play mode
    /// (Create a new AVPlayerLayer)
    ///
    /// - Parameter originView: The original view
    /// - Parameter avPlayer: The video player
    convenience init(originView: NSView, avPlayer: AVPlayer) {
        self.init(frame: originView.frame)
        
        self.recordPreview = false
        let avPlayerLayer = AVPlayerLayer(player: avPlayer)
        avPlayerLayer.videoGravity = .resizeAspect
        self.layer?.addSublayer(avPlayerLayer)
        self.enterFullScreenMode(NSScreen.main!, withOptions: nil)
        avPlayerLayer.frame = self.bounds
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.wantsLayer = true
    }
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
    }
    
    /// Exit fullscreen mode
    override func mouseDown(with event: NSEvent) {
        if self.isInFullScreenMode {
            if self.recordPreview { //Record mode
                if let layer = self.layer, let sublayers = layer.sublayers, let previewLayer = sublayers.first {
                    previewLayer.frame = self.originView.bounds
                    self.originView.layer?.addSublayer(previewLayer)
                    self.exitFullScreenMode(options: nil)
                }
            } else { //Play mode
                self.exitFullScreenMode(options: nil)
            }
        }
    }
}
