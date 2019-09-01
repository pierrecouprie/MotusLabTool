//
//  RecordCameraView.swift
//  MotusLabTool
//
//  Created by Pierre Couprie on 01/09/2019.
//  Copyright © 2019 Pierre Couprie. All rights reserved.
//

import Cocoa

class RecordCameraView: NSView {
    
    weak var leftViewController: LeftViewController!
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        self.wantsLayer = true
        self.layer = CALayer()
        //self.layer?.backgroundColor = NSColor(named: "paneBackground")?.cgColor
        
    }
    
    override func mouseDown(with event: NSEvent) {
        self.enterFullScreen()
    }
    
    /// Use a new view to render the camera in fullscreen
    /// Avoid an issue with constraints in record and play views
    func enterFullScreen() {
        let _ = PreviewCameraView(originView: self)
    }
    
}
