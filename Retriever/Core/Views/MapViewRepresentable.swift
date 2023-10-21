//
//  MapViewRepresentable.swift
//  Retriever
//
//  Created by Thomas Tseng on 2023/9/16.
//

import SwiftUI
import MapKit
import SwiftData

struct MapViewRepresentable: UIViewRepresentable {
    var enabled: Bool
    var fixedCoordinate: CLLocationCoordinate2D?
    
    @EnvironmentObject var mapViewModel: MapViewModel

    @Binding var routeCoordinate: CLLocationCoordinate2D?
    @Binding var backToDefault: Bool
    @Binding var change: Bool
    @Binding var transportType: String
    
    @Query private var tasks: [TaskItem]
    
    var coordinates: [CLLocationCoordinate2D] {
        let filtered = tasks.compactMap { task in
            return !isTaskCompleted(task) ? CLLocationCoordinate2D(latitude: task.latitude, longitude: task.longitude) : nil
        }
        return filtered
    }
    
    let mapView = MKMapView()
    let locationManager = LocationManager()
    
    func makeUIView(context: Context) -> some UIView {
        mapView.delegate = context.coordinator
        mapView.isRotateEnabled = true
        mapView.isPitchEnabled = false
        mapView.isZoomEnabled = true
        mapView.showsUserLocation = true
        mapView.showsUserTrackingButton = true
        mapView.userTrackingMode = .follow
        mapView.layoutMargins = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        if let coordinate = fixedCoordinate {
            context.coordinator.selectAnnotation(withCoordinate: coordinate)
            context.coordinator.configurePolyline(withDestinationCoordinate: coordinate, transportType)
        }
        return mapView
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        if self.enabled {
            if let coordinate = fixedCoordinate {
                if !mapViewModel.updated {
                    mapViewModel.updated = true
                    context.coordinator.getTransportTimes(withDestinationCoordinate: coordinate)
                    context.coordinator.selectAnnotation(withCoordinate: coordinate)
                    context.coordinator.configurePolyline(withDestinationCoordinate: coordinate, transportType)
                }
            }
            else if let coordinate = routeCoordinate {
                if change {
                    context.coordinator.selectAnnotation(withCoordinate: coordinate)
                    context.coordinator.configurePolyline(withDestinationCoordinate: coordinate, transportType)
                    change = false
                }
            }
            else {
                if backToDefault {
                    context.coordinator.refocusUserLocation()
                    backToDefault = false
                }
                context.coordinator.manageAnnotations(withCoordinates: coordinates)
                context.coordinator.removePolyline()
            }
        }
    }
    
    func makeCoordinator() -> MapCoordinator {
        return MapCoordinator(parent: self)
    }
    
    func isTaskCompleted(_ task: TaskItem) -> Bool {
        return (task.isRepeatEnabled && (isTaskRoutineCompleted(task))) || (!task.isRepeatEnabled && task.isCompleted)
    }
    
    func isDayRoutineCompleted(_ task: TaskItem, _ day: Date) -> Bool {
        return task.completedDates.contains(where: { isSameDate($0, day) })
    }
    
    func isTaskRoutineCompleted(_ task: TaskItem) -> Bool {
        return nextRoutineDay(task) == nil && lastRoutineDay(task) == nil
    }
    
    func nextRoutineDay(_ task: TaskItem) -> Date? {
        var nextDate: Date = Date.now
        if task.isEndDateEnabled {
            while isSameDate(nextDate, task.endDate) || nextDate < task.endDate {
                if !isDayRoutineCompleted(task, nextDate) && task.routine.contains(dayToNum(nextDate.format("EEEE"))) {
                    return nextDate
                }
                nextDate = Calendar.current.date(byAdding: .day, value: 1, to: nextDate)!
            }
        }
        else {
            while true {
                if !isDayRoutineCompleted(task, nextDate) && task.routine.contains(dayToNum(nextDate.format("EEEE"))) {
                    return nextDate
                }
                nextDate = Calendar.current.date(byAdding: .day, value: 1, to: nextDate)!
            }
        }
        return nil
    }
    
    func lastRoutineDay(_ task: TaskItem) -> Date? {
        var lastDate: Date = Calendar.current.date(byAdding: .day, value: -1, to: Date.now)!
        
        while isSameDate(lastDate, task.dateCreated) || lastDate > task.dateCreated {
            if !isDayRoutineCompleted(task, lastDate) && task.routine.contains(dayToNum(lastDate.format("EEEE"))) {
                return lastDate
            }
            lastDate = Calendar.current.date(byAdding: .day, value: -1, to: lastDate)!
        }
        return nil
    }
}

