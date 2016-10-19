//
//  AppDelegate.swift
//  GeoFence
//
//  Created by Антон on 18/10/2016.
//  Copyright © 2016 Akademon Ltd. All rights reserved.
//

import UIKit
import XCGLogger
import CoreLocation

@UIApplicationMain
class AppDelegate: UIResponder,
                   UIApplicationDelegate,
                   CLLocationManagerDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        log.logAppDetails()
        
        locationManager.delegate = self
        
        if CLLocationManager.authorizationStatus() == .notDetermined {
            log.debug("Location permissions do not determined yet")
            locationManager.requestAlwaysAuthorization()
        } else if CLLocationManager.authorizationStatus() == .authorizedAlways {
            log.debug("Location permissions allows to always monitor location")
            regions = loadSavedRegions()
        } else {
            log.error("Location permissions denied")
        }

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        stopMonitoring(forRegions: regions)
    }
    
    // MARK: CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        guard status == .authorizedAlways else {
            log.error("User did not allow to monitor position always")
            return
        }
        log.debug("User did grant to monitor position always")
        regions = loadSavedRegions()
    }
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        
    }
    
    // MARK: Private
    
    private let saveKey = "SavedRegions"
    private let locationManager: CLLocationManager = {
        return CLLocationManager()
    }()
    
    let log: XCGLogger = {
        var documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        documentsUrl?.appendPathComponent("application.log")
        
        let log = XCGLogger.default
        log.setup(level: .debug,
                  showThreadName: true,
                  showLevel: true,
                  showFileNames: true,
                  showLineNumbers: true,
                  writeToFile: documentsUrl,
                  fileLevel: .debug)
        return log
    }()
    
    private func loadSavedRegions() -> [CLCircularRegion] {
        log.debug("Load regions")
        let regions = UserDefaults.standard.object(forKey: saveKey) as? [CLCircularRegion] ?? [CLCircularRegion]()
        log.debug("Did load regions: \(regions)")
        
        return regions
    }

    private var regions = [CLCircularRegion]() {
        willSet {
            stopMonitoring(forRegions: regions)
        }
        didSet {
            startMonitoring(forRegions: regions)
        }
    }
    private func startMonitoring(forRegions regions: [CLCircularRegion]) {
        regions.forEach { locationManager.startMonitoring(for: $0) }
    }
    private func stopMonitoring(forRegions regions: [CLCircularRegion]) {
        regions.forEach { locationManager.stopMonitoring(for: $0) }
    }

}
