//
//  UpdateSavedLocationView.swift
//  Retriever
//
//  Created by Thomas Tseng on 2023/10/15.
//

import SwiftUI
import MapKit
import SwiftData

struct UpdateSavedLocationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) var context
    @EnvironmentObject var locationViewModel: LocationSearchViewModel
    @EnvironmentObject var tabManager: TabManager
    
    @Bindable var location: SavedLocation
    
    @StateObject var locationManager = LocationManager()
    
    @State private var position: MapCameraPosition = .automatic
    @State private var title = ""
    @State private var locationType = "Home"
    
    @State var routeCoordinate: CLLocationCoordinate2D? = nil
    @State var backToDefault = false
    @State var change = false
    @State var transportType: String = "automobile"
    
    @State var carTime: Double? = nil
    
    @State private var useCurrentLocation = false
    @State private var locationAttempted = false
    @State private var showAlert = false
    
    @State private var dataLoaded = false
    
    var body: some View {
        NavigationStack {
            VStack {
                List {
                    Section {
                        TextField("Title", text: $title)
                    }
                    
                    Section {
                        Picker(selection: $locationType, label: Text("Location Type")) {
                            Text("Home").tag("Home")
                            Text("Work").tag("Work")
                            Text("School").tag("School")
                            Text("Other").tag("Other")
                        }
                        .pickerStyle(.inline)
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
                        if !useCurrentLocation && locationViewModel.selectedLocationCoordinate == nil {
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
                            
                            location.title = title
                            location.type = locationType
                            location.latitude = latitude
                            location.longitude = longitude
                            location.locationTitle = locationTitle
                            location.locationSubtitle = locationSubtitle
                            
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
        .navigationTitle("Edit Favorite Location")
        .navigationBarBackButtonHidden()
        .background(Color(Color.backgroundColor))
        .alert(isPresented: $showAlert) {
            Alert(title: Text("No Location Selected"), message: Text("Please select a location or use your current location!"))
        }
        .onAppear {
            tabManager.turnOff()
            if !dataLoaded {
                locationViewModel.selectedLocationTitle = location.locationTitle
                locationViewModel.selectedLocationSubtitle = location.locationSubtitle
                locationViewModel.selectedLocationCoordinate = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
                locationViewModel.selectedLocationCamera = MapCameraPosition.camera(MapCamera(centerCoordinate: CLLocationCoordinate2DMake(location.latitude, location.longitude), distance: 200))
                title = location.title
                locationType = location.type
            }
            dataLoaded = true
            useCurrentLocation = false
            locationAttempted = true
        }
    }
}
