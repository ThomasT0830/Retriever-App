//
//  Item.swift
//  ToDoLocation
//
//  Created by Thomas Tseng on 2023/9/16.
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
