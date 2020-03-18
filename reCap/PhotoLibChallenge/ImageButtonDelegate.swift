//
//  ImageButtonDelegate.swift
//  reCap
//
//  Created by Jackson Delametter on 2/24/18.
//  Copyright © 2020 OSU App Center. All rights reserved.
//

import Foundation
import UIKit

protocol ImageButtonDelegate: class {
    func imageButtonPressed(image: UIImage, pictureData: RCPicture)
}
