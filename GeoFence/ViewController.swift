//
//  ViewController.swift
//  GeoFence
//
//  Created by Антон on 18/10/2016.
//  Copyright © 2016 Akademon Ltd. All rights reserved.
//

import UIKit
import MapKit

import SwiftyBeaver

class ViewController: UIViewController,
                      MKMapViewDelegate {
    
    // MARK: Properties
    
    var regionDelegate: RegionDelegate!
    var showsUserLocation = false
    
    // MARK: Outlets

    @IBOutlet weak var mapView: MKMapView!
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.showsUserLocation = showsUserLocation
        
        drawRegion(region: regionDelegate.region)
    }
    
    // MARK: MKMapViewDelegate
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        guard let circle = overlay as? MKCircle else {
            return MKOverlayRenderer(overlay: overlay)
        }
        let renderer = MKCircleRenderer(circle: circle)
        renderer.fillColor = UIColor.green
        renderer.alpha = 0.3
        
        return renderer
    }
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        guard let location = userLocation.location, location.horizontalAccuracy > 0 else {
            return
        }
        if firstLocationDetection {
            firstLocationDetection = false
            mapView.zoomToUserLocation()
        }
    }

    // MARK: Actions
    
    @IBAction func onZoomTapped(_ sender: UIButton) {
        mapView.zoomToUserLocation()
    }
    @IBAction func onMapTapped(_ sender: UITapGestureRecognizer) {
        let point = sender.location(in: mapView)
        let tapPoint = mapView.convert(point, toCoordinateFrom: view)
        
        print("tap at coordinates: \(tapPoint)")
        
        let region = newFenceRegion(point: tapPoint, withRadius: defaultRadius, andIdentifier: "Geo Fence at: \(point)")
        drawRegion(region: region)
        
        regionDelegate.region = region
    }
    
    // MARK: Private

    private let log: SwiftyBeaver.Type = {
        return SwiftyBeaver.self
    }()

    private let defaultRadius = 100.0
    private var firstLocationDetection = true
    
    private var circle: MKCircle?

    private func drawRegion(region: CLCircularRegion?) {
        guard let region = region else {
            return
        }
        if let oldCircle = self.circle {
            mapView.remove(oldCircle)
        }
        let circle = MKCircle(center: region.center, radius: region.radius)
        mapView.addOverlays([circle])
        
        self.circle = circle
    }
    private func newFenceRegion(point: CLLocationCoordinate2D, withRadius radius: CLLocationDistance, andIdentifier identifier: String) -> CLCircularRegion {
        let region = CLCircularRegion(center: point, radius: radius, identifier: identifier)
        region.notifyOnEntry = true
        region.notifyOnExit = true
        
        return region
    }

}

extension MKMapView {
    func zoomToUserLocation() {
        guard let coordinate = userLocation.location?.coordinate else {
            SwiftyBeaver.self.error("Failed to get current location")
            return
        }
        SwiftyBeaver.self.info("Zoom to the current coordinates")
        let region = MKCoordinateRegionMakeWithDistance(coordinate, 500, 500)
        setRegion(region, animated: true)
    }
}
