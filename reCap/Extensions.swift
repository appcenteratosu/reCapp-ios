//
//  Extensions.swift
//  reCap
//
//  Created by Kaleb Cooper on 2/8/18.
//  Copyright © 2018 Kaleb Cooper. All rights reserved.
//

import Foundation
import UIKit
import FCAlertView
import CoreLocation

extension Double
{
    func truncate(places : Int)-> Double
    {
        return Double(floor(pow(10.0, Double(places)) * self)/pow(10.0, Double(places)))
    }
    
    func round(nearest: Double) -> Double {
        let n = 1 / nearest
        let numberToRound = self * n
        return numberToRound.rounded() / n
    }
}

extension String
{
    static func convertGPSCoordinatesToOutput(coordinates: [Double]) -> String {
        
        let lat = coordinates[0]
        var latString: String
        let long = coordinates[1]
        var longString: String
        
        if lat > 0 {
            latString = "\(lat)°N"
        } else {
            latString = "\(lat)°S"
        }
        
        if long > 0 {
            longString = "\(long)°E"
        }
        else {
            longString = "\(long)°W"
        }
        
        let returnString = latString + " , " + longString
        return returnString
        
    }
}

extension Bool {
    
    static func checkIfTimeIs(between: Int, and: Int) -> Bool {
        
        let calendar = Calendar.current
        let now = Date()
        
        let date1 = calendar.date(bySettingHour: between, minute: 0, second: 0, of: now)!
        
        var date2 = Date()
        
        if and == 23 {
            date2 = calendar.date(bySettingHour: and, minute: 59, second: 59, of: now)!
        }
        else {
            date2 = calendar.date(bySettingHour: and, minute: 0, second: 0, of: now)!
        }
        
        
        
        if now >= date1 && now <= date2 {
            return true
        }
        else {
            return false
        }
        
    }
    
}

extension FCAlertView
{
    
    static func displayAlert(title: String, message: String, buttonTitle: String, type: String, view: UIViewController, blur: Bool = false) {
        let alert = FCAlertView()
        alert.dismissOnOutsideTouch = true
        alert.darkTheme = true
        alert.bounceAnimations = true
        
        if blur == true {
            alert.blurBackground = true
        }
        
        if type == "caution" {
            alert.makeAlertTypeCaution()
        }
        else if type == "warning" {
            alert.makeAlertTypeWarning()
        }
        else if type == "success" {
            alert.makeAlertTypeSuccess()
        }
        else if type == "progress" {
            alert.makeAlertTypeProgress()
            alert.blurBackground = true
            
            let when = DispatchTime.now() + 1 // change 2 to desired number of seconds
            DispatchQueue.main.asyncAfter(deadline: when) {
                alert.dismiss()
            }
        }
        
        let titleString = title
        let subtitleString = message
        
        alert.showAlert(inView: view,
                        withTitle: titleString,
                        withSubtitle: subtitleString,
                        withCustomImage: nil,
                        withDoneButtonTitle: buttonTitle,
                        andButtons: nil)
    }
    
    
}


extension UIViewController
{
    func hideKeyboard()
    {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(UIViewController.dismissKeyboard))
        
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard()
    {
        view.endEditing(true)
    }
}


extension UIView{
    func rotateToDestination(from: Double, to: Double) {
        
        let rotation : CABasicAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotation.fromValue = NSNumber(value: from)
        rotation.toValue = NSNumber(value: to)
        rotation.duration = 0.25
        rotation.isCumulative = true
        rotation.repeatCount = Float.greatestFiniteMagnitude
        self.layer.add(rotation, forKey: "rotationAnimation")
        
        
    }
}


extension UINavigationController {
    open override var preferredStatusBarStyle: UIStatusBarStyle {
        return topViewController?.preferredStatusBarStyle ?? .default
    }
}

struct AppUtility {
    
    static func lockOrientation(_ orientation: UIInterfaceOrientationMask) {
        
        if let delegate = UIApplication.shared.delegate as? AppDelegate {
            delegate.orientationLock = orientation
        }
    }
    
    /// OPTIONAL Added method to adjust lock and rotate to the desired orientation
    static func lockOrientation(_ orientation: UIInterfaceOrientationMask, andRotateTo rotateOrientation:UIInterfaceOrientation) {
        
        self.lockOrientation(orientation)
        
        UIDevice.current.setValue(rotateOrientation.rawValue, forKey: "orientation")
    }
    
}

extension CLLocation {
    /// Checks to see if a certain image is in range of the current photo
    ///
    /// - Parameters:
    ///   - range: The range in miles
    ///   - picture: The picture to check if in range
    func isIn(range: Double, of picture: CLLocation) -> Bool {
        let rangeInMiles = Measurement(value: range, unit: UnitLength.miles)
        let rangeInMeters = rangeInMiles.converted(to: UnitLength.meters).value
        
        let distanceInMeters = self.distance(from: picture)
        
        if distanceInMeters <= rangeInMeters {
            return true
        } else {
            return false
        }
    }
}

extension BinaryInteger {
    var degreesToRadians: CGFloat { return CGFloat(Int(self)) * .pi / 180 }
}

extension FloatingPoint {
    var degreesToRadians: Self { return self * .pi / 180 }
    var radiansToDegrees: Self { return self * 180 / .pi }
}


extension UIImage {
    func convertToData() -> Data? {
        if let data = UIImagePNGRepresentation(self) {
            return data
        } else {
            return nil
        }
    }
}

extension Data {
    func convertToUIImage() -> UIImage? {
        if let image = UIImage(data: self) {
            return image
        } else {
            return nil
        }
    }
}
