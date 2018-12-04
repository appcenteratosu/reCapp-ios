//
//  ProfileImageCacherTests.swift
//  reCapUITests
//
//  Created by App Center on 12/3/18.
//  Copyright © 2018 Kaleb Cooper. All rights reserved.
//

import XCTest
@testable import reCap

class ProfileImageCacherTests: XCTestCase {
    
    override func setUp() {
        
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func test_addingProfilePicture_actuallySavesImage() {
        
        let image = #imageLiteral(resourceName: "icon-messages-transcript-32x24")
        XCTAssertNotNil(image)
        
        ProfileImageCacher.AddNewProfilePicture(uid: "1234ABCD", image: image)
        
        let result = ProfileImageCacher.requestProfilePictureFor(uid: "1234ABCD")
        
        XCTAssertNotNil(result)
    }
    

}
