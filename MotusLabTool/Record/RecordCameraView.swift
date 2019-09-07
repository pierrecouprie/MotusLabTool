//
//  RecordCameraView.swift
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

class RecordCameraView: NSView {
    
    weak var leftViewController: LeftViewController!
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        self.wantsLayer = true
        self.layer = CALayer()
        
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
