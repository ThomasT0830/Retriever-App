//
//  Settings.swift
//  Retriever
//
//  Created by Thomas Tseng on 2023/10/18.
//

import Foundation
import SwiftData
import SwiftUI

@Model
class AppSettings {
    var uncategorizedColorString: String
    var isExpandCellOnDefault: Bool
    
    var isDeleteOnCompletion: Bool
    var isHideOnCompletionCalendar: Bool
    var isHideOnCompletionList: Bool
    
    var isEnableTimeNotification: String
    var isEnableLocationNotification: String
    var isEnableTimeNotificationOnDefault: Bool
    var isEnableLocationNotificationOnDefault: Bool
    
    var isUserLocationSelectedOnDefault: Bool
    var defaultPriority: String
    
    var notificationTime: Date
    var notificationDistance: Double
    
    var sortCalendar: String
    var sortList: String
    
    init() {
        uncategorizedColorString = Color.gray.description
        isExpandCellOnDefault = true
        
        isDeleteOnCompletion = false
        isHideOnCompletionCalendar = false
        isHideOnCompletionList = false
        
        isEnableTimeNotification = "Enable"
        isEnableLocationNotification = "Enable"
        isEnableTimeNotificationOnDefault =  true
        isEnableLocationNotificationOnDefault = true
        
        isUserLocationSelectedOnDefault = true
        defaultPriority = "None"
        
        notificationTime = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date())!
        notificationDistance = 500
        
        sortCalendar = "Distance"
        sortList = "Distance"
    }
}
