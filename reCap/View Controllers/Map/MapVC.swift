//
//  MapVC.swift
//  reCap
//
//  Created by Jackson Delametter on 2/4/18.
//  Copyright © 2018 Kaleb Cooper. All rights reserved.
//

import UIKit
import Mapbox
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections
import Firebase
import RealmSwift

class MapVC: UIViewController, MGLMapViewDelegate, RCPictureChallengeDelegate {
    
    private static let TAKE_PIC_FROM_RECENT = "Recent Photos (+1 point)"
    private static let TAKE_PIC_FROM_WEEK = "Photos over a week ago (+5 points)"
    private static let TAKE_PIC_FROM_MONTH = "Photos over a month ago (+15 points)"
    private static let TAKE_PIC_FROM_YEAR = "Photos from over a year ago (+50 points)"
    private static let CHALLENGE_RECENT_POINTS = 1
    private static let CHALLENGE_WEEK_POINTS = 5
    private static let CHALLENGE_MONTH_POINTS = 10
    private static let CHALLENGE_YEAR_POINTS = 20
    static let SECONDS_IN_WEEK = 604800
    static let SECONDS_IN_MONTH = PhotoLibChallengeVC.SECONDS_IN_WEEK * 4
    static let SECONDS_IN_YEAR = PhotoLibChallengeVC.SECONDS_IN_MONTH * 12
    
    // MARK: - Properties
    private var locations: [String]!
    private var locationDictionary: [String : [RCPicture]]!
    
//    var user: User!
    var user: RCUser!
    let ref = Database.database().reference()
    var mapView: NavigationMapView!
    var progressView: UIProgressView!
    var pins: [MGLPointAnnotation] = []
    var pictureDataArray: [RCPicture] = []
    var userPictureDataArray: [RCPicture] = []
    var activeChallengePicData: RCPicture?
    
    var pictureIDArray: [String]! = []
    var pictureArray: [UIImage]! = []
    
    var directionsRoute: Route?
    var mapViewNavigation: NavigationMapView!
    
    var imageToPass: UIImage?
    var pictureDataToPass: RCPicture?
    
    let darkColor = UIColor(red: 48/255, green: 48/255, blue: 48/255, alpha: 1.0)

    var viewModel: MapViewModel!
    
    var token: NotificationToken?
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.user = DataManager.currentAppUser
        
        // 1. Check for cached data OR Get all data and cache it
        
        RealmHelper.getCachedPhotoData(token: { (token) in
            self.token = token
        }, updates: { (added, deleted) in
            if added != nil {
                self.photos.append(contentsOf: added!)
            }
        }) { (error, cachedData) in
            if error != nil {
                Log.e(error!.localizedDescription)
                // No cached Data
                FirebaseHandler.getAllPictureData(onlyRecent: true, completion: { (pictureData) in
                    for picture in pictureData {
                        picture.convertToRealm()
                    }
                    
                    self.completeSetup(data: pictureData)
                })
            } else {
                if let data = cachedData {
                    self.completeSetup(data: data)
                }
            }
        }
        
        // Setup offline pack notification handlers.
        NotificationCenter.default.addObserver(self, selector: #selector(offlinePackProgressDidChange), name: NSNotification.Name.MGLOfflinePackProgressChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(offlinePackDidReceiveError), name: NSNotification.Name.MGLOfflinePackError, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(offlinePackDidReceiveMaximumAllowedMapboxTiles), name: NSNotification.Name.MGLOfflinePackMaximumMapboxTilesReached, object: nil)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        
        
        user.getActiveChallenge(updated: hasUpdatedchallenge) { (challenge) in
            if let challenge = challenge {
                self.centerButton.isHidden = false
            } else {
                self.centerButton.isHidden = true
            }
            
            if self.hasUpdatedchallenge {
                self.hasUpdatedchallenge = false
            }
        }
    }
    