extension MapViewRepresentable {
    class MapCoordinator: NSObject, MKMapViewDelegate {
        var parent: MapViewRepresentable
        var userLocationCoordinate: CLLocationCoordinate2D?
        
        init(parent: MapViewRepresentable) {
            self.parent = parent
            super.init()
        }
        
        func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
            self.userLocationCoordinate = userLocation.coordinate
            
            let region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude),
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
            parent.mapView.regionThatFits(region)
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            let polyline = MKPolylineRenderer(overlay: overlay)
            polyline.strokeColor = .systemBlue
            polyline.lineWidth = 6
            return polyline
        }
        
        func selectAnnotation(withCoordinate coordinate: CLLocationCoordinate2D) {
            for annotation in self.parent.mapView.annotations {
                if annotation.coordinate.latitude != coordinate.latitude && annotation.coordinate.longitude != coordinate.longitude {
                    self.parent.mapView.removeAnnotation(annotation)
                }
            }
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            self.parent.mapView.addAnnotation(annotation)
            self.parent.mapView.selectAnnotation(annotation, animated: true)
            self.parent.mapView.showAnnotations(parent.mapView.annotations, animated: true)
        }
        
        func manageAnnotations(withCoordinates coordinates: [CLLocationCoordinate2D]) {
            for annotation in self.parent.mapView.annotations {
                self.parent.mapView.deselectAnnotation(annotation, animated: false)
            }
            for annotation in self.parent.mapView.annotations {
                if !coordinates.contains(where: { $0.latitude == annotation.coordinate.latitude && $0.longitude == annotation.coordinate.longitude }) {
                    self.parent.mapView.removeAnnotation(annotation)
                }
            }
            for coordinate in coordinates {
                let annotation = MKPointAnnotation()
                annotation.coordinate = coordinate
                self.parent.mapView.addAnnotation(annotation)
            }
        }
        
        func configurePolyline(withDestinationCoordinate coordinate: CLLocationCoordinate2D, _ transportType: String) {
            removePolyline()
            guard let userLocationCoordinate = userLocationCoordinate else { return }
            if transportType == "walk" {
                getDestinationRoute(from: userLocationCoordinate, to: coordinate, transportType: .walking) { route in
                    self.parent.mapView.addOverlay(route.polyline)
                }
            }
            else if transportType == "transit" {
                getDestinationRoute(from: userLocationCoordinate, to: coordinate, transportType: .transit) { route in
                    self.parent.mapView.addOverlay(route.polyline)
                }
            }
            else {
                getDestinationRoute(from: userLocationCoordinate, to: coordinate, transportType: .automobile) { route in
                    self.parent.mapView.addOverlay(route.polyline)
                }
            }
        }
        
        func getDestinationRoute(from userLocation: CLLocationCoordinate2D, to destinationCoordinate: CLLocationCoordinate2D, transportType: MKDirectionsTransportType, completion: @escaping(MKRoute) -> Void) {
            let userPlacemark = MKPlacemark(coordinate: userLocation)
            let destinationPlacemark = MKPlacemark(coordinate: destinationCoordinate)
            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: userPlacemark)
            request.destination = MKMapItem(placemark: destinationPlacemark)
            request.transportType = transportType
            
            let directions = MKDirections(request: request)
            
            directions.calculate { response, error in
                if error != nil {
                    print("Unable to find directions.")
                    return
                }
                
                guard let route = response?.routes.first else { return }
                completion(route)
            }
        }
        
        func removePolyline() {
            self.parent.mapView.removeOverlays(self.parent.mapView.overlays)
        }
        
        func refocusUserLocation() {
            self.parent.mapView.setUserTrackingMode(.follow, animated: true)
        }
        
        func getTransportTimes(withDestinationCoordinate coordinate: CLLocationCoordinate2D) {
            guard let userLocationCoordinate = userLocationCoordinate else { return }
            
            getDestinationRoute(from: userLocationCoordinate, to: coordinate, transportType: .automobile) { route in
                self.parent.mapViewModel.carTime = route.expectedTravelTime
            }
            getDestinationRoute(from: userLocationCoordinate, to: coordinate, transportType: .walking) { route in
                self.parent.mapViewModel.walkTime = route.expectedTravelTime
            }
            getDestinationRoute(from: userLocationCoordinate, to: coordinate, transportType: .transit) { route in
                self.parent.mapViewModel.transitTime = route.expectedTravelTime
            }
        }
    }
}

