//
//  CalendarView.swift
//  Retriever
//
//  Created by Thomas Tseng on 2023/10/9.
//

import SwiftUI
import SwiftData
import CoreLocation

struct TaskListView: View {
    @Environment(\.modelContext) var context
    @EnvironmentObject var tabManager: TabManager
    
    @Query private var tasks: [TaskItem]
    
    @Namespace private var animation
    
    @Bindable var settings: AppSettings
    
    @StateObject var locationManager = LocationManager()
    
    @State private var sortType: String = "Distance"
    
    var filteredTasks: [TaskItem] {
        let filtered = tasks.compactMap { task in
            return (!settings.isHideOnCompletionList || !isTaskCompleted(task)) ? task : nil
        }
        return sort(on: sortType, filtered, locationManager)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HeaderView()
                    .padding([.horizontal], 15)
                    .padding(.bottom)
                    .background(Color.white)
                TaskView()
                    .padding([.horizontal, .bottom])
                    .animation(.easeIn, value: filteredTasks)
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .background(Color.backgroundColor)
        }
        .background(Color(Color.backgroundColor))
        .onAppear {
            if settings.isExpandCellOnDefault {
                expandAllCells(tasks)
            }
            else {
                shrinkAllCells(tasks)
            }
            tabManager.turnOn()
        }
    }
    
    @ViewBuilder
    func HeaderView() -> some View {
        VStack(spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 5){
                        Text(Date().formatted(date: .complete, time: .omitted))
                    }
                    .font(.callout)
                    .font(.body)
                    .fontWeight(.semibold)
                    .textScale(.secondary)
                    .foregroundStyle(.gray)
                    HStack(spacing: 5) {
                        Text("Tasks")
                            .font(.title.bold())
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                HStack(spacing: 35){
                    Menu {
                        Picker("", selection: $sortType) {
                            Label("Distance", systemImage: "location")
                                .tag("Distance")
                            Label("Title", systemImage: "textformat.size.larger")
                                .tag("Title")
                            Label("Category", systemImage: "list.triangle")
                                .tag("Category")
                            Label("Priority", systemImage: "exclamationmark")
                                .tag("Priority")
                            Label("Date and Time", systemImage: "calendar")
                                .tag("Time")
                        }
                        .labelsHidden()
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease")
                    }
                    NavigationLink(destination: CreateTaskView(settings: settings)) {
                        Image(systemName: "plus")
                    }
                }
                .frame(alignment: .trailing)
            }
            .padding([.horizontal, .top])
        }
    }
    
    @ViewBuilder
    func TaskView() -> some View {
        if filteredTasks == [] {
            VStack(alignment: .center) {
                Text("No task remaining!")
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 30)
            .frame(maxHeight: .infinity)
        }
        else{
            ScrollView(showsIndicators: false) {
                HStack {
                }
                .padding(.top)
                VStack(spacing: 0) {
                    ForEach(filteredTasks) { task in
                        TaskViewCell(task, settings)
                            .animation(.snappy(duration: 0.5), value: task.isExpanded)
                    }
                }
                HStack {
                }
                .padding(.bottom, 40)
                .padding(.bottom)
                .padding(.bottom)
                .padding(.bottom)
            }
        }
    }
    
    @ViewBuilder
    func TaskViewCell(_ task: TaskItem, _ settings: AppSettings) -> some View {
        HStack(alignment: .top, spacing: 15) {
            TaskViewBar(task)
            NavigationLink(destination: DetailView(settings: settings, task: task)) {
                if task.isExpanded {
                    if task.isRepeatEnabled && nextRoutineDay(task) != nil && lastRoutineDay(task) != nil {
                        VStack {
                            TaskViewExpandedBlock(task)
                            TaskViewReverseBlock(task)
                        }
                    }
                    else {
                        TaskViewExpandedBlock(task)
                    }
                }
                else {
                    TaskViewShrinkedBlock(task)
                }
            }
        }
        .padding([.horizontal, .top])
        .padding(.trailing, -5)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    func TaskViewBar(_ task: TaskItem) -> some View {
        VStack(spacing: 0) {
            Button {
                if task.isExpanded {
                    task.isExpanded = false
                }
                else {
                    for t in filteredTasks {
                        t.isExpanded = false
                    }
                }
            } label: {
                if task.isExpanded {
                    Circle()
                        .fill(convertColorString(task.category?.colorString ?? settings.uncategorizedColorString).gradient)
                        .frame(width: 12, height: 12)
                        .opacity(isTaskCompleted(task) ? 0.5 : 1)
                }
                else {
                    Circle()
                        .stroke(convertColorString(task.category?.colorString ?? settings.uncategorizedColorString).gradient, lineWidth: 3)
                        .frame(width: 12, height: 12)
                        .opacity(isTaskCompleted(task) ? 0.5 : 1)
                }
            }
            Button {
                if !task.isExpanded {
                    task.isExpanded = true
                }
                else {
                    for t in filteredTasks {
                        t.isExpanded = true
                    }
                }
            } label: {
                RoundedRectangle(cornerRadius: 50)
                    .fill(convertColorString(task.category?.colorString ?? settings.uncategorizedColorString).gradient)
                    .frame(width: 4)
                    .opacity(isTaskCompleted(task) ? 0.5 : 1)
            }
        }
    }
    
    @ViewBuilder
    func TaskViewExpandedBlock(_ task: TaskItem) -> some View {
        VStack(spacing: 15) {
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        if task.priority == "High" {
                            Text("!!!")
                                .font(.title3.bold())
                                .multilineTextAlignment(.leading)
                        }
                        else if task.priority == "Medium" {
                            Text("!!")
                                .font(.title3.bold())
                                .multilineTextAlignment(.leading)
                        }
                        else if task.priority == "Low" {
                            Text("!")
                                .font(.title3.bold())
                                .multilineTextAlignment(.leading)
                        }
                        Text(task.title)
                            .font(.title3.bold())
                            .multilineTextAlignment(.leading)
                            .strikethrough(isTaskCompleted(task))
                    }
                    if task.locationTitle != "" {
                        Text(task.locationTitle)
                            .font(.body)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if task.category != nil {
                    Text(task.category?.title ?? "")
                        .foregroundColor(convertColorString(task.category?.colorString ?? Color.gray.description))
                        .font(.caption.bold())
                        .padding(.vertical, 5)
                        .padding(.horizontal, 15)
                        .background(.white, in: RoundedRectangle(cornerRadius: 5))
                }
            }
            HStack {
                HStack(spacing: 8) {
                    if locationManager.userLocation?.latitude != nil && locationManager.userLocation?.longitude != nil {
                        HStack(spacing: 5) {
                            Image(systemName: "mappin.and.ellipse")
                                .font(.system(size: 15))
                            let distance = CLLocation(latitude: locationManager.userLocation?.latitude ?? 0, longitude: locationManager.userLocation?.longitude ?? 0).distance(from: CLLocation(latitude: task.latitude, longitude: task.longitude))
                            Text(formatDistance(distance))
                        }
                    }
                    if task.isDateEnabled || task.isRepeatEnabled  {
                        HStack(spacing: 5) {
                            if task.isDateEnabled {
                                Image(systemName: "calendar")
                                Text(task.date.format("MMM d"))
                                    .font(.headline)
                            }
                            else {
                                if !isTaskCompleted(task) {
                                    Image(systemName: "calendar")
                                    if let nextDay = nextRoutineDay(task) {
                                        Text(nextDay.format("MMM d"))
                                            .font(.headline)
                                    }
                                    else if let lastDay = lastRoutineDay(task) {
                                        Text(lastDay.format("MMM d"))
                                            .font(.headline)
                                    }
                                }
                            }
                        }
                    }
                    if task.isRepeatEnabled {
                        Image(systemName: "repeat")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Button {
                    toggleTask(task, (task.isRepeatEnabled && nextRoutineDay(task) == nil))
                } label: {
                    Image(systemName: "checkmark")
                        .foregroundStyle(isTaskCompleted(task) ? .black : .white)
                        .font(.system(size: 14))
                        .fontWeight(.bold)
                }
                .padding(10)
                .background(.white, in: RoundedRectangle(cornerRadius: 15))
            }
        }
        .foregroundStyle(.white)
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            convertColorString(task.category?.colorString ?? settings.uncategorizedColorString).opacity(isTaskCompleted(task) ? 0.5 : 1).gradient
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    @ViewBuilder
    func TaskViewShrinkedBlock(_ task: TaskItem) -> some View {
        VStack {
            HStack(alignment: .center, spacing: 8) {
                HStack {
                    HStack (spacing: 8){
                        if task.priority == "High" {
                            Text("!!!")
                                .font(.callout.bold())
                                .multilineTextAlignment(.leading)
                        }
                        else if task.priority == "Medium" {
                            Text("!!")
                                .font(.callout.bold())
                                .multilineTextAlignment(.leading)
                        }
                        else if task.priority == "Low" {
                            Text("!")
                                .font(.callout.bold())
                                .multilineTextAlignment(.leading)
                        }
                        Text(task.title)
                            .font(.callout.bold())
                            .multilineTextAlignment(.leading)
                            .strikethrough(isTaskCompleted(task))
                    }
                    if task.category != nil {
                        Text(task.category?.title ?? "")
                            .foregroundColor(convertColorString(task.category?.colorString ?? settings.uncategorizedColorString))
                            .font(.caption.bold())
                            .padding(.vertical, 5)
                            .padding(.horizontal, 15)
                            .background(.white, in: RoundedRectangle(cornerRadius: 5))
                    }
                    if task.isRepeatEnabled {
                        Image(systemName: "repeat")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if !task.isRepeatEnabled {
                    Button {
                        toggleTask(task)
                    } label: {
                        Image(systemName: "checkmark")
                            .foregroundStyle(isTaskCompleted(task) ? .black : .white)
                            .font(.system(size: 10))
                            .fontWeight(.bold)
                    }
                    .padding(8)
                    .background(.white, in: RoundedRectangle(cornerRadius: 15))
                }
            }
        }
        .foregroundStyle(.white)
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            convertColorString(task.category?.colorString ?? settings.uncategorizedColorString).opacity(isTaskCompleted(task) ? 0.5 : 1).gradient
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    @ViewBuilder
    func TaskViewReverseBlock(_ task: TaskItem) -> some View {
        VStack {
            HStack(alignment: .center, spacing: 8) {
                HStack {
                    Text("Task Uncompleted On: " + (lastRoutineDay(task)?.format("MMM d") ?? ""))
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Button {
                    toggleTask(task, true)
                } label: {
                    Image(systemName: "checkmark")
                        .foregroundStyle(isTaskCompleted(task) ? .black : .white)
                        .font(.system(size: 10))
                        .fontWeight(.bold)
                }
                .padding(8)
                .background(.white, in: RoundedRectangle(cornerRadius: 15))
            }
        }
        .foregroundStyle(.white)
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            convertColorString(task.category?.colorString ?? settings.uncategorizedColorString).opacity(isTaskCompleted(task) ? 0.5 : 1).gradient
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    func toggleTask(_ task: TaskItem, _ reverse: Bool = false) {
        if task.isRepeatEnabled {
            if reverse {
                if let lastDay = lastRoutineDay(task) {
                    task.completedDates.append(lastDay)
                }
            }
            else {
                if let nextDay = nextRoutineDay(task) {
                    task.completedDates.append(nextDay)
                }
            }
        }
        else {
            task.isCompleted.toggle()
            if task.isCompleted {
                task.isExpanded = false
            }
            else {
                task.isExpanded = true
            }
        }
        NotificationManager.instance.manageNotification(task, settings)
        if isTaskItemCompleted(task) && settings.isDeleteOnCompletion {
            task.isDelete = true
            NotificationManager.instance.manageNotification(task, settings)
            context.delete(task)
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
    
    func sort(on option: String, _ tasks: [TaskItem], _ locationManager: LocationManager) -> [TaskItem] {
        if option == "Title" {
            return tasks.sorted(by: {
                (isTaskCompleted($0) ? 1 : 0, $0.title, CLLocation(latitude: $0.latitude, longitude: $0.longitude).distance(from: CLLocation(latitude: locationManager.userLocation?.latitude ?? 0, longitude: locationManager.userLocation?.longitude ?? 0))) <
                    (isTaskCompleted($1) ? 1 : 0, $1.title, CLLocation(latitude: $1.latitude, longitude: $1.longitude).distance(from: CLLocation(latitude: locationManager.userLocation?.latitude ?? 0, longitude: locationManager.userLocation?.longitude ?? 0)))}
            )
        }
        else if option == "Category" {
            return tasks.sorted(by: {
                (isTaskCompleted($0) ? 1 : 0, $0.category != nil ? 0 : 1, ($0.category?.title ?? ""), CLLocation(latitude: $0.latitude, longitude: $0.longitude).distance(from: CLLocation(latitude: locationManager.userLocation?.latitude ?? 0, longitude: locationManager.userLocation?.longitude ?? 0))) <
                
                (isTaskCompleted($1) ? 1 : 0, $1.category != nil ? 0 : 1, ($1.category?.title ?? ""), CLLocation(latitude: $1.latitude, longitude: $1.longitude).distance(from: CLLocation(latitude: locationManager.userLocation?.latitude ?? 0, longitude: locationManager.userLocation?.longitude ?? 0)))}
            )
        }
        else if option == "Priority" {
            return tasks.sorted(by: {
                (isTaskCompleted($0) ? 1 : 0, $0.priority == "High" ? 0 : ($0.priority == "Medium") ? 1 : ($0.priority == "Low" ? 2 : 3), CLLocation(latitude: $0.latitude, longitude: $0.longitude).distance(from: CLLocation(latitude: locationManager.userLocation?.latitude ?? 0, longitude: locationManager.userLocation?.longitude ?? 0))) <
                
                (isTaskCompleted($1) ? 1 : 0, $1.priority == "High" ? 0 : ($1.priority == "Medium") ? 1 : ($1.priority == "Low" ? 2 : 3), CLLocation(latitude: $1.latitude, longitude: $1.longitude).distance(from: CLLocation(latitude: locationManager.userLocation?.latitude ?? 0, longitude: locationManager.userLocation?.longitude ?? 0)))}
            )
        }
        else if option == "Time" {
            return tasks.sorted(by: {
                (isTaskCompleted($0) ? 1 : 0, $0.isDateEnabled || $0.isRepeatEnabled ? 0 : 1, $0.isDateEnabled ? $0.date : nextRoutineDay($0) ?? lastRoutineDay($0) ?? Date.now, ($0.isDateEnabled && $0.isTimeEnabled) || ($0.isRepeatEnabled && $0.isRoutineTimeEnabled) ? 0 : 1, $0.isTimeEnabled ? $0.time : $0.routineTime, CLLocation(latitude: $0.latitude, longitude: $0.longitude).distance(from: CLLocation(latitude: locationManager.userLocation?.latitude ?? 0, longitude: locationManager.userLocation?.longitude ?? 0))) <
                    
                (isTaskCompleted($1) ? 1 : 0, $1.isDateEnabled || $1.isRepeatEnabled ? 0 : 1, $1.isDateEnabled ? $1.date : nextRoutineDay($1) ?? lastRoutineDay($1) ?? Date.now, ($1.isDateEnabled && $1.isTimeEnabled) || ($1.isRepeatEnabled && $1.isRoutineTimeEnabled) ? 0 : 1 , $1.isTimeEnabled ? $1.time : $1.routineTime, CLLocation(latitude: $1.latitude, longitude: $1.longitude).distance(from: CLLocation(latitude: locationManager.userLocation?.latitude ?? 0, longitude: locationManager.userLocation?.longitude ?? 0)))}
            )
        }
        else{
            return tasks.sorted(by: {
                (isTaskCompleted($0) ? 1 : 0, CLLocation(latitude: $0.latitude, longitude: $0.longitude).distance(from: CLLocation(latitude: locationManager.userLocation?.latitude ?? 0, longitude: locationManager.userLocation?.longitude ?? 0))) <
                
                (isTaskCompleted($1) ? 1 : 0, CLLocation(latitude: $1.latitude, longitude: $1.longitude).distance(from: CLLocation(latitude: locationManager.userLocation?.latitude ?? 0, longitude: locationManager.userLocation?.longitude ?? 0)))}
            )
        }
    }
}
