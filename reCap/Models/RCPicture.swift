//
//  RCPicture.swift
//  reCap
//
//  Created by App Center on 11/16/18.
//  Copyright © 2018 Kaleb Cooper. All rights reserved.
//

import Foundation
import FirebaseDatabase

class RCPicture: Codable {

    static let ORIENTATION_PORTRAIT = 0
    static let ORIENTATION_LANDSCAPE_LEFT = 1
    static let ORIENTATION_LANDSCAPE_RIGHT = 2
    static let LONGITUDE_INDEX = 1
    static let LATTITUDE_INDEX = 0

    var id: String
    var name: String
    var latitude: Double
    var longitude: Double
    var bearing: Double
    
    /// Uses UIImage.Orientation
    var orientation: Int
    
    var time: Int
    var owner: String
    var locationName: String
    var isRoot: Bool
    var isMostRecent: Bool
    var groupID: String
    var info: String
    var image: Data?
    
    init() {
        id = ""
        name = ""
        latitude = 0.0
        longitude = 0.0
        bearing = 0
        orientation = 0
        time = 0
        owner = ""
        locationName = ""
        isRoot = true
        isMostRecent = true
        groupID = ""
        info = ""
    }
    
    convenience init(snapshot: DataSnapshot) {
        self.init()
        if let data = snapshot.value as? [String: Any] {
            if let info = data["id"] as? String {
                self.id = info
            }
            if let info = data["name"] as? String {
                self.name = info
            }
            if let info = data["latitude"] as? Double {
                self.latitude = info
            }
            if let info = data["longitude"] as? Double {
                self.longitude = info
            }
            if let info = data["bearing"] as? Double {
                self.bearing = info
            }
            if let info = data["orientation"] as? Int {
                self.orientation = info
            }
            if let info = data["time"] as? Int {
                self.time = info
            }
            if let info = data["owner"] as? String {
                self.owner = info
            }
            if let info = data["locationName"] as? String {
                self.locationName = info
            }
            if let info = data["isRootPicture"] as? Bool {
                self.isRoot = info
            }
            if let info = data["isMostRecentPicture"] as? Bool {
                self.isMostRecent = info
            }
            if let info = data["groupID"] as? String {
                self.groupID = info
            }
            if let info = data["info"] as? String {
                self.info = info
            }
        }
    }
    
    func convertToRealm(with image: UIImage? = nil, dataImage: Data? = nil) {
        let realmImage = PictureData()
        realmImage.id = self.id
        realmImage.name = self.name
        realmImage.latitude = self.latitude
        realmImage.longitude = self.longitude
        realmImage.bearing = self.bearing
        realmImage.orientation = self.orientation
        realmImage.time = self.time
        realmImage.owner = self.owner
        realmImage.locationName = self.locationName
        realmImage.isRootPicture = self.isRoot
        realmImage.isMostRecentPicture = self.isMostRecent
        realmImage.groupID = self.groupID
        realmImage.info = self.info
        realmImage.image = dataImage
        
        if let image = image {
            if let data = image.pngData() {
                realmImage.image = data
            }
        }
        
        guard let realm = RealmHelper.realm else { return }
        
        try! realm.write {
            realm.add(realmImage, update: .error)
        }
    }
    
    func fetchPhoto(completion: (UIImage)->()) {
        FirebaseHandler.downloadPicture(pictureData: self) { (image) in
            self.image = image?.convertToData()
        }
    }
}
