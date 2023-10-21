//
//  RetrieverApp.swift
//  Retriever
//
//  Created by Thomas Tseng on 2023/9/16.
//

import SwiftUI
import SwiftData

@main
struct RetrieverApp: App {
    @StateObject var locationViewModel = LocationSearchViewModel()
    @StateObject var mapViewModel = MapViewModel()
    @StateObject var tabManager = TabManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: [AppSettings.self, TaskItem.self, SavedLocation.self])
                .environmentObject(mapViewModel)
                .environmentObject(locationViewModel)
                .environmentObject(tabManager)
        }
    }
}
