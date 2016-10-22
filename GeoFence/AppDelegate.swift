//
//  AppDelegate.swift
//  GeoFence
//
//  Created by Антон on 18/10/2016.
//  Copyright © 2016 Akademon Ltd. All rights reserved.
//

import UIKit
import CoreLocation
import UserNotifications
import SwiftyBeaver

protocol RegionDelegate {
    var region: CLCircularRegion? { get set }
}

@UIApplicationMain
class AppDelegate: UIResponder,
                   UIApplicationDelegate,
                   CLLocationManagerDelegate,
                   RegionDelegate {
    
    // MARK: Properties

    var window: UIWindow?
    var region: CLCircularRegion? = CLCircularRegion() {
        didSet {
//            stopMonitoring(forRegion: oldValue)
            saveRegion(region: region)
            startMonitoring(forRegion: region)
        }
    }
    
    // MARK: Lifecycle

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        log.info("******************** Start app  with options: '\(launchOptions)' ********************")
        
        rootViewController.regionDelegate = self
        rootViewController.showsUserLocation = false

        locationManager.delegate = self

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            self.isGrantedNotificationAccess = granted
            if !granted {
                self.log.error("Notification access denied")
            }
        }
        
        if CLLocationManager.authorizationStatus() == .notDetermined {
            log.debug("Location permissions do not determined yet")
            locationManager.requestAlwaysAuthorization()
        } else if CLLocationManager.authorizationStatus() == .authorizedAlways {
            log.debug("Location permissions allows to always monitor location")
            
            locationManager.startUpdatingLocation()
            rootViewController.showsUserLocation = true

            region = loadSavedRegion()
        } else {
            log.error("Location permissions denied")
        }

        return true
    }
    func applicationWillResignActive(_ application: UIApplication) {
        log.info("******************** Will resign active ********************")
    }
    func applicationDidEnterBackground(_ application: UIApplication) {
        log.info("******************** Did enter background ********************")
    }
    func applicationWillEnterForeground(_ application: UIApplication) {
        log.info("******************** Will enter foreground ********************")
    }
    func applicationDidBecomeActive(_ application: UIApplication) {
        log.info("******************** Did become active ********************")
    }
    func applicationWillTerminate(_ application: UIApplication) {
        log.info("******************** Will terminate ********************")
    }
    
    // MARK: CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        guard status == .authorizedAlways else {
            log.error("User did not allow to monitor position always")
            return
        }
        log.debug("User did grant to monitor position always")
        region = loadSavedRegion()
    }
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if region is CLCircularRegion {
            handleEvent(forRegion: region)
        }
    }
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        if region is CLCircularRegion {
            handleEvent(forRegion: region)
        }
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //log.verbose("Updated locations: \(locations)")
    }
    
    // MARK: Private
    
    private let log: SwiftyBeaver.Type = {
        let log = SwiftyBeaver.self
        
        // add log destinations. at least one is needed!
        let console = ConsoleDestination()  // log to Xcode Console
        let file = FileDestination()  // log to default swiftybeaver.log file
        let cloud = SBPlatformDestination(appID: "o8QQka", appSecret: "qwzsd7129iOwboyekiute8tdUmluoKar", encryptionKey: "5g5Txz1cv3jjkfquOxmobqyOfcdi3pcb") // to cloud
        
        // use custom format and set console output to short time, log level & message
        console.format = "$DHH:mm:ss$d $L $M"
        
        // add the destinations to SwiftyBeaver
        log.addDestination(console)
        log.addDestination(file)
        log.addDestination(cloud)
        
        return log
    }()
    
    private var isGrantedNotificationAccess = false

    private let locationManager: CLLocationManager = {
        return CLLocationManager()
    }()
    private lazy var rootViewController: ViewController = {
        return self.window!.rootViewController as! ViewController
    }()
    
    private let saveRegionsKey    = "SavedRegions"
    private let saveKeyRadius     = "SavedRadius"
    private let saveKeyIdentifier = "SavedIdentifier"
    private let saveKeyLatitude   = "SavedLatitude"
    private let saveKeyLongitude  = "SavedLongitude"
    
    private func loadSavedRegion() -> CLCircularRegion? {
        guard let radius = UserDefaults.standard.object(forKey: saveKeyRadius) as? Double else {
            log.error("Failed to load region - radius is nil")
            return nil
        }
        guard let identifier = UserDefaults.standard.object(forKey: saveKeyIdentifier) as? String else {
            log.error("Failed to load region - id is nil")
            return nil
        }
        guard let latitude = UserDefaults.standard.object(forKey: saveKeyLatitude) as? CLLocationDegrees else {
            log.error("Failed to load region - latitude is nil")
            return nil
        }
        guard let longitude = UserDefaults.standard.object(forKey: saveKeyLongitude) as? CLLocationDegrees else {
            log.error("Failed to load region - longitude is nil")
            return nil
        }
        
        let point = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let region = CLCircularRegion(center: point, radius: radius, identifier: identifier)
        
        return region
    }
    private func saveRegion(region: CLCircularRegion?) {
        guard let region = region else {
            return
        }

        UserDefaults.standard.set(region.radius, forKey: saveKeyRadius)
        UserDefaults.standard.set(region.identifier, forKey: saveKeyIdentifier)
        UserDefaults.standard.set(region.center.latitude, forKey: saveKeyLatitude)
        UserDefaults.standard.set(region.center.longitude, forKey: saveKeyLongitude)
        
        log.info("Saved region: \(region)")
    }
    
    private func startMonitoring(forRegion region: CLCircularRegion?) {
        guard let startRegion = region else {
            log.warning("Region is nil")
            return
        }
        locationManager.startMonitoring(for: startRegion)
    }
    private func stopMonitoringForRegion(region: CLCircularRegion?) {
        guard let stopRegion = region else {
            log.warning("Region is nil")
            return
        }
        locationManager.stopMonitoring(for: stopRegion)
    }
    private func handleEvent(forRegion region: CLRegion!) {
        let message = "Fence triggered at: \(region)"
        let title = "Fence triggered"
        
        log.info(message)
        
        if UIApplication.shared.applicationState == .active {
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
            alertController.addAction(cancelAction)
            
            rootViewController.present(alertController, animated: true)
        } else {
            guard !isGrantedNotificationAccess else {
                log.error("Failed to send a local notification - access denied")
                return
            }
            
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = message
            content.categoryIdentifier = "message"
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1.0, repeats: false)
            let request = UNNotificationRequest(identifier: "\(region)", content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    self.log.error("Failed to send a local notification: \(error)")
                }
            }
        }
    }

}
