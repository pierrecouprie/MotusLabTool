//
//  VideoUtilities.swift
//  MotusLabTool
//
//  Created by Pierre Couprie on 14/08/2024.
//  Copyright © 2024 Pierre Couprie. All rights reserved.
//

import Foundation
import AVFoundation

protocol VideoUtilities { }

extension VideoUtilities {
    func videoRotation(_ layer: CALayer) {
        let preferences = UserDefaults.standard
        if preferences.bool(forKey: PreferenceKey.movieRotation) {
            layer.transform = CATransform3DMakeAffineTransform(CGAffineTransformMakeRotation(CGFloat.pi))
        }
    }
}
