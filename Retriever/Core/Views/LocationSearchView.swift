//
//  LocationSearchView.swift
//  Retriever
//
//  Created by Thomas Tseng on 2023/9/23.
//

import SwiftUI
import SwiftData

struct LocationSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var tabManager: TabManager    
    @EnvironmentObject var locationViewModel: LocationSearchViewModel
    
    @Query private var savedLocations: [SavedLocation]
    
    @Binding var locationAttempted: Bool
    
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                    TextField("Search Locations", text: $locationViewModel.queryFragment)
                        .textFieldStyle(.roundedBorder)
                        .background(.white)
                        .padding()
                }
                .padding(.horizontal)
                
                Divider()
            
                ScrollView {
                    VStack(alignment: .leading) {
                        ForEach(savedLocations) { location in
                            LocationSearchCell(title: location.title + (location.locationTitle != "" ? ": " + location.locationTitle : ""), subtitle: location.locationSubtitle, imageName: getImageName(location))
                                .onTapGesture {
                                    self.locationAttempted = true
                                    locationViewModel.setSelectedLocation(location)
                                    dismiss()
                                }
                        }
                        ForEach(locationViewModel.results, id: \.self) { result in
                            LocationSearchCell(title: result.title, subtitle: result.subtitle, imageName: "mappin.circle.fill")
                                .onTapGesture {
                                    self.locationAttempted = true
                                    locationViewModel.selectLocation(result)
                                    locationViewModel.queryFragment = ""
                                    dismiss()
                                }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding()
        }
        .navigationTitle("Search For Location")
        .toolbar {
            ToolbarItem(placement: ToolbarItemPlacement.topBarLeading) {
                Button {
                    locationViewModel.queryFragment = ""
                    dismiss()
                    tabManager.turnOn()
                } label: {
                    Text("Cancel")
                }
            }
        }
        .navigationBarBackButtonHidden()
        .background(Color(Color.backgroundColor))
    }
    
    func getImageName(_ location: SavedLocation) -> String {
        if location.type == "Home" {
            return "house.circle.fill"
        }
        else if location.type == "Work" {
            return "briefcase.circle.fill"
        }
        else if location.type == "School" {
            return "graduationcap.circle.fill"
        }
        else {
            return "location.circle.fill"
        }
    }
}