    deinit {
        // Remove offline pack observers.
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup
    
    var photos: [RCPicture] = [] {
        didSet {
            completeSetup(data: photos)
        }
    }
    
    /// Finshes the setup of the map page, given data has been downloaded and parsed
    ///
    /// - Parameter data: A list of RCPicture objects
    func completeSetup(data: [RCPicture]) {
        if self.pins.count > 0 {
            self.mapView.removeAnnotations(self.pins)
            self.pins.removeAll()
        }
        
        // 2. Set MapView DataSource
        if data.count > 0 {
            for picture in data {
                
                let pin = MGLPointAnnotation()
                pin.coordinate = CLLocationCoordinate2D(latitude: (picture.latitude), longitude: (picture.longitude))
                pin.title = picture.name
                pin.subtitle = picture.locationName
                
                self.pictureIDArray.append(picture.id)
                self.pictureDataArray.append(picture)
                
                self.pins.append(pin)
            }
            
            // 3. Check if user has active challenge - Update as needed
            user.getActiveChallenge { (picture) in
                if let challenge = picture {
                    self.activeChallengePicData = challenge
                    self.setupMap()
                    let when = DispatchTime.now() + 0.5 // change 2 to desired number of seconds
                    DispatchQueue.main.asyncAfter(deadline: when) {
                        self.setupCamera()
                    }
                } else {
                    self.setupMap()
                    let when = DispatchTime.now() + 0.5 // change 2 to desired number of seconds
                    DispatchQueue.main.asyncAfter(deadline: when) {
                        self.setupCamera()
                    }
                }
            }
        }
    }
    
    func setupCamera() {
        
        let user = self.mapView.userLocation?.coordinate
        self.mapView.setCenter(user!, zoomLevel: 2, direction: 0, animated: true)
//        let camera = MGLMapCamera(lookingAtCenter: user!, fromDistance: 500, pitch: 0, heading: 0)
        let camera = MGLMapCamera(lookingAtCenter: user!, altitude: 500, pitch: 30, heading: 0)
        let when = DispatchTime.now() + 0.5 // change 2 to desired number of seconds
        DispatchQueue.main.asyncAfter(deadline: when) {
            // Animate the camera movement over 5 seconds.
            self.mapView.setCamera(camera, withDuration: 2,
                                   animationTimingFunction: CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut))
            
        }
    }
    
    func setupMap() {
        
        mapView = NavigationMapView(frame: view.bounds)
        mapView.delegate = self
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.showsUserLocation = true
        mapView.compassView.isHidden = true
        
        self.viewModel = MapViewModel(map: mapView,
                                      userLocation: CLLocation(latitude: CLLocationDegrees(exactly: user.latitude)!,
                                                               longitude: CLLocationDegrees(exactly: user.longitude)!))
        
        if Bool.checkIfTimeIs(between: 0, and: 7) == true || Bool.checkIfTimeIs(between: 18, and: 23) == true {
            mapView.styleURL = MGLStyle.darkStyleURL(withVersion: 9)
            styleControl.selectedSegmentIndex = 1
            styleControl.tintColor = UIColor.white
            mapView.attributionButton.tintColor = UIColor.white
        } else {
            mapView.styleURL = MGLStyle.outdoorsStyleURL(withVersion: 10)
            styleControl.selectedSegmentIndex = 0
            styleControl.tintColor = darkColor
            mapView.attributionButton.tintColor = darkColor
        }
        
        view.addSubview(mapView)
        view.bringSubviewToFront(styleControl)
        view.bringSubviewToFront(centerButton)
        
        setupPictures()
        self.setupPins()
    }
    
