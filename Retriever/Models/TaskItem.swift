//
//  TaskItem.swift
//  Retriever
//
//  Created by Thomas Tseng on 2023/9/22.
//

import Foundation
import SwiftData

@Model
class TaskItem {
    var title: String
    var notes: String
    var priority: String
    var date: Date
    var time: Date
    var dateCreated: Date
    var routine: [Int]
    var endDate: Date
    var routineTime: Date
    var completedDates: [Date]
    var latitude: Double
    var longitude: Double
    var locationTitle: String
    var locationSubtitle: String
    var notificationKey: String
    var isCompleted: Bool
    var isDateEnabled: Bool
    var isTimeEnabled: Bool
    var isRepeatEnabled: Bool
    var isEndDateEnabled: Bool
    var isRoutineTimeEnabled: Bool
    var isTimeNotificationEnabled: Bool
    var isLocationNotificationEnabled: Bool
    var isExpanded: Bool
    var isDelete: Bool
    
    @Relationship(deleteRule: .nullify, inverse: \Category.tasks)
    var category: Category?
    
    init(title: String, notes: String, priority: String, date: Date, time: Date, routine: [Int], endDate: Date, routineTime: Date, latitude: Double, longitude: Double, locationTitle: String, locationSubtitle: String, isDateEnabled: Bool, isTimeEnabled: Bool, isRepeatEnabled: Bool, isEndDateEnabled: Bool, isRoutineTimeEnabled: Bool, isTimeNotificationEnabled: Bool, isLocationNotificationEnabled: Bool) {
        self.title = title
        self.notes = notes
        self.priority = priority
        self.date = date
        self.time = time
        self.routine = routine
        self.endDate = endDate
        self.routineTime = routineTime
        self.latitude = latitude
        self.longitude = longitude
        self.locationTitle = locationTitle
        self.locationSubtitle = locationSubtitle
        self.isDateEnabled = isDateEnabled
        self.isTimeEnabled = isTimeEnabled
        self.isRepeatEnabled = isRepeatEnabled
        self.isEndDateEnabled = isEndDateEnabled
        self.isRoutineTimeEnabled = isRoutineTimeEnabled
        self.isTimeNotificationEnabled = isTimeNotificationEnabled
        self.isLocationNotificationEnabled = isLocationNotificationEnabled
        self.dateCreated = Date.now
        self.notificationKey = title + " " + Date.now.formatted(date: .complete, time: .complete)
        self.completedDates = []
        self.isCompleted = false
        self.isExpanded = true
        self.isDelete = false
    }
}
