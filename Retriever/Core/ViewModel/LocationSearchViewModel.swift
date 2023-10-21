//
//  LocationSearchViewModel.swift
//  Retriever
//
//  Created by Thomas Tseng on 2023/9/23.
//

import Foundation
import MapKit
import SwiftUI

class LocationSearchViewModel: NSObject, ObservableObject {
    @Published var results = [MKLocalSearchCompletion]()
    @Published var selectedLocationTitle: String?
    @Published var selectedLocationSubtitle: String?
    @Published var selectedLocationCoordinate: CLLocationCoordinate2D?
    @Published var selectedLocationCamera = MapCameraPosition.camera(MapCamera(centerCoordinate: CLLocationCoordinate2DMake(0, 0), distance: 200))
    
    private let searchCompleter = MKLocalSearchCompleter()
    
    var queryFragment: String = "" {
        didSet {
            searchCompleter.queryFragment = queryFragment
        }
    }
    
    override init() {
        super.init()
        searchCompleter.delegate = self
        searchCompleter.queryFragment = queryFragment
        searchCompleter.resultTypes = [.address, .pointOfInterest, .query]
        searchCompleter.pointOfInterestFilter = .includingAll
    }
    
    func selectLocation(_ localSearch: MKLocalSearchCompletion) {
        locationSearch(forLocationSearchCompletion: localSearch) { response, error in
            if error != nil { return }
            
            guard let item = response?.mapItems.first else { return }
            
            let coordinate = item.placemark.coordinate
            
            self.selectedLocationTitle = localSearch.title
            self.selectedLocationSubtitle = localSearch.subtitle
            self.selectedLocationCoordinate = coordinate
            self.selectedLocationCamera = MapCameraPosition.camera(MapCamera(centerCoordinate: CLLocationCoordinate2DMake(coordinate.latitude, coordinate.longitude), distance: 200))
        }
    }
    
    func setSelectedLocation(_ location: SavedLocation) {
        let coordinate = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
        
        if location.locationTitle != "" {
            self.selectedLocationTitle = location.locationTitle
        }
        else {
            self.selectedLocationTitle = location.title
        }
        self.selectedLocationSubtitle = location.locationSubtitle
        self.selectedLocationCoordinate = coordinate
        self.selectedLocationCamera = MapCameraPosition.camera(MapCamera(centerCoordinate: CLLocationCoordinate2DMake(coordinate.latitude, coordinate.longitude), distance: 200))
    }
    
    func locationSearch(forLocationSearchCompletion localSearch: MKLocalSearchCompletion, completion: @escaping MKLocalSearch.CompletionHandler){
        let searchRequest = MKLocalSearch.Request(completion: localSearch)
        
        let search = MKLocalSearch(request: searchRequest)
        search.start(completionHandler: completion)
    }
    
    func reset(){
        self.selectedLocationTitle = nil
        self.selectedLocationSubtitle = nil
        self.selectedLocationCoordinate = nil
    }
}

extension LocationSearchViewModel: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        self.results = completer.results.filter { result in
            result.subtitle != "Search Nearby"
        }
    }
}

