//
//  CameraContainerVC.swift
//  reCap
//
//  Created by Kaleb Cooper on 2/6/18.
//  Copyright © 2018 Kaleb Cooper. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit
import SwiftLocation
import Hero
import Firebase
import CoreLocation
import CoreMotion
import FCAlertView


class CameraContainerVC: UIViewController, AVCapturePhotoCaptureDelegate, UINavigationControllerDelegate, CLLocationManagerDelegate, HorizontalDialDelegate {
    
    // MARK: - Outlets
    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var locationOutlet: UILabel!
    @IBOutlet weak var logoText: UIImageView!
    @IBOutlet weak var profileOutlet: UIImageView!
    @IBOutlet weak var albumOutlet: UIButton!
    @IBOutlet weak var previousOutlet: UIButton!
    @IBOutlet weak var arrowOutlet: UIImageView!
    
    @IBOutlet weak var previewView: UIView!
    
    @IBOutlet weak var bearingPickerOutlet: HorizontalDial!
    @IBOutlet weak var bearingOutlet: UILabel!
    
    // MARK: - Properties
    var imageToPass: UIImage?
    var latToPass: Double?
    var longToPass: Double?
    var bearingToPass: Double?
    var locationToPass: String?
    private var isAtChallengeLocation: Bool!
    let locationManager = CLLocationManager()
    var destinationAngle: Double? = nil
    private var rcUser: ChallengeSetup!
    private var hasUpdateUserLocation = false
    var profileImage: UIImage?
    var session: AVCaptureSession?
    var stillImageOutput: AVCapturePhotoOutput?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var photoSetting = AVCapturePhotoSettings()
    var captureDevice: AVCaptureDevice?
    var captureDeviceInput: AVCaptureDeviceInput?
    var previousImageView: UIImageView?
    var previousImageContentMode: UIView.ContentMode?
    
    var motionManager = CMMotionManager()
    let geocoder = CLGeocoder()
    var firstRun = true
    
    let blackColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
    var user: User!
    private var activeChallengePicData: RCPicture!
    private let chalBestCoordThreshold = 0.0001
    private let chalCloseCoordThreshold = 0.005
    
    public var isLoadingFromSelf = false
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        Log.i("Camera container loaded")
        setupHero()
        setupCamera(clear: false)
        configureButton()
        setupGestures()
        setupDial()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.rcUser = DataManager.currentAppUser
        self.setupActiveChallenge()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.hasUpdateUserLocation = false
        for request in CameraContainerVC.requests {
            request.stop()
        }
        
        LocationManager.shared.completeAllLocationRequest()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Log.i("Starting Camera Main setup ")
        setup()

    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        
        UIView.animate(withDuration: 0.25, animations: {
            self.previousImageView?.alpha = 0.0
        })
        
        if self.previousImageContentMode == .scaleToFill {
            if UIDevice.current.orientation == .landscapeLeft || UIDevice.current.orientation == .landscapeRight {
                
                self.previousImageView?.frame = self.previewView.frame
                self.previousImageView?.contentMode = .center
                self.previousOutlet.isEnabled = false
                
            } else {
                self.previousImageView?.contentMode = .scaleToFill
                self.previousOutlet.isEnabled = true
            }
        }
        
