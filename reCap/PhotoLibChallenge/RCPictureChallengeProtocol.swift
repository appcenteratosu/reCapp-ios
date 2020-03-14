//
//  RCPictureChallengeProtocol.swift
//  reCap
//
//  Created by App Center on 12/5/18.
//  Copyright © 2018 Kaleb Cooper. All rights reserved.
//

import Foundation

protocol RCPictureChallengeDelegate {
    func userDidAddNewChallenge(picture: RCPicture)
    func userDidRemoveChallenge(picture: RCPicture)
}
