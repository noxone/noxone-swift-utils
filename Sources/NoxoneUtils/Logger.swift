//
//  Logger.swift
//  
//
//  Created by Olaf Neumann on 01.08.23.
//

import SwiftUI
import os.log

public extension Logger {
    public init(category: String) {
        self.init(subsystem: Bundle.main.bundleIdentifier!, category: category)
    }
}

