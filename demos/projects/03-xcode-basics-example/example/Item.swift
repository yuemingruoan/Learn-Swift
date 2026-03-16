//
//  Item.swift
//  example
//
//  Created by 时雨 on 2026/3/16.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
