//
//  SignUpVC.swift
//  reCap
//
//  Created by Jackson Delametter on 2/4/18.
//  Copyright © 2018 Kaleb Cooper. All rights reserved.
//

import UIKit
import Hero
import SkyFloatingLabelTextField
import Firebase
import FCAlertView


class CreateAccountVC: UITableViewController, UINavigationControllerDelegate{
    
    // MARK: - Outlets
    @IBOutlet weak var fullNameOutlet: SkyFloatingLabelTextField!
    @IBOutlet weak var emailOutlet: SkyFloatingLabelTextField!
    @IBOutlet weak var passwordOutlet: SkyFloatingLabelTextField!
    @IBOutlet weak var verifyPasswordOutlet: SkyFloatingLabelTextField!
    @IBOutlet weak var imageOutlet: UIButton!
    @IBOutlet weak var imageView: UIImageView!
    
    // MARK: - Properties
    var gradientLayer: CAGradientLayer!
    var pickedImageUrl: URL!
    var pickedImage: UIImage!
    
    // MARK: - Contansts
    private static let PAGE_VIEW_SEGUE = "PageViewSegue"
    
    // MARK: - View Controller Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        let duration: TimeInterval = TimeInterval(exactly: 0.5)!
        setup()
        // Do any additional setup after loading the view.
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AppUtility.lockOrientation(.portrait)
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        AppUtility.lockOrientation(.all)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    // MARK: - Setup Methods
    private func setup() {
        createGradientLayer()
        setupNavigationController()
        self.hideKeyboard()
        self.title = "Create Account"
        self.tableView.allowsSelection = false
        
        imageView.layer.borderWidth = 1
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.layer.cornerRadius = imageView.layer.frame.width / 2
        
        fullNameOutlet.delegate = self
        emailOutlet.delegate = self
        passwordOutlet.delegate = self
        verifyPasswordOutlet.delegate = self
    }
    
    private func setupNavigationController() {
        let logo = #imageLiteral(resourceName: "Logo Text Wide")
        let imageView = UIImageView(image:logo)
        imageView.hero.id = "logoID"
        let duration: TimeInterval = TimeInterval(exactly: 0.5)!
        imageView.hero.modifiers = [.forceNonFade, .duration(duration)]
        
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.view.backgroundColor = UIColor.clear
        
        let bannerWidth = self.navigationController?.navigationBar.frame.size.width
        let bannerHeight = self.navigationController?.navigationBar.frame.size.height
        let bannerx = bannerWidth! / 2 - logo.size.width / 2
        let bannery = bannerHeight! / 2 - logo.size.height / 2
        imageView.frame = CGRect(x: bannerx, y: bannery, width: bannerWidth!, height: bannerHeight!)
        
        imageView.contentMode = .scaleAspectFit
        
        self.navigationItem.titleView = imageView
    }

    private func createGradientLayer() {
        gradientLayer = CAGradientLayer()
        
        gradientLayer.frame = self.view.bounds
        
        let bottomColor = UIColor(displayP3Red: 99/255, green: 207/255, blue: 155/255, alpha: 1).cgColor
        let topColor = UIColor(displayP3Red: 9/255, green: 85/255, blue: 95/255, alpha: 1).cgColor
        
        gradientLayer.colors = [topColor, bottomColor]
        
        //self.tableView.layer.insertSublayer(gradientLayer, at: 0)
        //self.tableView.backgroundView?.layer.insertSublayer(gradientLayer, at: 1)
        //self.view.layer.insertSublayer(gradientLayer, at: 0)
        let background: UIView? = UIView(frame: self.view.frame)
        background?.layer.insertSublayer(gradientLayer, at: 0)
        self.tableView.backgroundView = background
    }
    
