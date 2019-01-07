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
    let networkService = MapNetworkService()
    let map: NavigationMapView
    var userLocation: CLLocation
    
    var pictures: [RCPicture] = []
    var challengeImageCache = NSCache<NSString, NSData>()
    
    init(map: NavigationMapView, userLocation: CLLocation) {
        self.map = map
        self.userLocation = userLocation
        self.getLocalImageData()
    }
    
    func getLocalImageData() {
        let extrema = getRadialExtrema(from: userLocation.coordinate, adding: 50)
        networkService.getPictureData(in: extrema) { (pictures) in
            guard pictures != nil else { return }
            guard pictures!.count > 0 else { return }
            self.getImages(for: pictures!)
        }
    }
    
    func getImages(for pictureData: [RCPicture]) {
        for picture in pictureData {
            networkService.downloadImage(for: picture) { (image) in
                if let image = image {
                    self.cache(image: image, id: picture.id)
                    self.pictures.append(picture)
                } else {
                    Log.e("Didn't get image back from call")
                }
            }
        }
    }
    
    /// Estimates the approximate latitude and longitude a given distance away from specified location
    func getRadialExtrema(from coord: CLLocationCoordinate2D, adding distance: Double) -> [Double] {
        let bearings = [0.0, 90.0, 180.0, 270.0]
        
        var minLat: Double = 0.0
        var maxLat: Double = 0.0
        var minLon: Double = 0.0
        var maxLon: Double = 0.0
        
        let earthRadius = 6378.1
        let latR = coord.latitude.degreesToRadians
        let lonR = coord.longitude.degreesToRadians
        let dR = distance / earthRadius
        
        for bearing in bearings {
            let bearingRadians = bearing.degreesToRadians
            
            let lat2 = asin(sin(latR) * cos(dR) + cos(latR) * sin(dR) * cos(bearingRadians))
            let lon2 = lonR + atan2(sin(bearingRadians) * sin(dR) * cos(latR), cos(dR) - sin(latR) * sin(lat2))
            
            let newLat = lat2.radiansToDegrees
            let newLon = lon2.radiansToDegrees
            
            let newLocation = CLLocation(latitude: CLLocationDegrees(exactly: newLat)!,
                                         longitude: CLLocationDegrees(exactly: newLon)!)
            
            print(newLat, newLon)
            
            switch bearing {
            case bearings[0]:
                maxLat = newLocation.coordinate.latitude
            case bearings[1]:
                maxLon = newLocation.coordinate.longitude
            case bearings[2]:
                minLat = newLocation.coordinate.latitude
            case bearings[3]:
                minLon = newLocation.coordinate.longitude
            default:
                break
            }
            
        }
        
        return [maxLat, maxLon, minLat, minLon]
    }

    func cache(image: UIImage, id: String) {
        if let data = UIImageJPEGRepresentation(image, 1.0) {
            let nsdata = data as NSData
            let nsString = NSString(string: id)
            
            challengeImageCache.setObject(nsdata, forKey: nsString)
        }
    }
}

