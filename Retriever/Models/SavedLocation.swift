//
//  SavedLocation.swift
//  Retriever
//
//  Created by Thomas Tseng on 2023/10/15.
//

import Foundation
import SwiftData

@Model
class SavedLocation {
    @Attribute(.unique)
    var title: String
    var latitude: Double
    var longitude: Double
    var locationTitle: String
    var locationSubtitle: String
    var type: String
    var isDelete: Bool
    
    init(latitude: Double, longitude: Double, locationTitle: String, locationSubtitle: String, title: String, type: String) {
        self.latitude = latitude
        self.longitude = longitude
        self.locationTitle = locationTitle
        self.locationSubtitle = locationSubtitle
        self.title = title
        self.type = type
        self.isDelete = false
    }
}
