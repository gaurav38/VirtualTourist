//
//  UserDefaultsHelper.swift
//  VirtualTourist
//
//  Created by Gaurav Saraf on 1/11/17.
//  Copyright © 2017 Gaurav Saraf. All rights reserved.
//

import Foundation
import UIKit
import MapKit

class UserDefaultsHelper {
    static func isFirstLaunch() -> Bool {
        if UserDefaults.standard.object(forKey: "latitude") == nil ||
            UserDefaults.standard.object(forKey: "longitude") == nil {
            return true
        }
        return false
    }
    
    static func save(coordinates: CLLocationCoordinate2D) {
        UserDefaults.standard.set(coordinates.latitude, forKey: "latitude")
        UserDefaults.standard.set(coordinates.longitude, forKey: "longitude")
    }
    
    static func getSavedCoordinates() -> CLLocationCoordinate2D {
        let latitude = UserDefaults.standard.value(forKey: "latitude")
        let longitude = UserDefaults.standard.value(forKey: "longitude")
        let coordinate = CLLocationCoordinate2DMake(latitude as! CLLocationDegrees, longitude as! CLLocationDegrees)
        return coordinate
    }
    
    static func save(latitudeDelta: Double, longitudeDelta: Double) {
        UserDefaults.standard.set(latitudeDelta, forKey: "latitudeDelta")
        UserDefaults.standard.set(longitudeDelta, forKey: "longitudeDelta")
    }
    
    static func getSavedLatitudeDelta() -> CLLocationDegrees {
        let delta = UserDefaults.standard.value(forKey: "latitudeDelta") as! Double
        return CLLocationDegrees(delta)
    }
    
    static func getSavedLongitudeDelta() -> CLLocationDegrees {
        let delta = UserDefaults.standard.value(forKey: "longitudeDelta") as! Double
        return CLLocationDegrees(delta)
    }
}
