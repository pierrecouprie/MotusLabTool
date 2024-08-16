//
//  VuMeterView.swift
//  MotusLabTool-Remote
//
//  Created by Pierre Couprie on 06/08/2024.
//  Copyright © 2024 Pierre Couprie. All rights reserved.
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

import Foundation
import UIKit

class VuMeterView: UIView {
    
    var shapeLayer: CALayer!
    
    var levels: [Float] = [0,0] {
        didSet {
            self.layer.setNeedsDisplay()
        }
    }
    
    override func display(_ layer: CALayer) {
        
        let sLayer = self.shapeLayer ?? CALayer()
        
        let vuMeterWidth: CGFloat = self.bounds.size.width / CGFloat(self.levels.count)
        var vuMeterFrame = CGRect(x: 0,
                                  y: 0,
                                  width: vuMeterWidth,
                                  height: 0)
        
        //Display amplitude values
        for (index,level) in self.levels.enumerated() {
            
            if sLayer.sublayers == nil || sLayer.sublayers!.count < index + 1 {
                let vuLayer = CAShapeLayer()
                sLayer.addSublayer(vuLayer)
            }
            
            // Compute size
            var height = (CGFloat(level) * self.bounds.size.height) / 100
            height = height >= 0 ? height : 0
            vuMeterFrame.origin.x = CGFloat(index) * vuMeterWidth
            vuMeterFrame.size.height = height
            vuMeterFrame.origin.y = self.bounds.size.height - height
            let vuLayer = sLayer.sublayers![index]
            vuLayer.frame = vuMeterFrame
            
            // Compute color depending on level
            vuLayer.updateColor(value: level)
            
        }
        
        if self.shapeLayer == nil {
            sLayer.frame = self.bounds
            self.shapeLayer = sLayer
            self.shapeLayer.drawsAsynchronously = true
            self.layer.addSublayer(sLayer)
        }
        
    }
    
}
