//
//  NotificationManager.swift
//  Retriever
//
//  Created by Thomas Tseng on 2023/10/22.
//

import Foundation
import UserNotifications
import SwiftUI
import CoreLocation

class NotificationManager {
    static let instance = NotificationManager()
    
    func requestAuthorization() {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        
        UNUserNotificationCenter.current().requestAuthorization(options: options) { (success, error) in
        }
    }
    
    func checkPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                self.requestAuthorization()
            case .denied:
                print("Denied")
            case .authorized:
                print("Success")
            case .provisional:
                print("Provisional")
            case .ephemeral:
                print("Ephermeral")
            @unknown default:
                print("Unknown")
            }
        }
    }
    
    func setBadgeNumber(_ number: Int) {
        UNUserNotificationCenter.current().setBadgeCount(number)
    }
    
    func manageNotification(_ task: TaskItem, _ settings: AppSettings) {
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [task.notificationKey, task.notificationKey + "T", task.notificationKey + "L", task.notificationKey + "1", task.notificationKey + "2", task.notificationKey + "3", task.notificationKey + "4", task.notificationKey + "5", task.notificationKey + "6", task.notificationKey + "7"])
        
        if !isTaskCompleted(task) && !task.isDelete {
            if task.isTimeNotificationEnabled && settings.isEnableTimeNotification == "Enable" {
                let content = UNMutableNotificationContent()
                if let category = task.category {
                    content.title = task.title + " (" + category.title + ")"
                }
                else {
                    content.title = task.title
                }
                content.sound = .default
                
                if task.isDateEnabled {
                    let year = Calendar.current.component(.year, from: task.date)
                    let month = Calendar.current.component(.month, from: task.date)
                    let day = Calendar.current.component(.day, from: task.date)
                    if task.isTimeEnabled {
                        content.subtitle = task.date.formatted(date: .abbreviated, time: .omitted) + " (" + task.time.formatted(date: .omitted, time: .shortened) + ")"
                        var dateComponents = DateComponents()
                        let hour = Calendar.current.component(.hour, from: task.time)
                        let minute = Calendar.current.component(.minute, from: task.time)
                        dateComponents.year = year
                        dateComponents.month = month
                        dateComponents.day = day
                        dateComponents.hour = hour
                        dateComponents.minute = minute
                        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
                        let request = UNNotificationRequest(identifier: task.notificationKey + "T", content: content, trigger: trigger)
                        notificationCenter.add(request)
                    }
                    else {
                        content.subtitle = task.date.formatted(date: .abbreviated, time: .omitted)
                        var dateComponents = DateComponents()
                        let hour = Calendar.current.component(.hour, from: settings.notificationTime)
                        let minute = Calendar.current.component(.minute, from: settings.notificationTime)
                        dateComponents.year = year
                        dateComponents.month = month
                        dateComponents.day = day
                        dateComponents.hour = hour
                        dateComponents.minute = minute
                        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
                        let request = UNNotificationRequest(identifier: task.notificationKey + "T", content: content, trigger: trigger)
                        notificationCenter.add(request) { error in
                            notificationCenter.getPendingNotificationRequests { requests in
                                print(requests.count)
                                print(requests)
                            }
                        }
                    }
                }
                else if task.isRepeatEnabled {
                    var routineDays: String {
                        if task.routine == [1, 7] {
                            return "Weekends"
                        }
                        else if task.routine == [2, 3, 4, 5, 6] {
                            return "Weekdays"
                        }
                        else if task.routine.count == 7 {
                            return "Daily"
                        }
                        var days = ""
                        for day in task.routine {
                            if task.routine.count == 1 {
                                days.append(numToDayShort(day))
                            }
                            else if task.routine.lastIndex(of: day) == task.routine.count - 1 {
                                days.append("and " + numToDayShort(day))
                            }
                            else {
                                if task.routine.count > 2 {
                                    days.append(numToDayShort(day) + ", ")
                                }
                                else {
                                    days.append(numToDayShort(day) + " ")
                                }
                            }
                        }
                        return days.trimmingCharacters(in: .whitespaces)
                    }
                    if task.isRoutineTimeEnabled {
                        content.subtitle = routineDays + " Routine (" + task.routineTime.formatted(date: .omitted, time: .shortened) + ")"
                        let hour = Calendar.current.component(.hour, from: task.routineTime)
                        let minute = Calendar.current.component(.minute, from: task.routineTime)
                        for routineDay in task.routine {
                            var dateComponents = DateComponents()
                            dateComponents.weekday = routineDay
                            dateComponents.hour = hour
                            dateComponents.minute = minute
                            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                            let request = UNNotificationRequest(identifier: task.notificationKey + String(routineDay), content: content, trigger: trigger)
                            
                            notificationCenter.add(request)
                        }
                    }
                    else {
                        content.subtitle = routineDays + " Routine"
                        let hour = Calendar.current.component(.hour, from: settings.notificationTime)
                        let minute = Calendar.current.component(.minute, from: settings.notificationTime)
                        for routineDay in task.routine {
                            var dateComponents = DateComponents()
                            dateComponents.weekday = routineDay
                            dateComponents.hour = hour
                            dateComponents.minute = minute
                            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                            let request = UNNotificationRequest(identifier: task.notificationKey + String(routineDay), content: content, trigger: trigger)
                            notificationCenter.add(request)
                        }
                    }
                }
            }
            
            if task.isLocationNotificationEnabled && settings.isEnableLocationNotification == "Enable" {
                let content = UNMutableNotificationContent()
                if let category = task.category {
                    content.title = task.title + " (" + category.title + ")"
                }
                else {
                    content.title = task.title
                }
                content.sound = .default
                var subtitle = "Your task is nearby"
                if task.locationTitle != "" {
                    subtitle += (" at " + task.locationTitle + ".")
                }
                else if task.locationSubtitle != "" {
                    subtitle += (" at " + task.locationSubtitle + ".")
                }
                else {
                    subtitle += "!"
                }
                content.subtitle = subtitle
                let center = CLLocationCoordinate2D(latitude: task.latitude, longitude: task.longitude)
                let region = CLCircularRegion(center: center, radius: settings.notificationDistance, identifier: task.locationTitle)
                region.notifyOnEntry = true
                region.notifyOnExit = false
                let trigger = UNLocationNotificationTrigger(region: region, repeats: true)
                let request = UNNotificationRequest(identifier: task.notificationKey + "L", content: content, trigger: trigger)
                notificationCenter.add(request)
            }
        }
        notificationCenter.getPendingNotificationRequests { requests in
            print(requests.count)
            print(requests)
        }
    }
    
    func isTaskCompleted(_ task: TaskItem) -> Bool {
        return (task.isRepeatEnabled && (isTaskRoutineCompleted(task))) || (!task.isRepeatEnabled && task.isCompleted)
    }
    
    func isDayRoutineCompleted(_ task: TaskItem, _ day: Date) -> Bool {
        return task.completedDates.contains(where: { isSameDate($0, day) })
    }
    
    func isTaskRoutineCompleted(_ task: TaskItem) -> Bool {
        return nextRoutineDay(task) == nil && lastRoutineDay(task) == nil
    }
    
    func nextRoutineDay(_ task: TaskItem) -> Date? {
        var nextDate: Date = Date.now
        if task.isEndDateEnabled {
            while isSameDate(nextDate, task.endDate) || nextDate < task.endDate {
                if !isDayRoutineCompleted(task, nextDate) && task.routine.contains(dayToNum(nextDate.format("EEEE"))) {
                    return nextDate
                }
                nextDate = Calendar.current.date(byAdding: .day, value: 1, to: nextDate)!
            }
        }
        else {
            while true {
                if !isDayRoutineCompleted(task, nextDate) && task.routine.contains(dayToNum(nextDate.format("EEEE"))) {
                    return nextDate
                }
                nextDate = Calendar.current.date(byAdding: .day, value: 1, to: nextDate)!
            }
        }
        return nil
    }
    
    func lastRoutineDay(_ task: TaskItem) -> Date? {
        var lastDate: Date = Calendar.current.date(byAdding: .day, value: -1, to: Date.now)!
        
        while isSameDate(lastDate, task.dateCreated) || lastDate > task.dateCreated {
            if !isDayRoutineCompleted(task, lastDate) && task.routine.contains(dayToNum(lastDate.format("EEEE"))) {
                return lastDate
            }
            lastDate = Calendar.current.date(byAdding: .day, value: -1, to: lastDate)!
        }
        return nil
    }
    
    func isSameDate(_ date1: Date, _ date2: Date) -> Bool {
        return Calendar.current.isDate(date1, inSameDayAs: date2)
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
}
