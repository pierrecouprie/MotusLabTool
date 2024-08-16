//
//  TypeAlias.swift
//  MotusLabTool
//
//  Created by Pierre Couprie on 15/08/2024.
//  Copyright © 2024 Pierre Couprie. All rights reserved.
//

import Foundation
#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

#if os(macOS)
typealias MLTColor = NSColor
#elseif os(iOS)
typealias MLTColor = UIColor
#endif
