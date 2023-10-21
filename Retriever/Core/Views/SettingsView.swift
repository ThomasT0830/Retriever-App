//
//  SettingsView.swift
//  Retriever
//
//  Created by Thomas Tseng on 2023/9/22.
//

import SwiftUI
import SwiftData
import CoreLocation

struct SettingsView: View {
    @Environment(\.modelContext) var context
    @EnvironmentObject var tabManager: TabManager
    
    @Query private var tasks: [TaskItem]
    @Query private var savedLocations: [SavedLocation]
    
    @Bindable var settings: AppSettings
    
    @State var isDeleteOnCompletion = true
    @State var showDeleteAlert = false
    @State var presentPickerWheel = false
    @State var deleteLocation: SavedLocation? = nil
    @State var showDeleteLocationAlert = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HeaderView()
                    .padding([.horizontal], 15)
                    .padding(.bottom)
                    .background(Color.white)
                List {
                    Section {
                        ForEach(savedLocations) { location in
                            HStack {
                                Text(location.title + (location.locationTitle != "" ? ": " + location.locationTitle : ""))
                                    .foregroundStyle(.black)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    deleteLocation = location
                                    showDeleteLocationAlert = true
                                } label: {
                                    Label("Delete", systemImage: "trash.fill")
                                }
                                NavigationLink(destination: UpdateSavedLocationView(location: location)) {
                                    Button {
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    .tint(.orange)
                                }
                            }
                            .alert(isPresented: $showDeleteLocationAlert) {
                                Alert(
                                    title: Text("Are you sure you want to delete this category?"),
                                    message: Text("This action cannot be undone."),
                                    primaryButton: .destructive(Text("Delete")) {
                                        if deleteLocation != nil {
                                            context.delete(deleteLocation!)
                                        }
                                        deleteLocation = nil
                                    },
                                    secondaryButton: .cancel() {
                                        deleteLocation = nil
                                    }
                                )
                            }
                        }
                        NavigationLink(destination: CreateSavedLocationView()) {
                            Text("Add Favorite Location")
                        }
                    }
                    Section {
                        NavigationLink(destination: ColorSelectView(settings: settings)) {
                            HStack {
                                Text("Cell Color of Uncategorized Tasks")
                                Spacer()
                                Circle()
                                    .fill(convertColorString(settings.uncategorizedColorString).gradient)
                                    .frame(width: 25, height: 25)
                                    .padding(3)
                                    .background(
                                        Circle()
                                            .stroke(style: StrokeStyle(lineWidth: 3))
                                            .foregroundStyle(convertColorString(settings.uncategorizedColorString).gradient)
                                            .padding(-2)
                                    )
                            }
                            .padding(.trailing)
                        }
                        .frame(maxWidth: .infinity)
                        Toggle(isOn: $settings.isExpandCellOnDefault) {
                            Text("Expand Cells On Default")
                        }
                    }
                    Section {
                        Toggle(isOn: $isDeleteOnCompletion) {
                            Text("Delete Task On Completion")
                        }
                        if !settings.isDeleteOnCompletion {
                            Toggle(isOn: $settings.isHideOnCompletionCalendar) {
                                Text("Hide Task On Completion In Calendar View")
                            }
                        }
                        if !settings.isDeleteOnCompletion {
                            Toggle(isOn: $settings.isHideOnCompletionList) {
                                Text("Hide Task On Completion In List View")
                            }
                        }
                    }
                    .onChange(of: isDeleteOnCompletion, initial: false) { oldValue, newValue in
                        if oldValue == false && newValue == true {
                            showDeleteAlert = true
                        }
                        else if newValue == false {
                            settings.isDeleteOnCompletion = false
                        }
                    }
                    .alert(isPresented: $showDeleteAlert) {
                        Alert(
                            title: Text("Are you sure you want to delete all completed tasks?"),
                            message: Text("This action cannot be undone."),
                            primaryButton: .destructive(Text("Delete")) {
                                settings.isDeleteOnCompletion = true
                                for task in tasks {
                                    if isTaskItemCompleted(task) {
                                        task.isDelete = true
                                        NotificationManager.instance.manageNotification(task, settings)
                                        context.delete(task)
                                    }
                                }
                            },
                            secondaryButton: .cancel() {
                                isDeleteOnCompletion = false
                                settings.isDeleteOnCompletion = false
                            }
                        )
                    }
                    Section {
                        Picker(selection: $settings.isEnableTimeNotification, label: Text("Time-Based Notifications")) {
                            Text("Enable").tag("Enable")
                            Text("Disable").tag("Disable")
                        }
                        .onChange(of: settings.isEnableTimeNotification, initial: false) { oldValue, newValue in
                            if newValue == "Enable" {
                                settings.isEnableTimeNotificationOnDefault = true
                            }
                            else {
                                settings.isEnableTimeNotificationOnDefault = false
                            }
                            for task in tasks {
                                NotificationManager.instance.manageNotification(task, settings)
                            }
                        }
                        if settings.isEnableTimeNotification == "Enable" {
                            Toggle(isOn: $settings.isEnableTimeNotificationOnDefault) {
                                Text("Enable Time-Based Notifications On Default")
                            }
                        }
                        Picker(selection: $settings.isEnableLocationNotification, label: Text("Location-Based Notifications")) {
                            Text("Enable").tag("Enable")
                            Text("Disable").tag("Disable")
                        }
                        .onChange(of: settings.isEnableLocationNotification, initial: false) { oldValue, newValue in
                            if newValue == "Enable" {
                                settings.isEnableLocationNotificationOnDefault = true
                            }
                            else {
                                settings.isEnableLocationNotificationOnDefault = false
                            }
                            for task in tasks {
                                NotificationManager.instance.manageNotification(task, settings)
                            }
                        }
                        if settings.isEnableLocationNotification == "Enable" {
                            Toggle(isOn: $settings.isEnableLocationNotificationOnDefault) {
                                Text("Enable Location-Based Notifications On Default")
                            }
                        }
                    }
                    Section {
                        Toggle(isOn: $settings.isUserLocationSelectedOnDefault) {
                            Text("Use User Location As Selected Location On Default")
                        }
                        Picker(selection: $settings.defaultPriority, label: Text("Default Priority")) {
                            Text("None").tag("None")
                            Text("Low").tag("Low")
                            Text("Medium").tag("Medium")
                            Text("High").tag("High")
                        }
                    }
                    Section {
                        VStack(alignment: .leading){
                            HStack (spacing: 0){
                                Text("Location Notification Radius")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text(formatDistance(settings.notificationDistance))
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                            .onTapGesture {
                                presentPickerWheel.toggle()
                            }
                            if presentPickerWheel {
                                Picker(selection: $settings.notificationDistance, label: Text("Location Notification Radius")) {
                                    ForEach(1..<201) { index in
                                        Text(formatDistance(Double(index) * 50))
                                            .tag(Double(index) * 50)
                                    }
                                }
                                .pickerStyle(.wheel)
                                .onChange(of: settings.notificationDistance, initial: false) {
                                    for task in tasks {
                                        NotificationManager.instance.manageNotification(task, settings)
                                    }
                                }
                                .animation(.easeIn, value: presentPickerWheel)
                            }
                        }
                        DatePicker("Daily Notification Time", selection: $settings.notificationTime, displayedComponents: [.hourAndMinute])
                            .onChange(of: settings.notificationTime, initial: false) {
                                for task in tasks {
                                    NotificationManager.instance.manageNotification(task, settings)
                                }
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
            .frame(maxHeight: .infinity, alignment: .top)
            .background(Color.backgroundColor)
        }
        .background(Color(Color.backgroundColor))
        .onAppear {
            isDeleteOnCompletion = settings.isDeleteOnCompletion
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
                        Text("Settings")
                            .font(.title.bold())
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding([.horizontal, .top])
        }
    }
}

