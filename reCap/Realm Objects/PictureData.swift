//
//  Picture.swift
//  reCap
//
//  Created by Jackson Delametter on 4/8/18.
//  Copyright © 2018 Kaleb Cooper. All rights reserved.
//

//
//  PictureData.swift
//  reCap
//
//  Created by Jackson Delametter on 2/4/18.
//  Copyright © 2018 Kaleb Cooper. All rights reserved.
//
import Foundation
import FirebaseDatabase
import RealmSwift

class PictureData: Object {
    
    // MARK: - Constants
    static let ORIENTATION_PORTRAIT = 0
    static let ORIENTATION_LANDSCAPE = 1
    static let LONGITUDE_INDEX = 1
    static let LATTITUDE_INDEX = 0
    
    // MARK: - Properties
    @objc dynamic var name: String!
    @objc dynamic var info: String!
    @objc dynamic var id: String!
    @objc dynamic var latitude = 0.0
    @objc dynamic var longitude = 0.0
    @objc dynamic var bearing = 0.0
    @objc dynamic var orientation = PictureData.ORIENTATION_PORTRAIT
    @objc dynamic var owner: String!
    @objc dynamic var time = 0
    @objc dynamic var locationName: String!
    @objc dynamic var isRootPicture = true
    @objc dynamic var isMostRecentPicture = true
    @objc dynamic var groupID: String!
    @objc dynamic var image: Data? = nil
    
    @objc dynamic var test: Bool = false
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    // MARK: - Initializers
    convenience required init(name: String!, info: String, owner: ChallengeSetup, latitude: Double, longitude: Double, bearing: Double, orientation: Int, time: Int, locationName: String, id: String, isRootPicture: Bool, groupID: String, isMostRecentPicture: Bool) {
        self.init()
        self.name = name
        self.info = info
        self.orientation = orientation
        self.latitude = latitude
        self.longitude = longitude
        self.bearing = bearing
        self.time = time
        self.owner = owner.id
        self.locationName = locationName
        self.id = id
        self.isRootPicture = isRootPicture
        self.groupID = groupID
        self.isMostRecentPicture = isMostRecentPicture
    }
    
    convenience init(snapshot: DataSnapshot) {
        self.init()
        if let data = snapshot.value as? [String: Any] {
            if let info = data["name"] as? String {
                self.name = info
            }
            if let info = data["info"] as? String {
                self.info = info
            }
            if let info = data["orientation"] as? Int {
                self.orientation = info
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
            if let info = data["time"] as? Int {
                self.time = info
            }
            if let info = data["owner"] as? String {
                self.owner = info
            }
            if let info = data["locationName"] as? String {
                self.locationName = info
            }
            if let info = data["id"] as? String {
                self.id = info
            }
            if let info = data["isRootPicture"] as? Bool {
                self.isRootPicture = info
            }
            if let info = data["groupID"] as? String {
                self.groupID = info
            }
            if let info = data["isMostRecentPicture"] as? Bool {
                self.isMostRecentPicture = info
            }
        }
    }
    
    func convertToRCPicture() -> RCPicture {
        let picture = RCPicture()
        picture.name = self.name
        picture.info = self.info
        picture.id = self.id
        picture.latitude = self.latitude
        picture.longitude = self.longitude
        picture.bearing = self.bearing
        picture.orientation = self.orientation
        picture.owner = self.owner
        picture.time = self.time
        picture.locationName = self.locationName
        picture.isRoot = self.isRootPicture
        picture.isMostRecent = self.isMostRecentPicture
        picture.groupID = self.groupID
        picture.image = self.image
        
        return picture
    }
    
}

