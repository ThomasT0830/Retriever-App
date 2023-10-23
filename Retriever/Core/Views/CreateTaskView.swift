//
//  CreateTaskView.swift
//  Retriever
//
//  Created by Thomas Tseng on 2023/9/22.
//

import SwiftUI
import MapKit
import SwiftData

struct CreateTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) var context
    @EnvironmentObject var locationViewModel: LocationSearchViewModel
    @EnvironmentObject var tabManager: TabManager
    
    @Query private var categories: [Category]
    
    @Bindable var settings: AppSettings
    
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
    
    @State var carTime: Double? = nil
    
    @State private var useCurrentLocation = true
    @State private var locationAttempted = false
    @State private var showAlert = false
    @State private var showDeleteAlert = false
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
                                    showDeleteAlert = true
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
                            .alert(isPresented: $showDeleteAlert) {
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
                            Text("Add Category")
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
                                    Text(locationViewModel.selectedLocationTitle ?? "")
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
                            
                            let task = TaskItem(title: title, notes: notes, priority: priority, date: date, time: time, routine: routine.sorted(by: { $0 < $1 }), endDate: endDate, routineTime: routineTime, latitude: latitude, longitude: longitude, locationTitle: locationTitle, locationSubtitle: locationSubtitle, isDateEnabled: isDateEnabled, isTimeEnabled: isTimeEnabled, isRepeatEnabled: isRepeatEnabled, isEndDateEnabled: isEndDateEnabled, isRoutineTimeEnabled: isRoutineTimeEnabled, isTimeNotificationEnabled: isTimeNotificationEnabled, isLocationNotificationEnabled: isLocationNotificationEnabled)
                            context.insert(task)
                            task.category = category
                            category?.tasks?.append(task)
                            
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
        .navigationTitle("Create New Task")
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
                if settings.isEnableTimeNotification == "Disable" {
                    isTimeNotificationEnabled = false
                }
                else {
                    isTimeNotificationEnabled = settings.isEnableTimeNotificationOnDefault
                }
                if settings.isEnableLocationNotification == "Disable" {
                    isLocationNotificationEnabled = false
                }
                else {
                    isLocationNotificationEnabled = settings.isEnableLocationNotificationOnDefault
                }
                useCurrentLocation = settings.isUserLocationSelectedOnDefault
                priority = settings.defaultPriority
            }
            dataLoaded = true
        }
    }
}
    
