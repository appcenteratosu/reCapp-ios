////
//  MapViewModel.swift
//  HealthApp
//
//  Created by App Center on 12/28/18.
//  Copyright © 2018 rlukedavis. All rights reserved.
//

import Foundation
import MapboxNavigation
import CoreLocation

class MapViewModel {
    let map: NavigationMapView
    var userLocation: CLLocation
    
    var pictures: [RCPicture] = []
    var challengeImageCache = NSCache<NSString, NSData>()
    
    init(map: NavigationMapView, userLocation: CLLocation) {
        self.map = map
        self.userLocation = userLocation
    }

    func cache(image: UIImage, id: String) {
        if let data = UIImageJPEGRepresentation(image, 1.0) {
            let nsdata = data as NSData
            let nsString = NSString(string: id)
            
            challengeImageCache.setObject(nsdata, forKey: nsString)
        }
    }
}

