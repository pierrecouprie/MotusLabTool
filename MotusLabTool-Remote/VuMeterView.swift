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
    
    var vuMeterLeftLayer: CALayer!
    var vuMeterRightLayer: CALayer!
    
    var levels: [Float] = [0,0] {
        didSet {
            self.layer.setNeedsDisplay()
        }
    }
    
    override func display(_ layer: CALayer) {
        
        let vmLLayer = vuMeterLeftLayer ?? CALayer()
        let vmRLayer = vuMeterRightLayer ?? CALayer()
        
        let lSize = self.bounds.size.height * CGFloat((levels[0] / 100))
        let rSize = self.bounds.size.height * CGFloat((levels[1] / 100))
        
        let rectangleL = CGRect(x: 0,
                                y: self.bounds.size.height - lSize,
                                width: self.bounds.size.width / 2,
                                height: lSize)
        let rectangleR = CGRect(x: self.bounds.size.width / 2,
                                y: self.bounds.size.height - rSize,
                                width: self.bounds.size.width / 2,
                                height: rSize)
        vmLLayer.frame = rectangleL
        self.updateColor(vmLLayer, value: Float(levels[0]))
        vmRLayer.frame = rectangleR
        self.updateColor(vmRLayer, value: Float(levels[1]))
        
        if vuMeterLeftLayer == nil {
            self.layer.sublayers?.removeAll()
            
            vmLLayer.backgroundColor = UIColor.green.cgColor
            vuMeterLeftLayer = vmLLayer
            self.layer.addSublayer(vmLLayer)
            
            vmRLayer.backgroundColor = UIColor.green.cgColor
            vuMeterRightLayer = vmRLayer
            self.layer.addSublayer(vmRLayer)
            
            let newActions = ["frame": NSNull(),
                              "bounds": NSNull(),
                              "position": NSNull()]
            vmLLayer.actions = newActions
            vmRLayer.actions = newActions
        }
    }
    
    func updateColor(_ layer: CALayer, value: Float) {
        var color = UIColor.green
        if value >= kVuMeterCritical {
            color = UIColor.red
        } else if value >= kVuMeterWarning {
            color = UIColor.orange
        }
        layer.backgroundColor = color.cgColor
    }
    
}
