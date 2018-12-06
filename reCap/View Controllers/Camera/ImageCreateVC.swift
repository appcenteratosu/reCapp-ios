//
//  ImageCreateVC.swift
//  reCap
//
//  Created by Kaleb Cooper on 2/9/18.
//  Copyright © 2018 Kaleb Cooper. All rights reserved.
//
import UIKit
import IHKeyboardAvoiding
import SkyFloatingLabelTextField
import Firebase
import SwiftLocation
import CoreLocation
import FCAlertView
import Pageboy

class ImageCreateVC: UIViewController, PageboyViewControllerDelegate, UITextFieldDelegate {
    
    var image: UIImage?
    var lat: Double?
    var long: Double?
    var bearing: Double?
    var location: String?
    var isAtChallengeLocation: Bool!
    var previousPic: RCPicture!
    var userData: RCUser!
    var challengePoints: String?
    
    @IBOutlet weak var imageBackground: UIImageView!
    @IBOutlet weak var imageView: UIImageView!
    
    
    @IBOutlet weak var locationOutlet: UILabel!
    @IBOutlet weak var locationNameOutlet: UILabel!
    @IBOutlet weak var titleOutlet: SkyFloatingLabelTextField!
    @IBOutlet weak var descriptionOutlet: SkyFloatingLabelTextField!
    
    @IBOutlet var avoidingView: UIView!
    
    @IBAction func cancelPressed(_ sender: Any) {
        
        self.navigationController?.setToolbarHidden(true, animated: true)
        self.navigationController?.popToRootViewController(animated: true)
        
    }
    
    @IBAction func confirmPressed(_ sender: Any) {
        print("Confirmed Pressed")
        var isRoot: Bool!
        var groupID: String!
        let currentDate = Int((Date().timeIntervalSince1970))
        
        FCAlertView.displayAlert(title: "Saving Picture...", message: "Adding your picture to the database...", buttonTitle: "", type: "progress", view: self)
        
        if self.isAtChallengeLocation {
            // If the user took the picture at the challenge coordinates, there is an active challenge
            let points = self.userData.points + self.userData.activeChalengePoints
            self.previousPic.isMostRecent = false
            isRoot = false
            groupID = self.previousPic.groupID
            
            userData.update(values: [.points : points,
                                     .activeChallenge: ""])
            self.challengePoints = "\(self.userData.activeChalengePoints)"
            
        } else {
            print("root picture")
            isRoot = true
            groupID = ""
        }
        
        let picture = RCPicture()
        picture.name = self.titleOutlet.text!
        picture.name = self.titleOutlet.text!
        picture.info = self.descriptionOutlet.text!
        picture.owner = self.userData.id
        picture.latitude = self.lat!
        picture.longitude = self.long!
        picture.bearing = self.bearing!
        picture.orientation = RCPicture.ORIENTATION_PORTRAIT
        picture.time = currentDate
        picture.locationName = self.locationNameOutlet.text!
        picture.isRoot = isRoot
        picture.isMostRecent = true
        
        Log.d("Starting database reference creation for new image")
        FirebaseHandler.createPictureDataReference(pictureData: picture) { (updatedPic) in
            if let picData = updatedPic {
                
                FirebaseHandler.storeImage(image: self.image!, picture: picData, whenDone: {
                    if self.isAtChallengeLocation {
                        self.displayChallengeComplete()
                    }
                    else {
                        self.displayPictureAdded(pictureData: picture)
                    }
                    self.navigationController?.setToolbarHidden(true, animated: true)
                    self.navigationController?.popToRootViewController(animated: true)
                })
            } else {
                Log.e("Could not get updated RCPicture. Will Not be storing Image")
            }
        }
    }
    
    private func displayChallengeComplete() {
        
        let challengePoints = self.challengePoints!
        let totalPoints: Int = self.userData.points
        
        let titleString = "+\(challengePoints) Points"
        let subtitleString = "Good Job! You now have \(totalPoints) points!"
        
        FCAlertView.displayAlert(title: titleString, message: subtitleString, buttonTitle: "Hooray!", type: "success", view: self, blur: true)
        
    }
    
    private func displayPictureAdded(pictureData: RCPicture) {
        
        let titleString = "Picture Added"
        let subtitleString = "Good Job! You now have added \(pictureData.name) to your library"
        
        FCAlertView.displayAlert(title: titleString, message: subtitleString, buttonTitle: "Hooray!", type: "success", view: self, blur: true)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboard()
        
        let duration: TimeInterval = TimeInterval(exactly: 0.5)!
        imageView.hero.modifiers = [.forceNonFade, .duration(duration)]
        
        
        let coordinates = CLLocationCoordinate2D(latitude: lat!, longitude: long!)
        Locator.location(fromCoordinates: coordinates, using: .apple, onSuccess: { places in
            print(places)
            self.locationNameOutlet.text = "\(places[0])"
        }) { err in
            print(err)
        }
        
        
        
        imageView.image = image
        self.locationOutlet.text = self.location
        
        applyBlurEffect(image: image!)
        
        KeyboardAvoiding.avoidingView = self.avoidingView
        
        descriptionOutlet.delegate = self
        
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
    }
    
    
    
    func applyBlurEffect(image: UIImage){
        let imageToBlur = CIImage(image: image)
        let blurfilter = CIFilter(name: "CIGaussianBlur")
        blurfilter?.setValue(imageToBlur, forKey: "inputImage")
        let resultImage = blurfilter?.value(forKey: "outputImage") as! CIImage
        let blurredImage = UIImage(ciImage: resultImage)
        self.imageBackground.image = blurredImage
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == titleOutlet {
            descriptionOutlet.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        
        return true
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}
