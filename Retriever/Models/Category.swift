//
//  Category.swift
//  Retriever
//
//  Created by Thomas Tseng on 2023/10/8.
//

import Foundation
import SwiftData

@Model
class Category {
    @Attribute(.unique)
    var title: String
    var colorString: String
    
    var tasks: [TaskItem]?
    
    init(title: String, colorString: String) {
        self.title = title
        self.colorString = colorString
    }
}
