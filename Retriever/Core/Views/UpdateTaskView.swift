//
//  UpdateTaskView.swift
//  Retriever
//
//  Created by Thomas Tseng on 2023/10/5.
//

import SwiftUI
import MapKit
import SwiftData

struct UpdateTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) var context
    @EnvironmentObject var locationViewModel: LocationSearchViewModel
    @EnvironmentObject var tabManager: TabManager
    
    @Bindable var settings: AppSettings
    @Bindable var task: TaskItem
    
    @Query private var categories: [Category]
    
    @StateObject var locationManager = LocationManager()
    
    @State private var position: MapCameraPosition = .automatic
    @State private var title = ""
    @State private var notes = ""
    @State private var priority = "None"
    @State private var category: Category? = nil
    @State private var date = Date.now
    @State private var time = Date.now
    @State private var routine: [Int] = []
    @State private var endDate = Date.now
    @State private var routineTime = Date.now
    @State private var isDateEnabled = false
    @State private var isTimeEnabled = false
    @State private var isRepeatEnabled = false
    @State private var isEndDateEnabled = false
    @State private var isRoutineTimeEnabled = false
    @State private var isTimeNotificationEnabled = true
    @State private var isLocationNotificationEnabled = true
    
    @State var routeCoordinate: CLLocationCoordinate2D? = nil
    @State var backToDefault = false
    @State var change = false
    @State var transportType: String = "automobile"
    
    @State private var useCurrentLocation = true
    @State private var locationAttempted = false
    @State private var showAlert = false
    @State private var showDeleteCategoryAlert = false
    @State private var deleteCategory: Category? = nil
    @State private var dataLoaded = false
    
    var body: some View {
        NavigationStack {
            VStack {
                List {
                    Section {
                        TextField("Title", text: $title)
                        TextField("Notes", text: $notes)
                    }
                    
                    Section {
                        if !isRepeatEnabled {
                            Toggle(isOn: $isDateEnabled) {
                                Text("Date")
                            }
                            if isDateEnabled || isRepeatEnabled {
                                DatePicker("", selection: $date, displayedComponents: [.date])
                                Toggle(isOn: $isTimeEnabled) {
                                    Text("Time")
                                }
                                if isTimeEnabled {
                                    DatePicker("", selection: $time, displayedComponents: [.hourAndMinute])
                                }
                            }
                        }
                        Toggle(isOn: $isRepeatEnabled) {
                            Text("Repeat")
                        }
                        .onChange(of: isRepeatEnabled, initial: false) { oldValue, newValue in
                            if newValue == false {
                                routine = []
                            }
                        }
                        if isRepeatEnabled {
                            Toggle(isOn: $isEndDateEnabled) {
                                Text("End Date")
                            }
                            if isEndDateEnabled {
                                DatePicker("", selection: $endDate, displayedComponents: [.date])
                            }
                            Toggle(isOn: $isRoutineTimeEnabled) {
                                Text("Time")
                            }
                            if isRoutineTimeEnabled {
                                DatePicker("", selection: $routineTime, displayedComponents: [.hourAndMinute])
                            }
                            NavigationLink(destination: RoutineSelectView(routine: $routine)) {
                                if routine == [] {
                                    Text("Select Routine")
                                }
                                else {
                                    Text("Change Routine")
                                }
                            }
                        }
                        if (isDateEnabled || isRepeatEnabled) && settings.isEnableTimeNotification == "Enable" {
                            Toggle(isOn: $isTimeNotificationEnabled) {
                                Text("Enable Time-Based Notification")
                            }
                        }
                    }
                    
                    Section {
                        Picker(selection: $priority, label: Text("Priority")) {
                            Text("None").tag("None")
                            Text("Low").tag("Low")
                            Text("Medium").tag("Medium")
                            Text("High").tag("High")
                        }
                    }
                    
                    Section {
                        Button {
                            category = nil
                        } label: {
                            HStack {
                                Text("No Category")
                                    .foregroundStyle(.black)
                                Spacer()
                                if category == nil {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        ForEach(categories) { c in
                            HStack {
                                Circle()
                                    .fill(convertColorString(c.colorString).gradient)
                                    .frame(width: 12, height: 12)
                                    .padding(3)
                                Text(c.title)
                                    .foregroundStyle(.black)
                                Spacer()
                                if category == c {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                            .contentShape(Rectangle())
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .onTapGesture {
                                category = c
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    deleteCategory = c
                                    showDeleteCategoryAlert = true
                                } label: {
                                    Label("Delete", systemImage: "trash.fill")
                                }
                                NavigationLink(destination: UpdateCategoriesView(category: c)) {
                                    Button {
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    .tint(.orange)
                                }
                            }
                            .alert(isPresented: $showDeleteCategoryAlert) {
                                Alert(
                                    title: Text("Are you sure you want to delete this category?"),
                                    message: Text("This action cannot be undone."),
                                    primaryButton: .destructive(Text("Delete")) {
                                        if let category1 = category, let category2 = deleteCategory {
                                            if category1 == category2 {
                                                category = nil
                                            }
                                        }
                                        if deleteCategory != nil {
                                            context.delete(deleteCategory!)
                                        }
                                    },
                                    secondaryButton: .cancel() {
                                        deleteCategory = nil
                                    }
                                )
                            }
                        }
                        NavigationLink(destination: CreateCategoriesView(selectedCategory: $category)) {
                            Button {
                            } label : {
                                Text("Add Category")
                            }
                        }
                    }
                    
                    Section {
                        VStack {
                            Toggle(isOn: $useCurrentLocation) {
                                Text("Use Current Location")
                            }
                            if useCurrentLocation {
                                MapViewRepresentable(enabled: false, fixedCoordinate: nil, routeCoordinate: $routeCoordinate, backToDefault: $backToDefault, change: $change, transportType: $transportType)
                                    .frame(height: 300)
                                    .padding([.top], 5)
                            }
                        }
                        if !useCurrentLocation {
                            NavigationLink(destination: LocationSearchView(locationAttempted: $locationAttempted)) {
                                if locationAttempted && locationViewModel.selectedLocationCoordinate != nil {
                                    Text("Change Location")
                                }
                                else {
                                    Text("Select Location")
                                }
                            }
                        }
                        if settings.isEnableLocationNotification == "Enable" {
                            Toggle(isOn: $isLocationNotificationEnabled) {
                                Text("Enable Location-Based Notification")
                            }
                        }
                    }
                    if !useCurrentLocation {
                        Section {
                            if locationViewModel.selectedLocationTitle != nil && locationViewModel.selectedLocationCoordinate != nil {
                                VStack(alignment: .leading, spacing: 8) {
                                    if locationViewModel.selectedLocationTitle != nil && locationViewModel.selectedLocationTitle != "" {
                                        Text(locationViewModel.selectedLocationTitle ?? "")
                                    }
                                    if locationViewModel.selectedLocationSubtitle != nil && locationViewModel.selectedLocationSubtitle != "" {
                                        Text(locationViewModel.selectedLocationSubtitle ?? "")
                                            .foregroundStyle(Color(.gray))
                                    }
                                    let coordinate = CLLocationCoordinate2D(latitude: locationViewModel.selectedLocationCoordinate?.latitude ?? 0, longitude: locationViewModel.selectedLocationCoordinate?.longitude ?? 0)
                                    Map.init(position: $locationViewModel.selectedLocationCamera) {
                                        Marker(locationViewModel.selectedLocationTitle ?? "", coordinate: coordinate)
                                    }
                                    .frame(height: 300)
                                }
                                .padding([.vertical], 5)
                            }
                            else if locationAttempted {
                                Text("No location found!")
                            }
                        }
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: ToolbarItemPlacement.topBarLeading) {
                Button {
                    locationViewModel.reset()
                    dismiss()
                    tabManager.turnOn()
                } label: {
                    Text("Cancel")
                }
            }
            if title.trimmingCharacters(in: .whitespacesAndNewlines) != "" {
                ToolbarItem(placement: ToolbarItemPlacement.topBarTrailing) {
                    Button {
                        if (!useCurrentLocation && locationViewModel.selectedLocationCoordinate == nil) || (isRepeatEnabled && routine == []) {
                            showAlert = true
                        }
                        else {
                            var latitude = locationViewModel.selectedLocationCoordinate?.latitude ?? 0
                            var longitude = locationViewModel.selectedLocationCoordinate?.longitude ?? 0
                            var locationTitle = locationViewModel.selectedLocationTitle ?? ""
                            var locationSubtitle = locationViewModel.selectedLocationSubtitle ?? ""
                            if useCurrentLocation {
                                locationManager.requestLocation()
                                latitude = locationManager.userLocation?.latitude ?? 0
                                longitude = locationManager.userLocation?.longitude ?? 0
                                locationTitle = ""
                                locationSubtitle = ""
                            }
                            
                            if isRepeatEnabled {
                                isDateEnabled = false
                            }
                            else if isDateEnabled {
                                isEndDateEnabled = false
                            }
                            
                            if !isDateEnabled {
                                isTimeEnabled = false
                            }
                            
                            if !isRepeatEnabled {
                                isRoutineTimeEnabled = false
                            }
                            
                            task.title = title
                            task.notes = notes
                            task.priority = priority
                            task.category = category
                            task.date = date
                            task.time = time
                            task.routine = routine.sorted(by: { $0 < $1 })
                            task.endDate = endDate
                            task.routineTime = routineTime
                            task.latitude = latitude
                            task.longitude = longitude
                            task.locationTitle = locationTitle
                            task.locationSubtitle = locationSubtitle
                            task.isDateEnabled = isDateEnabled
                            task.isTimeEnabled = isTimeEnabled
                            task.isRepeatEnabled = isRepeatEnabled
                            task.isEndDateEnabled = isEndDateEnabled
                            task.isRoutineTimeEnabled = isRoutineTimeEnabled
                            task.isTimeNotificationEnabled = isTimeNotificationEnabled
                            task.isLocationNotificationEnabled = isLocationNotificationEnabled
                            
                            NotificationManager.instance.manageNotification(task, settings)
                            
                            locationViewModel.reset()
                            dismiss()
                            tabManager.turnOn()
                        }
                    } label: {
                        Text("Done")
                    }
                }
            }
        }
        .navigationTitle("Edit Task")
        .navigationBarBackButtonHidden()
        .background(Color(Color.backgroundColor))
        .alert(isPresented: $showAlert) {
            if !useCurrentLocation && locationViewModel.selectedLocationCoordinate == nil {
                Alert(title: Text("No Location Selected"), message: Text("Please select a location or use your current location!"))
            }
            else {
                Alert(title: Text("No Routine Chosen"), message: Text("Please choose a routine for your task!"))
            }
        }
        .onAppear {
            tabManager.turnOff()
            if !dataLoaded {
                locationViewModel.selectedLocationTitle = task.locationTitle
                locationViewModel.selectedLocationSubtitle = task.locationSubtitle
                locationViewModel.selectedLocationCoordinate = CLLocationCoordinate2D(latitude: task.latitude, longitude: task.longitude)
                locationViewModel.selectedLocationCamera = MapCameraPosition.camera(MapCamera(centerCoordinate: CLLocationCoordinate2DMake(task.latitude, task.longitude), distance: 200))
                title = task.title
                notes = task.notes
                priority = task.priority
                category = task.category
                date = task.date
                time = task.time
                routine = task.routine
                endDate = task.endDate
                routineTime = task.routineTime
                isDateEnabled = task.isDateEnabled
                isTimeEnabled = task.isTimeEnabled
                isRepeatEnabled = task.isRepeatEnabled
                isEndDateEnabled = task.isEndDateEnabled
                isRoutineTimeEnabled = task.isRoutineTimeEnabled
                if settings.isEnableTimeNotification == "Disable" {
                    isTimeNotificationEnabled = false
                }
                else {
                    isTimeNotificationEnabled = task.isTimeNotificationEnabled
                }
                if settings.isEnableLocationNotification == "Disable" {
                    isLocationNotificationEnabled = false
                }
                else {
                    isLocationNotificationEnabled = task.isLocationNotificationEnabled
                }
                useCurrentLocation = false
                locationAttempted = true
            }
            dataLoaded = true
        }
    }
}
    
