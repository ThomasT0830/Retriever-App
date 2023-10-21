//
//  ViewExtension.swift
//  Retriever
//
//  Created by Thomas Tseng on 2023/10/7.
//

import Foundation
import SwiftUI

extension View {
    func isSameDate(_ date1: Date, _ date2: Date) -> Bool {
        return Calendar.current.isDate(date1, inSameDayAs: date2)
    }
    
    func convertColorString(_ colorString: String) -> Color {
        let colors: [Color] = [.red, .pink, .orange, .yellow, .green, .mint, .teal, .cyan, .blue, .indigo, .purple, .brown, .gray, .black]
        for color in colors {
            if (colorString == color.description) {
                return color
            }
        }
        return .blue
    }
    
    func numToDay(_ num: Int) -> String {
        let days: [String] = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        return days[num - 1]
    }
    
    func numToDayShort(_ num: Int) -> String {
        let days: [String] = ["Sun", "Mon", "Tues", "Wed", "Thurs", "Fri", "Sat"]
        return days[num - 1]
    }
    
    func dayToNum(_ day: String) -> Int {
        let days: [String] = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        return (days.firstIndex(of: day) ?? 0) + 1
    }
    
    func formatDistance(_ distance: Double) -> String {
        let meterFormatter = NumberFormatter()
        let kilometerFormatter = NumberFormatter()
        
        meterFormatter.maximumFractionDigits = 0
        kilometerFormatter.usesSignificantDigits = true
        kilometerFormatter.maximumSignificantDigits = 3
        kilometerFormatter.minimumSignificantDigits = 3
        
        if distance < 1000 {
            return (meterFormatter.string(from: distance as NSNumber) ?? "") + " m"
        }
        else {
            return (kilometerFormatter.string(from: (distance / 1000) as NSNumber) ?? "") + " km"
        }
    }
    
    func expandAllCells(_ tasks: [TaskItem]) {
        for task in tasks {
            task.isExpanded = true
        }
    }
    
    func shrinkAllCells(_ tasks: [TaskItem]) {
        for task in tasks {
            task.isExpanded = false
        }
    }
    
    func isTaskItemCompleted(_ task: TaskItem) -> Bool {
        return (task.isRepeatEnabled && (isTaskRoutineItemCompleted(task))) || (!task.isRepeatEnabled && task.isCompleted)
    }
    
    func isDayRoutineItemCompleted(_ task: TaskItem, _ day: Date) -> Bool {
        return task.completedDates.contains(where: { isSameDate($0, day) })
    }
    
    func isTaskRoutineItemCompleted(_ task: TaskItem) -> Bool {
        return nextRoutineItemDay(task) == nil && lastRoutineItemDay(task) == nil
    }
    
    func nextRoutineItemDay(_ task: TaskItem) -> Date? {
        var nextDate: Date = Date.now
        if task.isEndDateEnabled {
            while isSameDate(nextDate, task.endDate) || nextDate < task.endDate {
                if !isDayRoutineItemCompleted(task, nextDate) && task.routine.contains(dayToNum(nextDate.format("EEEE"))) {
                    return nextDate
                }
                nextDate = Calendar.current.date(byAdding: .day, value: 1, to: nextDate)!
            }
        }
        else {
            while true {
                if !isDayRoutineItemCompleted(task, nextDate) && task.routine.contains(dayToNum(nextDate.format("EEEE"))) {
                    return nextDate
                }
                nextDate = Calendar.current.date(byAdding: .day, value: 1, to: nextDate)!
            }
        }
        return nil
    }
    
    func lastRoutineItemDay(_ task: TaskItem) -> Date? {
        var lastDate: Date = Calendar.current.date(byAdding: .day, value: -1, to: Date.now)!
        
        while isSameDate(lastDate, task.dateCreated) || lastDate > task.dateCreated {
            if !isDayRoutineItemCompleted(task, lastDate) && task.routine.contains(dayToNum(lastDate.format("EEEE"))) {
                return lastDate
            }
            lastDate = Calendar.current.date(byAdding: .day, value: -1, to: lastDate)!
        }
        return nil
    }
}