    func setupPictures() {
        
        locations = []
        locationDictionary = [:]
        
//        if self.pins.count > 0 {
//            self.mapView.removeAnnotations(self.pins)
//            self.pins.removeAll()
//        }
//        
//        FirebaseHandler.getAllPictureData(onlyRecent: true) { (pictures) in
//            if pictures.count > 0 {
//                for picture in pictures {
//
//                    let pin = MGLPointAnnotation()
//                    pin.coordinate = CLLocationCoordinate2D(latitude: (picture.latitude), longitude: (picture.longitude))
//                    pin.title = picture.name
//                    pin.subtitle = picture.locationName
//
//                    self.pictureIDArray.append(picture.id)
//                    self.pictureDataArray.append(picture)
//
//                    self.pins.append(pin)
//                }
//
//                self.setupPins()
//            }
//        }
        
        
    }
    
    func setupPins() {
        self.mapView.addAnnotations(self.pins)
    }
    
    // MARK: - Actions and Delegates
    
    @IBOutlet weak var styleControl: UISegmentedControl!
    @IBOutlet weak var centerButton: UIButton!
    @IBAction func styleControlAction(_ sender: Any) {
        
        if styleControl.selectedSegmentIndex == 0 {
            mapView.styleURL = MGLStyle.outdoorsStyleURL(withVersion: 10)
            
            styleControl.tintColor = darkColor
            mapView.attributionButton.tintColor = darkColor
        }
        else {
            mapView.styleURL = MGLStyle.darkStyleURL(withVersion: 9)
            styleControl.tintColor = UIColor.white
            mapView.attributionButton.tintColor = UIColor.white
        }
        
    }
    
    @IBAction func centerAction(_ sender: Any) {
        if let user = self.user {
            user.getActiveChallenge { (challenge) in
                if let challenge = challenge {
                    let lat = challenge.latitude
                    let long = challenge.longitude
                    
                    print(lat, long)
                    
                    let coordinate = CLLocationCoordinate2DMake(lat, long)
                    self.mapView.setCenter(coordinate, zoomLevel: self.mapView.zoomLevel, direction: 0, animated: true)
                }
            }
        }
    }
    
    // MARK: - Challenge Delegate
    var hasUpdatedchallenge = false
    func userDidAddNewChallenge(picture: RCPicture) {
        Log.d("User did add new challenge")
        self.activeChallengePicData = picture
        hasUpdatedchallenge = true
    }
    
    func userDidRemoveChallenge(picture: RCPicture) {
        Log.d("User did remove challenge")
        self.activeChallengePicData = nil
    }
    
    // MARK: - MGLOfflinePack notification handlers
    func mapViewDidFinishLoadingMap(_ mapView: MGLMapView) {
        // Start downloading tiles and resources for z13-16.
        //startOfflinePackDownload()
        mapView.showsUserLocation = true
    }
    
    func startOfflinePackDownload() {
        // Create a region that includes the current viewport and any tiles needed to view it when zoomed further in.
        // Because tile count grows exponentially with the maximum zoom level, you should be conservative with your `toZoomLevel` setting.
        let region = MGLTilePyramidOfflineRegion(styleURL: mapView.styleURL, bounds: mapView.visibleCoordinateBounds, fromZoomLevel: 0, toZoomLevel: 5)
        
        // Store some data for identification purposes alongside the downloaded resources.
        let userInfo = ["name": "My Offline Pack"]
        let context = NSKeyedArchiver.archivedData(withRootObject: userInfo)
        
        // Create and register an offline pack with the shared offline storage object.
        
        MGLOfflineStorage.shared.addPack(for: region, withContext: context) { (pack, error) in
            guard error == nil else {
                // The pack couldn’t be created for some reason.
                print("Error: \(error?.localizedDescription ?? "unknown error")")
                return
            }
            
            // Start downloading.
            pack!.resume()
        }
        
    }
    
