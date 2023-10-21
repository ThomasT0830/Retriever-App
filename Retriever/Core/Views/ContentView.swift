//
//  ContentView.swift
//  Retriever
//
//  Created by Thomas Tseng on 2023/9/18.
//

import SwiftUI
import SwiftData

extension Color {
    public static let backgroundColor = Color("BackgroundColor")
}

struct ContentView: View {
    @Environment(\.modelContext) var context
    @EnvironmentObject var tabManager: TabManager
    @Query private var tasks: [TaskItem]
    @StateObject var locationManager = LocationManager()
    @State private var selectedTab: Tab = .map
    @State private var settings: AppSettings? = nil
    
    init() {
        UITabBar.appearance().isHidden = true
    }
    
    var body: some View {
        ZStack {
            if locationManager.authorizationStatus() == .authorizedWhenInUse || locationManager.authorizationStatus() == .authorizedAlways {
                VStack {
                    TabView(selection: $selectedTab) {
                        HomeView(settings: settings ?? AppSettings())
                            .background(Color.backgroundColor)
                            .tabItem {
                            }
                            .tag(Tab.map)
                        CalendarView(settings: settings ?? AppSettings())
                            .background(Color.backgroundColor)
                            .tabItem {
                            }
                            .tag(Tab.calendar)
                        TaskListView(settings: settings ?? AppSettings()).tabItem {
                        }
                        .tag(Tab.checklist)
                        SettingsView(settings: settings ?? AppSettings())
                            .background(Color.backgroundColor)
                            .tabItem {
                            }
                            .tag(Tab.gearshape)
                    }
                }
                if tabManager.showTabBar {
                    VStack {
                        Spacer()
                        TabBar(selectedTab: $selectedTab)
                    }
                }
            }
            else {
                GeometryReader { geometry in
                    VStack(alignment: .center, spacing: 30){
                        Image(systemName: "location.slash.circle")
                            .foregroundStyle(.white)
                            .font(.system(size: 80))
                            .multilineTextAlignment(.center)
                        VStack(spacing: 10) {
                            Text("Unable To Access Your Location")
                                .foregroundStyle(.white)
                                .font(.title.bold())
                                .multilineTextAlignment(.center)
                            Text("Please make sure that you have granted location access to the app!")
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .background(.blue.gradient)
                }
            }
        }
        .onAppear {
            NotificationManager.instance.requestAuthorization()
            NotificationManager.instance.setBadgeNumber(0)
            let request = FetchDescriptor<AppSettings>()
            let data = try? context.fetch(request)
            settings = data?.first ?? AppSettings()
            context.insert(settings ?? AppSettings())
            for task in tasks {
                NotificationManager.instance.manageNotification(task, settings ?? AppSettings())
                if task.isDelete {
                    context.delete(task)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