    // MARK: - Outlet Actions
    @IBAction func addPressed(_ sender: Any) {
        let name = fullNameOutlet.text
        let email = emailOutlet.text
        let password = passwordOutlet.text
        let verifyPass = verifyPasswordOutlet.text
        if name != "", email != "", password != "", verifyPass != "" {
            // If all fields are filled out
            let image = imageView.image
            if image == nil {
                // User has not selected profile picture
                let alert = FCAlertView()
                alert.dismissOnOutsideTouch = false
                alert.showAlert(inView: self,
                                withTitle: "Select an image",
                                withSubtitle: nil,
                                withCustomImage: nil,
                                withDoneButtonTitle: nil,
                                andButtons: nil)
                return
            }
            else if password != verifyPass {
                // Users passwords do not match up
                let alert = FCAlertView()
                alert.dismissOnOutsideTouch = false
                alert.showAlert(inView: self,
                                withTitle: "Password must match",
                                withSubtitle: nil,
                                withCustomImage: nil,
                                withDoneButtonTitle: nil,
                                andButtons: nil)
                return
            }
            else if !isValidEmail(email: email) {
                // Determines if the given email is valid
                let alert = FCAlertView()
                alert.dismissOnOutsideTouch = false
                alert.showAlert(inView: self,
                                withTitle: "Not a valid email",
                                withSubtitle: nil,
                                withCustomImage: nil,
                                withDoneButtonTitle: nil,
                                andButtons: nil)
                return
            }
            print("Creating user")
            let progressAlert = FCAlertView()
            progressAlert.makeAlertTypeProgress()
            progressAlert.dismissOnOutsideTouch = false
            let titleString = "Creating account"
            progressAlert.showAlert(inView: self,
                            withTitle: titleString,
                            withSubtitle: nil,
                            withCustomImage: nil,
                            withDoneButtonTitle: nil,
                            andButtons: nil)
            
            FirebaseHandler.createAccount(name: name!, email: email!, password: password!) { (error, user) in
                if error != nil {
                    progressAlert.dismiss()
                    self.displayErrorAlert(message: error!.localizedDescription)
                } else {
                    if let user = user {
                        let newUser = ChallengeSetup()
                        newUser.id = user.uid
                        newUser.name = name!
                        newUser.email = email!
                        
                        FirebaseHandler.createUserDataReference(userData: newUser, completion: { (error) in
                            FirebaseHandler.storeProfilePicture(image: image!, userID: user.uid, completion: { (error) in
                                if error != nil {
                                    self.displayErrorAlert(message: error!.localizedDescription)
                                } else {
                                    progressAlert.dismiss()
                                    
                                    DataManager.currentAppUser = newUser
                                    DataManager.currentFBUser = user
                                    
                                    let eula = EULAViewController()
                                    eula.delegate = self
                                    self.pickedImage = image
                                    
                                    self.present(eula, animated: true, completion: nil)
                                }
                            })
                        })
                    } else {
                        progressAlert.dismiss()
                        self.displayErrorAlert(message: "Something went wrong. Please try again in a little bit")
                    }
                }
            }
        
        }
        else {
            print("Fill out all fields")
            displayErrorAlert(message: "Please fill out all fields.")
        }
    }
    
    @IBAction func selectImagePressed(_ sender: Any) {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = UIImagePickerController.SourceType.photoLibrary
        imagePicker.delegate = self
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    // MARK: - Class Methods
    private func displayErrorAlert(message: String) {
        let alert = FCAlertView()
        alert.makeAlertTypeWarning()
        alert.dismissOnOutsideTouch = true
        
        
        let titleString = "Oops!"
        let subtitleString = message
        
        alert.showAlert(inView: self,
                        withTitle: titleString,
                        withSubtitle: subtitleString,
                        withCustomImage: nil,
                        withDoneButtonTitle: "Try Again",
                        andButtons: nil)
    }
    
    /// validate an email for the right format
    private func isValidEmail(email:String?) -> Bool {
        
        guard email != nil else { return false }
        
        let regEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        
        let pred = NSPredicate(format:"SELF MATCHES %@", regEx)
        let evaluate = pred.evaluate(with: email)
        return evaluate
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.identifier == CreateAccountVC.PAGE_VIEW_SEGUE {
            let image = sender as! UIImage
            let destination = segue.destination as! PageViewController
            destination.profileImage = image
        }
    }
}

// MARK: - Image Picker Methods
extension CreateAccountVC: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let pickedImage = info[.originalImage] as? UIImage else {
            return
        }
        // A valid image was picked
        //imageOutlet.setBackgroundImage(pickedImage, for: .normal)
        
        imageView.image = pickedImage
        imageView.layer.borderWidth = 1
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.layer.cornerRadius = imageView.layer.frame.width / 2
        imageView.layer.masksToBounds = false
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        
        imageOutlet.setTitle("", for: .normal)
        
        guard let imageData = pickedImage.pngData() else { return }
        UserDefaults.standard.set(imageData, forKey: "profileImage")
        picker.dismiss(animated: true, completion: nil)
    }
}

// MARK: - Table View Methods
extension CreateAccountVC {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
}

// MARK: - EULA Delegate
extension CreateAccountVC: EULAViewControllerDelegate {
    
    func didAgree(controller: EULAViewController) {
        controller.dismiss(animated: true) {
            self.performSegue(withIdentifier: CreateAccountVC.PAGE_VIEW_SEGUE, sender: self.pickedImage)
        }
    }
    
    func didCancel(controller: EULAViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
    
}

// MARK: - UITextfield Delegate
extension CreateAccountVC: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == fullNameOutlet {
            emailOutlet.becomeFirstResponder()
        } else if textField == emailOutlet {
            passwordOutlet.becomeFirstResponder()
        } else if textField == passwordOutlet {
            verifyPasswordOutlet.becomeFirstResponder()
        } else if textField == verifyPasswordOutlet {
            textField.resignFirstResponder()
        }
        
        return true
    }
}