    @objc func offlinePackProgressDidChange(notification: NSNotification) {
        // Get the offline pack this notification is regarding,
        // and the associated user info for the pack; in this case, `name = My Offline Pack`
        if let pack = notification.object as? MGLOfflinePack,
            let userInfo = NSKeyedUnarchiver.unarchiveObject(with: pack.context) as? [String: String] {
            let progress = pack.progress
            // or notification.userInfo![MGLOfflinePackProgressUserInfoKey]!.MGLOfflinePackProgressValue
            let completedResources = progress.countOfResourcesCompleted
            let expectedResources = progress.countOfResourcesExpected
            
            // Calculate current progress percentage.
            let progressPercentage = Float(completedResources) / Float(expectedResources)
            
            // Setup the progress bar.
            if progressView == nil {
                progressView = UIProgressView(progressViewStyle: .default)
                let frame = view.bounds.size
                progressView.frame = CGRect(x: frame.width / 4, y: frame.height * 0.9, width: frame.width / 2, height: 10)
                view.addSubview(progressView)
            }
            
            progressView.progress = progressPercentage
            
            // If this pack has finished, print its size and resource count.
            if completedResources == expectedResources {
                let byteCount = ByteCountFormatter.string(fromByteCount: Int64(pack.progress.countOfBytesCompleted), countStyle: ByteCountFormatter.CountStyle.memory)
                print("Offline pack “\(userInfo["name"] ?? "unknown")” completed: \(byteCount), \(completedResources) resources")
                progressView.isHidden = true
            } else {
                // Otherwise, print download/verification progress.
                print("Offline pack “\(userInfo["name"] ?? "unknown")” has \(completedResources) of \(expectedResources) resources — \(progressPercentage * 100)%.")
                progressView.isHidden = false
            }
        }
    }
    
    @objc func offlinePackDidReceiveError(notification: NSNotification) {
        if let pack = notification.object as? MGLOfflinePack,
            let userInfo = NSKeyedUnarchiver.unarchiveObject(with: pack.context) as? [String: String],
            let error = notification.userInfo?[MGLOfflinePackUserInfoKey.error] as? NSError {
            print("Offline pack “\(userInfo["name"] ?? "unknown")” received error: \(error.localizedFailureReason ?? "unknown error")")
        }
    }
    
    @objc func offlinePackDidReceiveMaximumAllowedMapboxTiles(notification: NSNotification) {
        if let pack = notification.object as? MGLOfflinePack,
            let userInfo = NSKeyedUnarchiver.unarchiveObject(with: pack.context) as? [String: String],
            let maximumCount = (notification.userInfo?[MGLOfflinePackUserInfoKey.maximumCount] as AnyObject).uint64Value {
            print("Offline pack “\(userInfo["name"] ?? "unknown")” reached limit of \(maximumCount) tiles.")
        }
    }
    
    let greenColor = UIColor(red: 99/255, green: 207/255, blue: 155/255, alpha: 1.0)
    let redColor = UIColor(red: 204/255, green: 51/255, blue: 51/255, alpha: 1.0)
    
    // Use the default marker. See also: our view annotation or custom marker examples.
    func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
        
        // Assign a reuse identifier to be used by both of the annotation views, taking advantage of their similarities.
//        let reuseIdentifier = "\(annotation.coordinate.longitude)"
        let reuseIdentifier = "reuse"
        