        let when = DispatchTime.now() + 0.01 // change 2 to desired number of seconds
        DispatchQueue.main.asyncAfter(deadline: when) {
            self.viewDidAppear(false)
        }
    }
    
    // MARK: - Setup
    private func setup() {
        self.rcUser = DataManager.currentAppUser
        if self.rcUser != nil {
            // Got user data from database
            self.setupProfileImage()
            self.setupActiveChallenge()
            self.setupLocation()
        } else {
            Log.d("Did not get user data")
        }
        
        DispatchQueue.main.async {
            if self.videoPreviewLayer != nil {
                self.setupOrientation()
                if self.session?.inputs.count == 0 {
                    self.setupCamera(clear: false)
                }
                self.locationManager.startUpdatingHeading()
            }
        }
    }
    
    private func setupProfileImage() {
        if self.profileImage != nil {
            self.profileOutlet.image = self.profileImage
            self.profileOutlet.layer.borderWidth = 1
            self.profileOutlet.layer.borderColor = UIColor.white.cgColor
            self.profileOutlet.layer.cornerRadius = self.profileOutlet.layer.frame.width / 2
            self.profileOutlet.layer.masksToBounds = false
            self.profileOutlet.clipsToBounds = true
            self.profileOutlet.contentMode = .scaleAspectFill
        } else {
            if let user = Auth.auth().currentUser {
                FirebaseHandler.getProfilePicture(userID: user.uid, completion: { (profilePicture) in
                    if let profilePic = profilePicture {
                        self.profileImage = profilePic
                        
                        self.profileOutlet.image = self.profileImage
                        self.profileOutlet.layer.borderWidth = 1
                        self.profileOutlet.layer.borderColor = UIColor.white.cgColor
                        self.profileOutlet.layer.cornerRadius = self.profileOutlet.layer.frame.width / 2
                        self.profileOutlet.layer.masksToBounds = false
                        self.profileOutlet.clipsToBounds = true
                        self.profileOutlet.contentMode = .scaleAspectFill
                        
                    } else {
                        print("Did not get profile picture in Camera Container VC")
                    }
                }) { (progress) in
                    
                }
            }
            
        }
        
    }
    
    private func setupActiveChallenge() {
        self.previousOutlet.isEnabled = false
        self.rcUser.getActiveChallenge { (challenge) in
            if let picture = challenge {
                self.activeChallengePicData = picture
                
                if self.activeChallengePicData != nil {
                    // There is an active challenge
                    FirebaseHandler.downloadPicture(pictureData: picture, completion: { (image) in
                        if let realImage = image {
                            self.previousImageView = UIImageView(frame: self.view.frame)
                            self.previousImageView?.image = realImage
                            self.previousImageView?.alpha = 0.0
                            
                            if realImage.imageOrientation == .left || realImage.imageOrientation == .right {
                                self.previousImageView?.contentMode = .scaleToFill
                                self.previousImageContentMode = .scaleToFill
                            } else {
                                self.previousImageView?.contentMode = .scaleAspectFill
                                self.previousImageContentMode = .scaleAspectFill
                            }
                            self.previousOutlet.isEnabled = true
                            self.arrowOutlet.isHidden = false
                            self.previewView.addSubview(self.previousImageView!)
                        }
                        else {
                            // Could not get image
                            self.previousOutlet.isEnabled = false
                            self.arrowOutlet.isHidden = true
                        }
                    })
                } else {
                    self.previousOutlet.isEnabled = false
                    self.arrowOutlet.isHidden = true
                }
            } else {
                print("No Active Challenge")
                self.arrowOutlet.isHidden = true
            }
        }
    }
    
    private func setupDial() {
        
        bearingPickerOutlet?.delegate = self
        bearingPickerOutlet?.animateOption = .easeOutElastic
        bearingPickerOutlet?.enableRange = true
        bearingPickerOutlet?.minimumValue = 0
        bearingPickerOutlet?.maximumValue = 359
        bearingPickerOutlet?.value = 90
        bearingPickerOutlet?.tick = 10
        bearingPickerOutlet?.centerMarkWidth = 3
        bearingPickerOutlet?.centerMarkRadius = 3.0
        bearingPickerOutlet.centerMarkHeightRatio = 0.75
        bearingPickerOutlet?.markColor = UIColor.white
        bearingPickerOutlet.centerMarkColor = UIColor.red
        bearingPickerOutlet?.markWidth = 1.0
        //bearingPickerOutlet?.markRadius = 0.5
        bearingPickerOutlet?.markCount = 10
        bearingPickerOutlet?.padding = 16
        bearingPickerOutlet?.verticalAlign = "top"
        bearingPickerOutlet?.backgroundColor = UIColor.clear
        
        
    }
    
    private func setupHero() {
        
        let duration: TimeInterval = TimeInterval(exactly: 0.5)!
        
        logoText.hero.modifiers = [.forceNonFade, .duration(duration), .useScaleBasedSizeChange]
        
        profileOutlet.hero.modifiers = [.duration(duration), .arc(intensity: 1.0)]
        
        albumOutlet.hero.modifiers = [.forceNonFade, .duration(duration), .arc(intensity: 1.0)]
        
        previousOutlet.hero.modifiers = [.fade, .duration(duration), .arc(intensity: 1.0)]
        
        cameraButton.hero.modifiers = [.duration(duration), .arc(intensity: 1.0)]
        
    }
    
    private func setupGestures() {
        
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(self.respondToSwipeGesture))
        swipeDown.direction = .down
        self.view.addGestureRecognizer(swipeDown)
        
    }
    
    public func setupCamera(clear: Bool) {
        
        photoSetting = AVCapturePhotoSettings.init(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
        photoSetting.isAutoStillImageStabilizationEnabled = true
        photoSetting.flashMode = .off
        
        session = AVCaptureSession()
        session!.sessionPreset = AVCaptureSession.Preset.high
        
        let backCamera = AVCaptureDevice.default(for: AVMediaType.video)
        
        try! backCamera?.lockForConfiguration()
        backCamera?.focusMode = .continuousAutoFocus
        backCamera?.isSmoothAutoFocusEnabled = true
        backCamera?.whiteBalanceMode = .continuousAutoWhiteBalance
        backCamera?.unlockForConfiguration()
        
        var error: NSError?
        var input: AVCaptureDeviceInput?
        do {
            if let camera = backCamera {
                input = try AVCaptureDeviceInput(device: camera)
            }
        } catch let error1 as NSError {
            error = error1
            input = nil
            print(error!.localizedDescription)
        }
        
        if let input = input {
            if error == nil && session!.canAddInput(input) {
                
                session!.addInput(input)
                // ...
                // The remainder of the session setup will go here...
                stillImageOutput = AVCapturePhotoOutput()
                stillImageOutput?.photoSettingsForSceneMonitoring?.livePhotoVideoCodecType = .jpeg
                
                
                if session!.canAddOutput(stillImageOutput!) {
                    session!.addOutput(stillImageOutput!)
                    
                    // Configure the Live Preview here...
                    videoPreviewLayer = AVCaptureVideoPreviewLayer(session: session!)
                    videoPreviewLayer!.videoGravity = AVLayerVideoGravity.resizeAspectFill
                    
                    if UIDevice.current.orientation == .portrait {
                        videoPreviewLayer!.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
                    } else if UIDevice.current.orientation == .landscapeLeft {
                        videoPreviewLayer!.connection?.videoOrientation = AVCaptureVideoOrientation.landscapeLeft
                    } else if UIDevice.current.orientation == .landscapeRight {
                        videoPreviewLayer!.connection?.videoOrientation = AVCaptureVideoOrientation.landscapeRight
                    }
                    
                    previewView.layer.addSublayer(videoPreviewLayer!)
                    session!.startRunning()
                    
                    let when = DispatchTime.now() + 0.01 // change 2 to desired number of seconds
                    DispatchQueue.main.asyncAfter(deadline: when) {
                        self.viewDidAppear(false)
                    }
                    
                }
            }
        }
        
    }
    
    static var requests: [LocationRequest] = []
    func setupLocation() {
        
        LocationManager.shared.requireUserAuthorization(.whenInUse)
        // Azimuth
        if (CLLocationManager.headingAvailable()) {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.headingFilter = 1
            locationManager.startUpdatingHeading()
        }
        
        let request = LocationManager.shared.locateFromGPS(.continous, accuracy: .room) { (result) in
            switch result {
            case .success(let location):
                let lat = location.coordinate.latitude.truncate(places: 6)
                let long = location.coordinate.longitude.truncate(places: 6)
                //            FirebaseHandler.updateUserLocation(lat: lat, lon: long)
                DataManager.currentAppUser.latitude = lat
                DataManager.currentAppUser.longitude = long
                
                let gpsString = String.convertGPSCoordinatesToOutput(coordinates: [lat, long])
                self.locationOutlet.text = gpsString
                self.latToPass = lat
                self.longToPass = long
                self.locationToPass = gpsString
                
                self.geocode(location: location) { (state, country) in
                    FirebaseHandler.updateUserLocation(state: state, country: country)
                    FirebaseHandler.updateUserLocation(lat: lat, lon: long)
                }
                
                if self.activeChallengePicData != nil {
                    let picLong = self.activeChallengePicData.longitude
                    let picLat = self.activeChallengePicData.latitude
                    var destination: CLLocation? = CLLocation(latitude: 0, longitude: 0)
                    var angle: Double = 0
                    destination = CLLocation(latitude: picLat, longitude: picLong)
                    angle = self.getBearingBetweenTwoPoints1(point1: location, point2: destination!)
                    self.destinationAngle = angle
                    let longDiff = abs(picLong - long)
                    let latDiff = abs(picLat - lat)
                    if longDiff > self.chalCloseCoordThreshold || latDiff > self.chalCloseCoordThreshold {
                        self.locationOutlet.textColor = UIColor.white
                        self.isAtChallengeLocation = false
                    }
                    else if longDiff < self.chalBestCoordThreshold && latDiff < self.chalBestCoordThreshold {
                        self.locationOutlet.textColor = UIColor.green
                        self.isAtChallengeLocation = true
                    }
                    else if longDiff <= self.chalCloseCoordThreshold && latDiff <= self.chalCloseCoordThreshold {
                        self.locationOutlet.textColor = UIColor.yellow
                        self.isAtChallengeLocation = true
                    }
                }
                else {
                    self.locationOutlet.textColor = UIColor.white
                    self.isAtChallengeLocation = false
                }
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
        
        
        CameraContainerVC.requests.append(request)
    }
    
    enum CameraControllerError: Swift.Error {
        case captureSessionAlreadyRunning
        case captureSessionIsMissing
        case inputsAreInvalid
        case invalidOperation
        case noCamerasAvailable
        case unknown
    }
    
    func prepare(completionHandler: @escaping (Error?) -> Void) {
        func createCaptureSession() {
            session = AVCaptureSession()
        }
        func configureCaptureDevices() throws {
            let session = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera],
                                                           mediaType: AVMediaType.video,
                                                           position: .unspecified)
            
            let cameras = (session.devices.map { $0 })
            
            for camera in cameras {
                if camera.position == .back {
                    captureDevice = camera
                    try camera.lockForConfiguration()
                    camera.focusMode = .continuousAutoFocus
                    camera.unlockForConfiguration()
                }
            }
        }
        func configureDeviceInputs() throws {
            guard let captureSession = self.session else {
                throw CameraControllerError.captureSessionIsMissing
            }
            
            if let frontCamera = self.captureDevice {
                self.captureDeviceInput = try AVCaptureDeviceInput(device: frontCamera)
                
                if captureSession.canAddInput(self.captureDeviceInput!) {
                    captureSession.addInput(self.captureDeviceInput!)
                } else {
                    throw CameraControllerError.inputsAreInvalid
                }
            } else {
                throw CameraControllerError.noCamerasAvailable
            }
        }
        func configurePhotoOutput() throws {
            guard let captureSession = self.session else {
                throw CameraControllerError.captureSessionIsMissing
            }
            
            self.stillImageOutput = AVCapturePhotoOutput()
            let settings = [AVCapturePhotoSettings(format: [AVVideoCodecKey : AVVideoCodecJPEG])]
            self.stillImageOutput!.setPreparedPhotoSettingsArray(settings, completionHandler: nil)
            
            if captureSession.canAddOutput(self.stillImageOutput!) {
                captureSession.addOutput(self.stillImageOutput!)
            }
            
            captureSession.startRunning()
        }
        
        DispatchQueue(label: "prepare").async {
            do {
                createCaptureSession()
                try configureCaptureDevices()
                try configureDeviceInputs()
                try configurePhotoOutput()
            } catch {
                DispatchQueue.main.async {
                    completionHandler(error)
                }
                
                return
            }
            
            DispatchQueue.main.async {
                completionHandler(nil)
            }
        }
    }
    
    func displayPreview(on view: UIView) throws {
        guard let captureSession = self.session, captureSession.isRunning else {
            throw CameraControllerError.captureSessionIsMissing
        }
        
        self.videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        self.videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        self.videoPreviewLayer?.connection?.videoOrientation = .portrait
        
        view.layer.insertSublayer(self.videoPreviewLayer!, at: 0)
        self.videoPreviewLayer!.frame = view.frame
    }
    
    
    // MARK: - Actions
    
    @IBAction func buttonPressed(_ sender: Any) {
        print("Button Pressed")
        if cameraButton.layer.borderColor == UIColor.red.cgColor {

            FCAlertView.displayAlert(title: "Error", message: "Please make sure the camera is perpendicular to the ground.", buttonTitle: "Okay", type: "warning", view: self, blur: true)

        } else if bearingOutlet.textColor != UIColor.green
            && bearingOutlet.textColor != UIColor.white
            && bearingOutlet.textColor != UIColor.yellow
            && bearingOutlet.textColor != UIColor.orange {
            
            rcUser.getBearingForActiveChallenge { (bearing) in
                if let bearing = bearing {
                    FCAlertView.displayAlert(title: "Error",
                                             message: "Please make sure the bearing is as close to \(bearing)°." , buttonTitle: "Okay",
                                             type: "warning", view: self, blur: true)
                } else {
                    Log.e("Couln't get bearing from callback")
                }
            }
        } else {
            self.stillImageOutput?.capturePhoto(with: self.photoSetting, delegate: self)
            
            DispatchQueue.main.async {
                
                let inputs = self.session?.inputs
                for oldInput:AVCaptureInput in inputs! {
                    self.session?.removeInput(oldInput)
                }
                
                let outputs = self.session?.outputs
                for oldOutput:AVCaptureOutput in outputs! {
                    self.session?.removeOutput(oldOutput)
                }
                
                self.session?.stopRunning()
                self.locationManager.stopUpdatingHeading()
                print("Camera Session Stopping")
            }
        }
        
        
    }
    @IBAction func albumAction(_ sender: Any) {
        self.performSegue(withIdentifier: "PhotoLibSegue", sender: self.user)
    }

    @IBAction func previousHoldAction(_ sender: Any) {
        if self.previousOutlet.isEnabled {
            self.previewView.addSubview(self.previousImageView!)
            
            if self.previousImageContentMode == .scaleToFill {
                if UIDevice.current.orientation == .portrait ||
                    UIDevice.current.orientation == .faceDown ||
                    UIDevice.current.orientation == .faceUp ||
                    UIDevice.current.orientation == .portraitUpsideDown {
                        UIView.animate(withDuration: 0.25, animations: {
                            self.previousImageView?.alpha = 0.8
                            self.bearingOutlet.isHidden = true
                            self.bearingPickerOutlet.isHidden = true
                        })
                }
            } else {
                UIView.animate(withDuration: 0.25, animations: {
                    self.previousImageView?.alpha = 0.9
                    self.bearingOutlet.isHidden = true
                    self.bearingPickerOutlet.isHidden = true
                })
            }
        }
    }
    
    @IBAction func previousUpInside(_ sender: Any) {
        
        UIView.animate(withDuration: 0.25, animations: {
            self.previousImageView?.alpha = 0.0
            self.bearingOutlet.isHidden = false
            self.bearingPickerOutlet.isHidden = false
        })
        
        //self.previousImageView?.removeFromSuperview()
    }
    
    @IBAction func previousUpOutside(_ sender: Any) {
        
        UIView.animate(withDuration: 0.25, animations: {
            self.previousImageView?.alpha = 0.0
            self.bearingOutlet.isHidden = false
            self.bearingPickerOutlet.isHidden = false
        })
    }
    
    // MARK: - Class Methods
    func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
        if let heading = manager.heading {
            if heading.headingAccuracy < 0 {
                return true
            } else if heading.headingAccuracy > 5 {
                return true
            } else {
                return false
            }
        } else {
            return false
        }
    }
    
    func horizontalDialDidValueChanged(_ horizontalDial: HorizontalDial) {
        
        let value = horizontalDial.value.truncate(places: 3)
        
        let roundedValue = value.round(nearest: 1)
        
        if let user = self.rcUser {
            user.getBearingForActiveChallenge { (bearing) in
                if let bearing = bearing {
                    let distance = abs(roundedValue - bearing)
                    
                    if distance >= 30.0 {
                        self.bearingOutlet.textColor = UIColor.red
                    } else if distance >= 10 {
                        self.bearingOutlet.textColor = UIColor.orange
                    } else if distance >= 4 {
                        self.bearingOutlet.textColor = UIColor.yellow
                    } else if distance <= 3 {
                        self.bearingOutlet.textColor = UIColor.green
                    } else {
                        self.bearingOutlet.textColor = UIColor.white
                    }
                }
            }
        }
        
        if roundedValue.truncatingRemainder(dividingBy: 1) == 0 {
            if UIDevice.current.orientation == .landscapeLeft {
                if roundedValue + 90.0 > 360 {
                    bearingOutlet.text = String((roundedValue + 90.0) - 360) + "°"
                    self.bearingToPass = (roundedValue + 90.0) - 360
                } else {
                    bearingOutlet.text = String(roundedValue + 90.0) + "°"
                    self.bearingToPass = roundedValue + 90.0
                }
                
            } else if UIDevice.current.orientation == .landscapeRight {
                if roundedValue + 90.0 > 360 {
                    
                    bearingOutlet.text = String((roundedValue - 90.0) - 360) + "°"
                    self.bearingToPass = (roundedValue - 90.0) - 360
                    
                } else {
                    bearingOutlet.text = String(roundedValue - 90.0) + "°"
                    self.bearingToPass = roundedValue - 90.0
                }
            } else {
                bearingOutlet.text = String(roundedValue) + "°"
                self.bearingToPass = roundedValue
            }
        }
    }
    
    func updateHorizontalDialValue(value: Double) {
        bearingPickerOutlet.value = value
    }
    
    func geocode(location: CLLocation, completion: @escaping (_ state: String, _ country: String)->()) {
        geocoder.reverseGeocodeLocation(location) { (places, error) in
            if error != nil {
                print("ERROR geocoding:", error!.localizedDescription)
            } else {
                if let place = places?.last {
                    guard let state = place.administrativeArea else { return }
                    guard let country = place.country else { return }
                    
                    self.stopGeocode()
                    completion(state, country)
                }
            }
        }
    }
    
    private func startGeocode() {
        
    }
    
    private func stopGeocode() {
        geocoder.cancelGeocode()
    }
    
    @objc func respondToSwipeGesture(gesture: UIGestureRecognizer) {
        if let swipeGesture = gesture as? UISwipeGestureRecognizer {
            switch swipeGesture.direction {
            case .right:
                print("Swiped right")
            case .down:
                print("Swiped down")
                self.performSegue(withIdentifier: "toProfileSegue", sender: self)
            case .left:
                print("Swiped left")
            case .up:
                print("Swiped up")
            default:
                break
            }
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    func configureButton() {
        
        cameraButton.layer.borderColor = UIColor.white.cgColor
        cameraButton.layer.borderWidth = 2
        cameraButton.layer.cornerRadius = 40
        
        
        // Ensure to keep a strong reference to the motion manager otherwise you won't get updates
        motionManager = CMMotionManager()
        if motionManager.isDeviceMotionAvailable == true {
            
            motionManager.deviceMotionUpdateInterval = 0.25;
            
            let queue = OperationQueue()
            //motionManager.startDeviceMotionUpdates(to: queue, withHandler: { [weak self] (motion, error) -> Void in
            motionManager.startDeviceMotionUpdates(using: CMAttitudeReferenceFrame.xArbitraryCorrectedZVertical, to: queue) { (motion, error) in
                
                if let z = motion?.gravity.z {
                    DispatchQueue.main.async {
                        
                        if (Swift.abs(z) < 0.25) {
                            self.cameraButton.layer.borderColor = UIColor.green.cgColor
                        }
                        else {
                            self.cameraButton.layer.borderColor = UIColor.red.cgColor
                        }
                        
                    }
                }
                
            }
        }
        else {
            print("Device motion unavailable");
        }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading heading: CLHeading) {
        updateHorizontalDialValue(value: heading.magneticHeading)
        if let angle = self.destinationAngle {
            UIView.animate(withDuration: 0.25, animations: {
                self.arrowOutlet.transform = CGAffineTransform(rotationAngle: CGFloat((angle - heading.magneticHeading) * Double.pi / 180))
            })
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            let lat = location.coordinate.latitude.truncate(places: 8)
            let long = location.coordinate.longitude.truncate(places: 8)
            let newLocation = CLLocation(latitude: lat, longitude: long)
            
            if firstRun {
                self.geocode(location: newLocation) { (state, country) in
                    FirebaseHandler.updateUserLocation(state: state, country: country)
                    FirebaseHandler.updateUserLocation(lat: lat, lon: long)
                }
                firstRun = false
            }
            
            let gpsString = String.convertGPSCoordinatesToOutput(coordinates: [lat, long])
            self.locationOutlet.text = gpsString
            self.latToPass = lat
            self.longToPass = long
            self.locationToPass = gpsString
            
            if self.activeChallengePicData != nil {
                let picLong = self.activeChallengePicData.longitude
                let picLat = self.activeChallengePicData.latitude
                var destination: CLLocation? = CLLocation(latitude: 0, longitude: 0)
                var angle: Double = 0
                destination = CLLocation(latitude: picLat, longitude: picLong)
                angle = self.getBearingBetweenTwoPoints1(point1: location, point2: destination!)
                self.destinationAngle = angle
                let longDiff = abs(picLong - long)
                let latDiff = abs(picLat - lat)
                if longDiff > self.chalCloseCoordThreshold || latDiff > self.chalCloseCoordThreshold {
                    self.locationOutlet.textColor = UIColor.white
                    self.isAtChallengeLocation = false
                }
                else if longDiff < self.chalBestCoordThreshold && latDiff < self.chalBestCoordThreshold {
                    self.locationOutlet.textColor = UIColor.green
                    self.isAtChallengeLocation = true
                }
                else if longDiff <= self.chalCloseCoordThreshold && latDiff <= self.chalCloseCoordThreshold {
                    self.locationOutlet.textColor = UIColor.yellow
                    self.isAtChallengeLocation = true
                }
            }
            else {
                self.locationOutlet.textColor = UIColor.white
                self.isAtChallengeLocation = false
            }
            
            locationManager.stopUpdatingLocation()
        }
    }
    
    func setupOrientation() {
        
        NotificationCenter.default.addObserver(forName: UIDevice.orientationDidChangeNotification, object: nil, queue: .main) { (notification) in
            switch UIDevice.current.orientation {
            case .portrait:
                self.videoPreviewLayer!.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
            case .landscapeRight:
                self.videoPreviewLayer!.connection?.videoOrientation = AVCaptureVideoOrientation.landscapeLeft
            case .landscapeLeft:
                self.videoPreviewLayer!.connection?.videoOrientation = AVCaptureVideoOrientation.landscapeRight
            default:
                Log.e("Irrelevant")
            }
        }

        videoPreviewLayer!.frame = previewView.bounds
        
    }
    
    @available(iOS 11.0, *)
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if error == nil {
            
            guard let imageData = photo.fileDataRepresentation() else { return }
            guard let img = UIImage(data: imageData) else { return }
            guard let rep = img.jpegData(compressionQuality: 1.0) else { return }
            
            
            var orientation: UIImage.Orientation?
            
            switch UIDevice.current.orientation {
            case .portrait:
                orientation = .right
            case .landscapeLeft:
                orientation = .up
            case .landscapeRight:
                orientation = .down
            case .portraitUpsideDown:
                orientation = .left
            case .faceDown:
                orientation = .down
            case .faceUp:
                orientation = .up
            case .unknown:
                orientation = .right
            }
            
            guard let newImage = UIImage(data: rep) else { return }
            
            let orientedImage = UIImage(cgImage: newImage.cgImage!, scale: newImage.scale, orientation: orientation!)
            
            self.imageToPass = orientedImage
            
            self.performSegue(withIdentifier: "confirmPictureSegue", sender: orientation)
        }
        
        
        
    }
    
    //MARK: - Navigation Arrow Functionality
    func degreesToRadians(degrees: Double) -> Double { return degrees * .pi / 180.0 }
    func radiansToDegrees(radians: Double) -> Double { return radians * 180.0 / .pi }
    
    func getBearingBetweenTwoPoints1(point1 : CLLocation, point2 : CLLocation) -> Double {
        
        let lat1 = degreesToRadians(degrees: point1.coordinate.latitude)
        let lon1 = degreesToRadians(degrees: point1.coordinate.longitude)
        
        let lat2 = degreesToRadians(degrees: point2.coordinate.latitude)
        let lon2 = degreesToRadians(degrees: point2.coordinate.longitude)
        
        let dLon = lon2 - lon1
        
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let radiansBearing = atan2(y, x)
        
        return radiansToDegrees(radians: radiansBearing)
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        let segueID = segue.identifier
        
        if segueID == "confirmPictureSegue" {
            guard let orientation = sender as? UIImage.Orientation else { return }
            let vc = segue.destination as! ImageConfirmVC
            vc.isAtChallengeLocation = self.isAtChallengeLocation
            vc.image = self.imageToPass
            vc.latToPass = self.latToPass
            vc.longToPass = self.longToPass
            vc.bearingToPass = self.bearingToPass
            vc.locationToPass = self.locationToPass
            vc.userData = AppManager.user
            vc.orientation = orientation
            AppManager.user.getActiveChallenge { (picture) in
                if picture != nil {
                    vc.previousPic = picture!
                }
            }
        } else if segueID == "toProfileSegue" {
            let vc = segue.destination as! ProfileMenuVC
            vc.image = self.profileImage
        } else if segueID == "PhotoLibSegue" {
            let destination = segue.destination as! UINavigationController
            let photoLibVC = destination.topViewController as! PhotoLibChallengeVC
            photoLibVC.mode = PhotoLibChallengeVC.PHOTO_LIB_MODE
        }
        
    }
}
