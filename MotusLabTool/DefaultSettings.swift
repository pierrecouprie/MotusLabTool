//
//  DefaultSettings.swift
//  MotusLabTool
//
//  Created by Pierre Couprie on 28/08/2019.
//  Copyright © 2019 Pierre Couprie. All rights reserved.
//

import Foundation

struct Mode {
    static let record = "record"
    static let play = "play"
    
    static func modeFrom(_ index: Int) -> String {
        if index == 0 {
            return Mode.record
        }
        return Mode.play
    }
}
