//
//  ViewController.swift
//  GeoFence
//
//  Created by Антон on 18/10/2016.
//  Copyright © 2016 Akademon Ltd. All rights reserved.
//

import UIKit
import MapKit

class ViewController: UIViewController {
    
    // MARK: Outlets

    @IBOutlet weak var mapView: MKMapView!
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.showsUserLocation = true
        regions = loadSavedRegions()
    }

    // MARK: Actions
    
    @IBAction func onZoomTapped(_ sender: UIButton) {
        mapView.zoomToUserLocation()
    }
    @IBAction func onMapTapped(_ sender: UITapGestureRecognizer) {
        let point = sender.location(in: mapView)
        let tapPoint = mapView.convert(point, toCoordinateFrom: view)
        
        print("tap at coordinates: \(tapPoint)")
        
        addFenceRegion(point: tapPoint, withRadius: 10.0, andIdentifier: "Geo Fence at: \(point)")
    }
    
    // MARK: Private
    
    private let saveKey = "SavedRegions"
    private var regions = [CLCircularRegion]()
    
    private func loadSavedRegions() -> [CLCircularRegion] {
        return UserDefaults.standard.object(forKey: saveKey) as? [CLCircularRegion] ?? [CLCircularRegion]()
    }
    private func saveRegions(regions: [CLCircularRegion]) {
        UserDefaults.standard.set(regions, forKey: saveKey)
    }
    private func addFenceRegion(point: CLLocationCoordinate2D, withRadius radius: CLLocationDistance, andIdentifier identifier: String) {
        let region = CLCircularRegion(center: point, radius: radius, identifier: identifier)
        region.notifyOnEntry = false
        region.notifyOnExit = true
        
        regions.append(region)
        saveRegions(regions: regions)
    }

}

extension MKMapView {
    func zoomToUserLocation() {
        guard let coordinate = userLocation.location?.coordinate else { return }
        let region = MKCoordinateRegionMakeWithDistance(coordinate, 1000, 1000)
        setRegion(region, animated: true)
    }
}
