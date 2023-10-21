//
//  DetailView.swift
//  Retriever
//
//  Created by Thomas Tseng on 2023/10/19.
//

import SwiftUI
import SwiftData
import CoreLocation

struct DetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) var context
    @EnvironmentObject var mapViewModel: MapViewModel
    @EnvironmentObject var tabManager: TabManager
    
    @Query private var tasks: [TaskItem]
    
    @Namespace private var animation
    
    @Bindable var settings: AppSettings
    @Bindable var task: TaskItem
    
    @StateObject var locationManager = LocationManager()
    
    @State var routeCoordinate: CLLocationCoordinate2D? = nil
    @State var backToDefault = false
    @State var change = true
    @State var transportType: String = "automobile"
    
    @State private var selectedTask: TaskItem? = nil
    @State private var sortType: String = "Distance"
    
    @State private var showDeleteAlert = false
    
    var myMap: MapViewRepresentable {
        return MapViewRepresentable(enabled: true, fixedCoordinate: CLLocationCoordinate2D(latitude: task.latitude, longitude: task.longitude), routeCoordinate: $routeCoordinate, backToDefault: $backToDefault, change: $change, transportType: $transportType)
    }
    
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
    
    var body: some View {
        NavigationStack {
            VStack {
                GeometryReader { geometry in
                    ScrollView {
                        VStack(spacing: 0){
                            ZStack (alignment: .bottomTrailing){
                                myMap
                                    .frame(height: geometry.size.height * 0.5)
                                    .clipShape(RoundedRectangle(cornerRadius: 15))
                            }
                            .padding()
                            HStack(spacing: 20){
                                Picker(selection: $transportType, label: Text("Transport Type")) {
                                    Text("Automobile").tag("automobile")
                                    Text("Walk").tag("walk")
                                    Text("Transit").tag("transit")
                                }
                                .pickerStyle(.segmented)
                                .onChange(of: transportType, initial: false) { _, _ in
                                    mapViewModel.updated = false
                                }
                                Button {
                                    mapViewModel.updated = false
                                } label: {
                                    Image(systemName: "arrow.clockwise")
                                        .foregroundStyle(.blue)
                                        .background(.white, in: Circle())
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(.white, in: RoundedRectangle(cornerRadius: 15))
                            .padding(.horizontal)
                            VStack {
                                VStack(alignment: .leading, spacing: 25){
                                    VStack(alignment: .leading, spacing: 10){
                                        if let category = task.category {
                                            Text(category.title)
                                                .foregroundColor(.white)
                                                .font(.body.bold())
                                                .padding(.vertical, 5)
                                                .padding(.horizontal, 15)
                                                .background(convertColorString(task.category?.colorString ?? settings.uncategorizedColorString), in: RoundedRectangle(cornerRadius: 5))
                                        }
                                        Text(task.title)
                                            .font(.title.bold())
                                        if task.locationTitle != "" {
                                            Text(task.locationTitle)
                                                .font(.title3)
                                        }
                                    }
                                    Grid (alignment: .center, horizontalSpacing: 30, verticalSpacing: 15) {
                                        if task.locationSubtitle != "" {
                                            GridRow {
                                                Image(systemName: "mappin")
                                                Text(task.locationSubtitle)
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                            }
                                        }
                                        
                                        if locationManager.userLocation?.latitude != nil && locationManager.userLocation?.longitude != nil {
                                            GridRow {
                                                Image(systemName: "mappin.and.ellipse")
                                                    .font(.system(size: 15))
                                                let distance = CLLocation(latitude: locationManager.userLocation?.latitude ?? 0, longitude: locationManager.userLocation?.longitude ?? 0).distance(from: CLLocation(latitude: task.latitude, longitude: task.longitude))
                                                Text(formatDistance(distance))
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                            }
                                        }
                                        
                                        if let carTime = mapViewModel.carTime {
                                            GridRow {
                                                Image(systemName: "car")
                                                Text(formatSeconds(Int(carTime)))
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                            }
                                        }
                                        
                                        if let walkTime = mapViewModel.walkTime {
                                            GridRow {
                                                Image(systemName: "figure.walk")
                                                Text(formatSeconds(Int(walkTime)))
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                            }
                                        }
                                        
                                        if let transitTime = mapViewModel.transitTime {
                                            GridRow {
                                                Image(systemName: "bus.fill")
                                                Text(formatSeconds(Int(transitTime)))
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                            }
                                        }
                                        
                                        GridRow {
                                            Image(systemName: "exclamationmark")
                                            Text(task.priority)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                        
                                        if (task.isRepeatEnabled && task.isEndDateEnabled) || (task.isDateEnabled) {
                                            GridRow {
                                                Image(systemName: "calendar")
                                                if (task.isRepeatEnabled && task.isEndDateEnabled) {
                                                    Text("Ends on " + task.endDate.formatted(date: .abbreviated, time: .omitted))
                                                        .frame(maxWidth: .infinity, alignment: .leading)
                                                }
                                                else {
                                                    Text(task.date.formatted(date: .abbreviated, time: .omitted))
                                                        .frame(maxWidth: .infinity, alignment: .leading)
                                                }
                                            }
                                        }
                                        
                                        if (task.isDateEnabled && task.isTimeEnabled) || (task.isRepeatEnabled && task.isRoutineTimeEnabled) {
                                            GridRow {
                                                Image(systemName: "clock")
                                                if (task.isDateEnabled && task.isTimeEnabled) {
                                                    Text(task.time.formatted(date: .omitted, time: .shortened))
                                                        .frame(maxWidth: .infinity, alignment: .leading)
                                                }
                                                else {
                                                    Text(task.routineTime.formatted(date: .omitted, time: .shortened))
                                                        .frame(maxWidth: .infinity, alignment: .leading)
                                                }
                                            }
                                        }
                                        
                                        if task.isRepeatEnabled {
                                            GridRow {
                                                Image(systemName: "repeat")
                                                Text(routineDays)
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                            }
                                        }
                                    }
                                    .font(.title3)
                                    
                                    if task.notes != "" {
                                        VStack(alignment: .leading, spacing: 8){
                                            Text("Notes:")
                                                .font(.title2.bold())
                                            Text(task.notes)
                                        }
                                    }
                                }
                                .padding()
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(.white)
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                            .padding()
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                            .background(Color(Color.backgroundColor))
                            VStack(spacing: 10){
                                NavigationLink(destination: UpdateTaskView(settings: settings, task: task)) {
                                    Text("Edit Task")
                                       .padding(.vertical, 12)
                                       .frame(maxWidth: .infinity, alignment: .center)
                                       .background(.white, in: RoundedRectangle(cornerRadius: 50))
                                       .padding(.horizontal)
                                }
                                Button(role: .destructive) {
                                    showDeleteAlert = true
                                } label: {
                                    Text("Delete Task")
                                        .padding(.vertical, 12)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                        .background(.white, in: RoundedRectangle(cornerRadius: 50))
                                        .padding(.horizontal)
                                }
                                .alert(isPresented: $showDeleteAlert) {
                                    Alert(
                                        title: Text("Are you sure you want to delete this task?"),
                                        message: Text("This action cannot be undone."),
                                        primaryButton: .destructive(Text("Delete")) {
                                            task.isDelete = true
                                            NotificationManager.instance.manageNotification(task, settings)
                                            context.delete(task)
//                                            for t in tasks {
//                                                if t.isDelete {
//                                                    context.delete(t)
//                                                }
//                                            }
                                            dismiss()
                                            tabManager.turnOn()
                                        },
                                        secondaryButton: .cancel() {
                                        }
                                    )
                                }
                            }
                        }
                    }
                }
            }
            .background(Color(Color.backgroundColor))
        }
        .onAppear {
            mapViewModel.updated = false
            tabManager.turnOff()
        }
        .toolbar {
            ToolbarItem(placement: ToolbarItemPlacement.topBarLeading) {
                Button {
                    dismiss()
                    tabManager.turnOn()
                } label: {
                    Text("Done")
                }
            }
            ToolbarItem(placement: ToolbarItemPlacement.topBarTrailing) {
                NavigationLink(destination: UpdateTaskView(settings: settings, task: task)) {
                    Text("Edit")
                }
            }
        }
        .navigationBarBackButtonHidden()
    }
    
    func formatSeconds(_ timeInSeconds: Int) -> String {
        var timeString: String = ""
        
        let hours = timeInSeconds / 3600
        let minutes = (timeInSeconds % 3600) / 60
        
        if hours != 0 {
            timeString += (String(hours) + " hours ")
        }
        timeString += (String(minutes) + " minutes")
        
        return timeString
    }
}
