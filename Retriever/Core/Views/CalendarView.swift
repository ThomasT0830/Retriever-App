//
//  CalendarView.swift
//  Retriever
//
//  Created by Thomas Tseng on 2023/10/1.
//

import SwiftUI
import SwiftData
import CoreLocation

struct CalendarView: View {
    @Environment(\.modelContext) var context
    @EnvironmentObject var tabManager: TabManager
    
    @Query(filter: #Predicate<TaskItem> { $0.isDateEnabled || $0.isRepeatEnabled })
    private var tasks: [TaskItem]
    
    @Namespace private var animation
    
    @Bindable var settings: AppSettings
    
    @StateObject var locationManager = LocationManager()
    
    @State private var selectedDate: Date = .init()
    @State private var weekIndex: Int = 1
    @State private var weekSlider: [[Date.WeekDay]] = []
    @State private var generateWeek: Bool = false

    var filteredTasks: [TaskItem] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE"
        let filtered = tasks.compactMap { task in
            return ((task.isRepeatEnabled && isInSelectedDay(task)) || (task.isDateEnabled && isSameDate(task.date, selectedDate))) && (!settings.isHideOnCompletionCalendar || !isTaskCompleted(task)) ? task : nil
        }
        return sort(on: settings.sortCalendar, filtered, locationManager)
    }
    