        // For better performance, always try to reuse existing annotations.
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier)
        
        // If there’s no reusable annotation view available, initialize a new one.
        if annotationView == nil {
            
            if annotation is MGLUserLocation && mapView.userLocation != nil {
                return CustomUserLocationAnnotationView()
            }
            
            let lat = annotation.coordinate.latitude
            let long = annotation.coordinate.longitude
            
            annotationView = CustomAnnotationView(reuseIdentifier: reuseIdentifier)
            annotationView!.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
            
            if self.activeChallengePicData?.latitude == lat && self.activeChallengePicData?.longitude == long {
                annotationView!.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
                annotationView!.backgroundColor = redColor
            } else {
                annotationView!.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
                annotationView!.backgroundColor = greenColor
            }
            return annotationView
        }
        
        return annotationView
    }
    
    /// Checks to see if the latitude and longitude supplied are the coordinates of the active challenge for the current user
    ///
    /// - Important: This method is depreciated and should not be implimented. Doing so will produce uncertain results
    ///
    /// - Parameters:
    ///   - av: Annotation View
    ///   - lat: Latitude of picture to check
    ///   - long: Longitude of picture to check
    ///   - completion: the completion handler to fire when complete
    func checkForMapAnnotation(av: MGLAnnotationView, lat: Double, long: Double, completion: @escaping (MGLAnnotationView?)->(MGLAnnotationView?)){
        FirebaseHandler.getPictureData(lat: lat, long: long, onlyRecent: true) { (picture) in
            if let user = self.user {
                user.getActiveChallenge(completion: { (challenge) in
                    if let picture = picture {
                        if let challenge = challenge {
                            if picture.id == challenge.id {
                                av.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
                                av.backgroundColor = self.redColor
                                completion(av)
                            }
                        }
                    }
                })
            }
        }
    }
    
    
    // Allow callout view to appear when an annotation is tapped.
    func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
        return true
    }
    
    func mapView(_ mapView: MGLMapView, leftCalloutAccessoryViewFor annotation: MGLAnnotation) -> UIView? {
        
        let lat = annotation.coordinate.latitude
        let long = annotation.coordinate.longitude
        Log.d("Starting data grab for callout")
        if let photo = RealmHelper.getPhotoFor(lat: lat, lon: long) {
            if let imageData = photo.image {
                if let image = imageData.convertToUIImage() {
                    let orientation = UIImage.Orientation(rawValue: photo.orientation)!
                    
                    guard image.cgImage != nil else { return nil }
                    let img = UIImage(cgImage: image.cgImage!, scale: image.scale, orientation: orientation)
                    
                    let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
                    imageView.contentMode = .scaleAspectFit
                    imageView.image = img
                    
                    return imageView
                } else {
                    Log.e("Could not convert data to image")
                    return nil
                }
            } else {
                Log.d("No data for image exists. Should fetch image data")
                return nil
            }
        } else {
            return nil
        }
    }
    
    func getImage(lat: Double, long: Double, completion: @escaping (UIImageView?)->(UIView?)) {
        FirebaseHandler.getPictureData(lat: lat, long: long, onlyRecent: true) { (picture) in
            let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 60, height: 100))
            if let picture = picture {
                FirebaseHandler.downloadPicture(pictureData: picture, completion: { (image) in
                    if let realImage = image {
                        imageView.image = realImage
                        imageView.contentMode = .scaleAspectFit
                        self.pictureDataToPass = picture
                        self.imageToPass = realImage
                        imageView.hero.id = "imageID"
                        
                        completion(imageView)
                    }
                })
            }
        }
    }
    
    
    func mapView(_ mapView: MGLMapView, rightCalloutAccessoryViewFor annotation: MGLAnnotation) -> UIView? {
        
        if annotation is MGLUserLocation && mapView.userLocation != nil {
            return nil
        } else {
            return UIButton(type: .detailDisclosure)
        }
 
    }
    
    func mapView(_ mapView: MGLMapView, annotation: MGLAnnotation, calloutAccessoryControlTapped control: UIControl) {
        // Hide the callout view.
        //mapView.deselectAnnotation(annotation, animated: true)
        
        self.calculateRoute(from: (mapView.userLocation!.coordinate), to: annotation.coordinate) { (route, error) in
            if error != nil {
                print("Error calculating route")
            }
        }
        
        // Ask user if they want to navigate to the pin.
        let alert = UIAlertController(title: "What would you like to do?", message: nil , preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Navigate Here", style: .default, handler: { (action) in
            // Calculate the route from the user's location to the set destination
            self.beginNavigation()
        }))
        
        var title = ""
        if self.activeChallengePicData?.latitude == annotation.coordinate.latitude &&
            self.activeChallengePicData?.longitude == annotation.coordinate.longitude {
            title = "Remove Active Challenge"
            alert.addAction(UIAlertAction(title: title, style: .default, handler: { (action) in
                
                self.user.update(values: [.activeChallenge: "",
                                          .activeChallengePoints: 0])
                
                self.user.getActiveChallenge(updated: true) { (challenge) in
                    if let challenge = challenge {
                        self.centerButton.isHidden = false
                    } else {
                        self.centerButton.isHidden = true
                    }
                    
                    self.setupCamera()
                    self.setupPictures()
                    
                    if self.hasUpdatedchallenge {
                        self.hasUpdatedchallenge = false
                    }
                }
            }))
        } else {
            title = "Set as Active Challenge"
            alert.addAction(UIAlertAction(title: title, style: .default, handler: { (action) in
                
                let lat = annotation.coordinate.latitude
                let long = annotation.coordinate.longitude
                
                FirebaseHandler.getPictureData(lat: lat, long: long, onlyRecent: true, compltion: { (picture) in
                    if let pic = picture {
                        self.addChallengeToUser(pictureData: pic)
                        self.setupPictures()
                        self.centerButton.isHidden = false
                    }
                })
                
            }))
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func mapView(_ mapView: MGLMapView, tapOnCalloutFor annotation: MGLAnnotation) {
        print("Tapped on image")
        
        let photo = RealmHelper.getPhotoFor(lat: annotation.coordinate.latitude, lon: annotation.coordinate.longitude)
        guard photo != nil else {
            Log.s("Photo did not exists for coords")
            return
        }
        
        self.performSegue(withIdentifier: "ChallengeViewSegue", sender: photo)
    }
    
    func calculateRoute(from origin: CLLocationCoordinate2D,
                        to destination: CLLocationCoordinate2D,
                        completion: @escaping (Route?, Error?) -> ()) {
        
        // Coordinate accuracy is the maximum distance away from the waypoint that the route may still be considered viable, measured in meters. Negative values indicate that a indefinite number of meters away from the route and still be considered viable.
        let origin = Waypoint(coordinate: origin, coordinateAccuracy: -1, name: "Start")
        let destination = Waypoint(coordinate: destination, coordinateAccuracy: -1, name: "Finish")
        
        // Specify that the route is intended for automobiles avoiding traffic
        let options = NavigationRouteOptions(waypoints: [origin, destination], profileIdentifier: .automobileAvoidingTraffic)
        
        // Generate the route object and draw it on the map
        _ = Directions.shared.calculate(options) { [unowned self] (waypoints, routes, error) in
            self.directionsRoute = routes?.first
            // Draw the route on the map after creating it
            self.drawRoute(route: self.directionsRoute!)
        }
    }
    
    func drawRoute(route: Route) {
        guard route.coordinateCount > 0 else { return }
        // Convert the route’s coordinates into a polyline
        var routeCoordinates = route.coordinates!
        let polyline = MGLPolylineFeature(coordinates: &routeCoordinates, count: route.coordinateCount)
        
        // If there's already a route line on the map, reset its shape to the new route
        if let source = mapView.style?.source(withIdentifier: "route-source") as? MGLShapeSource {
            source.shape = polyline
        } else {
            let source = MGLShapeSource(identifier: "route-source", features: [polyline], options: nil)
            
            // Customize the route line color and width
            let lineStyle = MGLLineStyleLayer(identifier: "route-style", source: source)
            lineStyle.lineColor = NSExpression(forConstantValue: #colorLiteral(red: 0.1897518039, green: 0.3010634184, blue: 0.7994888425, alpha: 1))
            lineStyle.lineWidth = NSExpression(forConstantValue: 3)
            
            // Add the source and style layer of the route line to the map
            mapView.style?.addSource(source)
            mapView.style?.addLayer(lineStyle)
        }
    }
    
    func beginNavigation() {
        print("Presenting Navigation View")
        let navigationViewController = NavigationViewController(for: self.directionsRoute!)
        
        self.present(navigationViewController, animated: true, completion: nil)
    }
    
    
    // Find where data source is set
    
    private func getPicChallengeCategory(pictureData: RCPicture, currentDate: Date) -> String {
        //let pictureDate = DateGetter.getDateFromString(string: pictureData.time)
        let dateDiffSec = Int(abs(TimeInterval(pictureData.time) - currentDate.timeIntervalSince1970))
        //let dateDiffSec = Int(abs(pictureDate.timeIntervalSince(currentDate)))
        if dateDiffSec >= MapVC.SECONDS_IN_YEAR {
            return MapVC.TAKE_PIC_FROM_YEAR
        }
        else if dateDiffSec >= MapVC.SECONDS_IN_MONTH {
            return MapVC.TAKE_PIC_FROM_MONTH
        }
        else if dateDiffSec >= MapVC.SECONDS_IN_WEEK {
            return MapVC.TAKE_PIC_FROM_WEEK
        }
        else {
            return MapVC.TAKE_PIC_FROM_RECENT
        }
    }
    
    private func addChallengeToUser(pictureData: RCPicture) {
        let challengeCategory = getPicChallengeCategory(pictureData: pictureData, currentDate: Date())
        var points = 0
        if challengeCategory == MapVC.TAKE_PIC_FROM_WEEK {
            points = MapVC.CHALLENGE_WEEK_POINTS
        }
        else if challengeCategory == MapVC.TAKE_PIC_FROM_MONTH {
            points = MapVC.CHALLENGE_MONTH_POINTS
        }
        else if challengeCategory == MapVC.TAKE_PIC_FROM_YEAR {
            points = MapVC.CHALLENGE_YEAR_POINTS
        }
        else if challengeCategory == MapVC.TAKE_PIC_FROM_RECENT {
            points = MapVC.CHALLENGE_RECENT_POINTS
        }
        
        self.user.update(values: [.activeChallenge: pictureData.id,
                                  .activeChallengePoints: points])

        let lat = pictureData.latitude
        let long = pictureData.longitude
        let coordinate = CLLocationCoordinate2DMake(lat, long)
        self.mapView.setCenter(coordinate, zoomLevel: self.mapView.zoomLevel, direction: 0, animated: true)
    }
    

    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        let segueID = segue.identifier
        if segueID == "ChallengeViewSegue" {
            let nav = segue.destination as! UINavigationController
            let destination = nav.topViewController as! PhotoTimelineVC
            
            if let photo = sender as? RCPicture {
                destination.pictureData = photo

                guard let image = photo.image?.convertToUIImage() else { return }
                guard let cg = image.cgImage else { return }
                guard let orientation = UIImage.Orientation(rawValue: photo.orientation) else { return }
                let img = UIImage(cgImage: cg, scale: image.scale, orientation: orientation)
                
                destination.image = img
            } else {
                Log.s("Could not get photo from segue sender")
            }
            
//            //let destination = segue.destination as! ChallengeViewVC
//            if let pictureData = pictureDataToPass {
//                let picture = imageToPass
//                destination.pictureData = pictureData
//                destination.image = picture
//                print("Segue Done")
//            }
        }
    }
    
}


// MGLAnnotationView subclass
class CustomAnnotationView: MGLUserLocationAnnotationView {
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Force the annotation view to maintain a constant size when the map is tilted.
        scalesWithViewingDistance = false
        
        // Use CALayer’s corner radius to turn this view into a circle.
        layer.cornerRadius = frame.width / 2
        layer.borderWidth = 2
        layer.borderColor = UIColor.white.cgColor
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Animate the border width in/out, creating an iris effect.
        let animation = CABasicAnimation(keyPath: "borderWidth")
        animation.duration = 0.1
        layer.borderWidth = selected ? frame.width / 4 : 2
        layer.add(animation, forKey: "borderWidth")
    }
}
