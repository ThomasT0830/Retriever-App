//
//  HomeView.swift
//  Retriever
//
//  Created by Thomas Tseng on 2023/9/16.
//

import SwiftUI
import SwiftData
import CoreLocation
import MapKit

struct HomeView: View {
    @Environment(\.modelContext) var context
    @EnvironmentObject var mapViewModel: MapViewModel
    @EnvironmentObject var tabManager: TabManager

    @Query private var tasks: [TaskItem]
    
    @Namespace private var animation
    
    @Bindable var settings: AppSettings
    
    @StateObject var locationManager = LocationManager()
    
    @State var routeCoordinate: CLLocationCoordinate2D? = nil
    @State var backToDefault = false
    @State var change = false
    @State var transportType: String = "automobile"
    
    @State private var selectedTask: TaskItem? = nil
    @State private var sortType: String = "Distance"
    
    var filteredTasks: [TaskItem] {
        let filtered = tasks.compactMap { task in
            return !isTaskCompleted(task) ? task : nil
        }
        return sort(filtered, locationManager)
    }
    
    var myMap: MapViewRepresentable {
        MapViewRepresentable(enabled: true, fixedCoordinate: nil, routeCoordinate: $routeCoordinate, backToDefault: $backToDefault, change: $change, transportType: $transportType)
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                ZStack {
                    GeometryReader { geometry in
                        VStack(spacing: 0){
                            ZStack (alignment: .bottomTrailing){
                                myMap
                            }
                            .frame(height: geometry.size.height * 0.45)
                            .padding(.bottom, 0)
                            HStack(spacing: 20){
                                Picker(selection: $transportType, label: Text("Transport Type")) {
                                    Text("Automobile").tag("automobile")
                                    Text("Walk").tag("walk")
                                    Text("Transit").tag("transit")
                                }
                                .pickerStyle(.segmented)
                                .onChange(of: transportType, initial: false) { _, _ in
                                    change = true
                                }
                                Button {
                                    change = true
                                } label: {
                                    Image(systemName: "arrow.clockwise")
                                        .foregroundStyle(.blue)
                                        .background(.white, in: Circle())
                                }
                            }
                            .padding()
                            .padding(.horizontal)
                            .frame(maxWidth: .infinity)
                            .background(.white)
                            TaskView()
                                .padding([.horizontal, .bottom])
                                .padding([.bottom])
                                .padding([.bottom])
                                .animation(.easeIn, value: filteredTasks)
                        }
                    }
                    .background(Color(Color.backgroundColor))
                    .ignoresSafeArea()
                }
                .onAppear {
                    routeCoordinate = nil
                    selectedTask = nil
                    backToDefault = true
                }
            }
        }
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
            ScrollViewReader { reader in
                ScrollView(showsIndicators: false) {
                    VStack {
                        HStack {
                        }
                        .padding(.top)
                        VStack(spacing: 0) {
                            ForEach(filteredTasks) { task in
                                if (!settings.isHideOnCompletionList || !isTaskCompleted(task)) {
                                    TaskViewCell(task, settings)
                                        .animation(.snappy(duration: 0.5), value: task.isExpanded)
                                }
                            }
                        }
                        HStack {
                        }
                        .padding(.bottom, 40)
                        .padding(.bottom)
                        .padding(.bottom)
                        .padding(.bottom)
                    }
                    .id("Scroll View")
                }
                .onChange(of: selectedTask, initial: false) { oldValue, newValue in
                    if newValue != nil  {
                        withAnimation {
                            reader.scrollTo("Scroll View", anchor: .top)
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    func TaskViewCell(_ task: TaskItem, _ settings: AppSettings) -> some View {
        HStack(alignment: .top, spacing: 15) {
            TaskViewBar(task)
            VStack {
                Button {
                    if !isSelectedTask(task) {
                        selectedTask = task
                        change = true
                        routeCoordinate = CLLocationCoordinate2D(latitude: task.latitude, longitude: task.longitude)
                    }
                    else {
                        selectedTask = nil
                        routeCoordinate = nil
                        backToDefault = true
                    }
                } label : {
                    VStack {
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
                if selectedTask == task {
                    NavigationLink(destination: DetailView(settings: settings, task: task)) {
                        TaskViewMoreBlock(task)
                    }
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
                        .opacity(!isSelectedTask(task) ? 0.6 : 1)
                }
                else {
                    Circle()
                        .stroke(convertColorString(task.category?.colorString ?? settings.uncategorizedColorString).gradient, lineWidth: 3)
                        .frame(width: 12, height: 12)
                        .opacity(!isSelectedTask(task) ? 0.6 : 1)
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
                    .opacity(!isSelectedTask(task) ? 0.6 : 1)
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
                        .foregroundColor(convertColorString(task.category?.colorString ?? settings.uncategorizedColorString))
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
            convertColorString(task.category?.colorString ?? settings.uncategorizedColorString).opacity(!isSelectedTask(task) ? 0.6 : 1).gradient
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
                            .font(.system(size: 12))
                            .fontWeight(.bold)
                    }
                    .padding(10)
                    .background(.white, in: RoundedRectangle(cornerRadius: 15))
                }
            }
        }
        .foregroundStyle(.white)
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            convertColorString(task.category?.colorString ?? settings.uncategorizedColorString).opacity(!isSelectedTask(task) ? 0.6 : 1).gradient
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
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Button {
                    toggleTask(task, true)
                } label: {
                    Image(systemName: "checkmark")
                        .foregroundStyle(isTaskCompleted(task) ? .black : .white)
                        .font(.system(size: 12))
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
            convertColorString(task.category?.colorString ?? settings.uncategorizedColorString).opacity(!isSelectedTask(task) ? 0.6 : 1).gradient
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    @ViewBuilder
    func TaskViewMoreBlock(_ task: TaskItem) -> some View {
        VStack {
            HStack(alignment: .center, spacing: 8) {
                HStack {
                    Text("More Details")
                        .fontWeight(.bold)
                    Image(systemName: "arrow.right")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            convertColorString(task.category?.colorString ?? settings.uncategorizedColorString).opacity(!isSelectedTask(task) ? 0.6 : 1).gradient
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
        if isTaskCompleted(task) && task == selectedTask {
            selectedTask = nil
            routeCoordinate = nil
            backToDefault = true
        }
        if isTaskItemCompleted(task) && settings.isDeleteOnCompletion {
            task.isDelete = true
            NotificationManager.instance.manageNotification(task, settings)
            context.delete(task)
        }
    }
    
    func isSelectedTask(_ task: TaskItem) -> Bool {
        if let chosenTask = selectedTask {
            if chosenTask == task {
                return true
            }
        }
        return false
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
    
    func sort(_ tasks: [TaskItem], _ locationManager: LocationManager) -> [TaskItem] {
        return tasks.sorted(by: {
            (isSelectedTask($0) ? 0 : 1, CLLocation(latitude: $0.latitude, longitude: $0.longitude).distance(from: CLLocation(latitude: locationManager.userLocation?.latitude ?? 0, longitude: locationManager.userLocation?.longitude ?? 0))) <
            
            (isSelectedTask($1) ? 0 : 1, CLLocation(latitude: $1.latitude, longitude: $1.longitude).distance(from: CLLocation(latitude: locationManager.userLocation?.latitude ?? 0, longitude: locationManager.userLocation?.longitude ?? 0)))}
        )
    }
}