    var taskDateStrings: [String] {
        let dates = tasks.compactMap { task in
            return (task.isDateEnabled && (!settings.isHideOnCompletionCalendar || !isTaskCompleted(task))) ? task.date.formatted(date: .complete, time: .omitted) : nil
        }
        return dates
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HeaderView()
                    .padding([.horizontal], 15)
                    .background(Color.white)
                TaskView()
                    .padding([.horizontal, .bottom])
                    .animation(.easeIn, value: filteredTasks)
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .background(Color.backgroundColor)
            .onAppear(perform: {
                if weekSlider.isEmpty {
                    let currentWeek = Date().fetchWeek()
                    
                    if let firstDate = currentWeek.first?.date {
                        weekSlider.append(firstDate.generatePreviousWeek())
                    }
                    weekSlider.append(currentWeek)
                    if let lastDate = currentWeek.last?.date {
                        weekSlider.append(lastDate.generateNextWeek())
                    }
                }
            })
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
                        if !isCurrentWeek(weekSlider) || !isSameDate(selectedDate, Date()) {
                            Text("Back To Today")
                            Image(systemName: "arrow.right")
                                .font(.caption)
                                .padding(.top, 2)
                        }
                        else {
                            Text("Today")
                        }
                    }
                    .font(.callout)
                    .font(.body)
                    .fontWeight(.semibold)
                    .textScale(.secondary)
                    .foregroundStyle(.gray)
                    .onTapGesture {
                        withAnimation(.snappy(duration: 0.8)) {
                            selectedDate = Date()
                            
                            weekSlider.removeAll()
                            let currentWeek = Date().fetchWeek()
                            if let firstDate = currentWeek.first?.date {
                                weekSlider.append(firstDate.generatePreviousWeek())
                            }
                            weekSlider.append(currentWeek)
                            if let lastDate = currentWeek.last?.date {
                                weekSlider.append(lastDate.generateNextWeek())
                            }
                            
                            weekIndex = 1
                            generateWeek = false
                        }
                    }
                    HStack(spacing: 5) {
                        if weekSlider.count > weekIndex {
                            Text(weekSlider[weekIndex].first?.date.format("MMMM") ?? selectedDate.format("MMMM"))
                                .font(.title.bold())
                            Text(weekSlider[weekIndex].first?.date.format("YYYY") ?? selectedDate.format("YYYY"))
                                .font(.title)
                        }
                        else {
                            Text(selectedDate.format("MMMM"))
                                .font(.title.bold())
                            Text(selectedDate.format("YYYY"))
                                .font(.title)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                HStack(spacing: 35){
                    Menu {
                        Picker("", selection: $settings.sortCalendar) {
                            Label("Distance", systemImage: "location")
                                .tag("Distance")
                            Label("Title", systemImage: "textformat.size.larger")
                                .tag("Title")
                            Label("Category", systemImage: "list.triangle")
                                .tag("Category")
                            Label("Priority", systemImage: "exclamationmark")
                                .tag("Priority")
                            Label("Time", systemImage: "clock")
                                .tag("Time")
                        }
                        .labelsHidden()
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease")
                            .frame(width: 50, height: 50)
                    }
                    NavigationLink(destination: CreateTaskView(settings: settings)) {
                        Image(systemName: "plus")
                    }
                }
                .frame(alignment: .trailing)
            }
            .padding([.horizontal, .top])
            TabView(selection: $weekIndex) {
                ForEach(weekSlider.indices, id: \.self) { index in
                    let week = weekSlider[index]
                    WeekView(week)
                        .padding(.horizontal, 15)
                        .tag(index)
                }
            }
            .padding(.horizontal, -15)
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 95)
            .padding([.bottom])
        }
        .onChange(of: weekIndex, initial: false) { oldValue, newValue in
            if newValue == 0 || newValue == (weekSlider.count - 1) {
                generateWeek = true
            }
        }
    }
    
    @ViewBuilder
    func WeekView(_ week: [Date.WeekDay]) -> some View {
        HStack(spacing: 0) {
            ForEach(week) { day in
                VStack(spacing: 10) {
                    Text(day.date.format("dd"))
                        .font(.system(size: 15))
                        .fontWeight(.semibold)
                    Text(day.date.format("EEE"))
                        .font(.system(size: 14))
                    if isSameDate(day.date, selectedDate) {
                        if taskDateStrings.contains(day.date.formatted(date: .complete, time: .omitted)) || isInRoutine(day.date) {
                            Circle()
                                .fill(Color.mint)
                                .frame(width: 8, height: 8)
                        }
                        else{
                            Circle()
                                .stroke(style: StrokeStyle(lineWidth: 1))
                                .fill(Color.white)
                                .frame(width: 8, height: 8)
                        }
                    }
                    else {
                        if taskDateStrings.contains(day.date.formatted(date: .complete, time: .omitted)) || isInRoutine(day.date) {
                            Circle()
                                .fill(Color.gray)
                                .frame(width: 8, height: 8)
                        }
                        else{
                            Circle()
                                .stroke(style: StrokeStyle(lineWidth: 1))
                                .fill(Color.gray)
                                .frame(width: 8, height: 8)
                        }
                    }
                }
                .foregroundStyle(isSameDate(day.date, selectedDate) ? Color.white : Color.gray)
                .frame(width: 45, height: 90)
                .overlay(
                    VStack {
                        if day.date.isToday && !isSameDate(day.date, selectedDate) {
                            Capsule(style: .continuous)
                                .stroke(Color.gray, lineWidth: 2)
                        }
                    }
                )
                .background(
                    ZStack {
                        if isSameDate(day.date, selectedDate) {
                            Capsule()
                                .fill(.blue.gradient)
                                .matchedGeometryEffect(id: "TABINDICATOR", in: animation)
                        }
                    }
                )
                .frame(maxWidth: .infinity, alignment: .center)
                .contentShape(.rect)
                .onTapGesture {
                    withAnimation(.snappy) {
                        selectedDate = day.date
                    }
                }
            }
        }
        .background {
            GeometryReader{
                let minX = $0.frame(in: .global).minX
                
                Color.clear
                    .preference(key: CalendarOffsetKey.self, value: minX)
                    .onPreferenceChange(CalendarOffsetKey.self) { value in
                        DispatchQueue.main.async {
                            if value.rounded() == 15 {
                                paginateWeek()
                                generateWeek = false
                            }
                        }
                    }
            }
        }
    }
    
    @ViewBuilder
    func TaskView() -> some View {
        if filteredTasks == [] {
            VStack(alignment: .center) {
                Text("No tasks on this day!")
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
                        
                        if settings.sortCalendar == "Category" {
                            if let index = filteredTasks.firstIndex(of: task) {
                                if index == 0 {
                                    if let category = task.category?.title {
                                        Text(category)
                                            .font(.headline.bold())
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding([.top, .horizontal])
                                    }
                                }
                                else {
                                    if let newCategory = task.category?.title, let oldCategory = filteredTasks[index - 1].category?.title {
                                        if newCategory != oldCategory {
                                            Text(newCategory)
                                                .font(.headline.bold())
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .padding([.top, .horizontal])
                                                .padding(.top)
                                        }
                                    }
                                    else if task.category?.title == nil && filteredTasks[index - 1].category?.title != nil {
                                        Text("No Category")
                                            .font(.headline.bold())
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding([.top, .horizontal])
                                            .padding(.top)
                                    }
                                }
                            }
                        }

                        else if settings.sortCalendar == "Priority" {
                            if let index = filteredTasks.firstIndex(of: task) {
                                if index == 0 {
                                    Text(task.priority != "None" ? (task.priority + " Priority") : "No Priority")
                                        .font(.headline.bold())
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding([.top, .horizontal])
                                }
                                else {
                                    if task.priority != filteredTasks[index - 1].priority {
                                        Text(task.priority != "None" ? (task.priority + " Priority") : "No Priority")
                                            .font(.headline.bold())
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding([.top, .horizontal])
                                            .padding(.top)
                                    }
                                }
                            }
                        }
                        
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
                    TaskViewExpandedBlock(task)
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
                        .opacity(isTaskCompleted(task) ? 0.3 : 1)
                }
                else {
                    Circle()
                        .stroke(convertColorString(task.category?.colorString ?? settings.uncategorizedColorString).gradient, lineWidth: 3)
                        .frame(width: 12, height: 12)
                        .opacity(isTaskCompleted(task) ? 0.3 : 1)
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
                    .opacity(isTaskCompleted(task) ? 0.3 : 1)
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
                    if (task.isDateEnabled && task.isTimeEnabled) || (task.isRepeatEnabled && task.isRoutineTimeEnabled)  {
                        HStack(spacing: 5) {
                            Image(systemName: "alarm")
                            if task.isDateEnabled && task.isTimeEnabled {
                                Text(task.time.formatted(date: .omitted, time: .shortened))
                                    .font(.headline)
                            }
                            else {
                                Text(task.routineTime.formatted(date: .omitted, time: .shortened))
                                    .font(.headline)
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
                    toggleTask(task)
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
            convertColorString(task.category?.colorString ?? settings.uncategorizedColorString).opacity(isTaskCompleted(task) ? 0.3 : 1).gradient
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
        .foregroundStyle(.white)
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            convertColorString(task.category?.colorString ?? settings.uncategorizedColorString).opacity(isTaskCompleted(task) ? 0.3 : 1).gradient
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    // Different from TaskListView
    func toggleTask(_ task: TaskItem) {
        if task.isRepeatEnabled {
            if task.completedDates.contains(where: { isSameDate($0, selectedDate) }) {
                task.completedDates.removeAll(where: { isSameDate($0, selectedDate) })
                task.isExpanded = true
            }
            else {
                task.completedDates.append(selectedDate)
                task.isExpanded = false
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
        return (task.isRepeatEnabled && isRoutineTaskCompleted(task)) || (!task.isRepeatEnabled && task.isCompleted)
    }
    
    func latestCompletionDate(_ task: TaskItem) -> Date? {
        if task.completedDates.count > 0 {
            return task.completedDates.sorted(by: { $0 > $1 })[0]
        }
        return nil
    }
    
    // Different from TaskListView
    func isRoutineTaskCompleted(_ task: TaskItem) -> Bool {
        for completeDate in task.completedDates {
            if isSameDate(completeDate, selectedDate) {
                return true
            }
        }
        return false
    }
    
    func isRoutineTaskCompletedAlternate(_ task: TaskItem, _ date: Date) -> Bool {
        for completeDate in task.completedDates {
            if isSameDate(completeDate, date) {
                return true
            }
        }
        return false
    }
    
    func isInSelectedDay(_ task: TaskItem) -> Bool {
        if (task.isRepeatEnabled && task.routine.contains(dayToNum(selectedDate.format("EEEE"))) && (!task.isEndDateEnabled || task.endDate > selectedDate || isSameDate(task.endDate, selectedDate))) && (isSameDate(selectedDate, task.dateCreated) || selectedDate > task.dateCreated) {
            return true
        }
        return false
    }
    
    func isInRoutine(_ day: Date) -> Bool {
        for task in tasks {
            if (task.isRepeatEnabled && task.routine.contains(dayToNum(day.format("EEEE"))) && (!task.isEndDateEnabled || task.endDate > day || isSameDate(task.endDate, day))) && (isSameDate(day, task.dateCreated) || day > task.dateCreated) && (!settings.isHideOnCompletionCalendar || !isRoutineTaskCompletedAlternate(task, day)) {
                return true
            }
        }
        return false
    }
    
    func paginateWeek() {
        if weekSlider.indices.contains(weekIndex) {
            if let firstDate = weekSlider[weekIndex].first?.date, weekIndex == 0 {
                weekSlider.insert(firstDate.generatePreviousWeek(), at: 0)
                weekSlider.removeLast()
                weekIndex = 1
            }
            if let lastDate = weekSlider[weekIndex].last?.date, weekIndex == (weekSlider.count - 1) {
                weekSlider.append(lastDate.generateNextWeek())
                weekSlider.removeFirst()
                weekIndex = weekSlider.count - 2
            }
        }
    }
    
    func isCurrentWeek(_ week: [[Date.WeekDay]]) -> Bool {
        if week.count > weekIndex {
            for day in week[weekIndex] {
                if isSameDate(Date(), day.date) {
                    return true
                }
            }
        }
        return false
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
                ($0.category != nil ? 0 : 1, ($0.category?.title ?? ""), isTaskCompleted($0) ? 1 : 0, CLLocation(latitude: $0.latitude, longitude: $0.longitude).distance(from: CLLocation(latitude: locationManager.userLocation?.latitude ?? 0, longitude: locationManager.userLocation?.longitude ?? 0))) <
                
                ($1.category != nil ? 0 : 1, ($1.category?.title ?? ""), isTaskCompleted($1) ? 1 : 0, CLLocation(latitude: $1.latitude, longitude: $1.longitude).distance(from: CLLocation(latitude: locationManager.userLocation?.latitude ?? 0, longitude: locationManager.userLocation?.longitude ?? 0)))}
            )
        }
        else if option == "Priority" {
            return tasks.sorted(by: {
                ($0.priority == "High" ? 0 : ($0.priority == "Medium") ? 1 : ($0.priority == "Low" ? 2 : 3), isTaskCompleted($0) ? 1 : 0, CLLocation(latitude: $0.latitude, longitude: $0.longitude).distance(from: CLLocation(latitude: locationManager.userLocation?.latitude ?? 0, longitude: locationManager.userLocation?.longitude ?? 0))) <
                
                ($1.priority == "High" ? 0 : ($1.priority == "Medium") ? 1 : ($1.priority == "Low" ? 2 : 3), isTaskCompleted($1) ? 1 : 0, CLLocation(latitude: $1.latitude, longitude: $1.longitude).distance(from: CLLocation(latitude: locationManager.userLocation?.latitude ?? 0, longitude: locationManager.userLocation?.longitude ?? 0)))}
            )
        }
        else if option == "Time" {
            return tasks.sorted(by: {
                (isTaskCompleted($0) ? 1 : 0, ($0.isDateEnabled && $0.isTimeEnabled) || ($0.isRepeatEnabled && $0.isRoutineTimeEnabled) ? 0 : 1, $0.isTimeEnabled ? $0.time : $0.routineTime, CLLocation(latitude: $0.latitude, longitude: $0.longitude).distance(from: CLLocation(latitude: locationManager.userLocation?.latitude ?? 0, longitude: locationManager.userLocation?.longitude ?? 0))) <
                    
                (isTaskCompleted($1) ? 1 : 0, ($1.isDateEnabled && $1.isTimeEnabled) || ($1.isRepeatEnabled && $1.isRoutineTimeEnabled) ? 0 : 1 , $1.isTimeEnabled ? $1.time : $1.routineTime, CLLocation(latitude: $1.latitude, longitude: $1.longitude).distance(from: CLLocation(latitude: locationManager.userLocation?.latitude ?? 0, longitude: locationManager.userLocation?.longitude ?? 0)))}
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
