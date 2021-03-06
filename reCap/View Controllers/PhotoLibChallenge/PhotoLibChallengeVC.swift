//
//  PhotoLibChallengeVC.swift
//  reCap
//
//  Created by Jackson Delametter on 2/6/18.
//  Copyright © 2018 Kaleb Cooper. All rights reserved.
//

import UIKit
import Firebase
import FCAlertView

import SwiftLocation
import CoreLocation

class PhotoLibChallengeVC: UITableViewController, UICollectionViewDelegate, UICollectionViewDataSource, CLLocationManagerDelegate, ImageButtonDelegate {
    
    // MARK: - Outlets
    
    // MARK: - Properties
    private var tableSectionArray: [String]!
    private var collectionDictionaryData: [String : [RCPicture]]!
    private var photoLibChalReference: DatabaseReference!
    var user: User!
    var userData: ChallengeSetup!
    var mode: Int!
    
    var userLat: Double!
    var userLong: Double!
    let locationManager = CLLocationManager()
    
    // MARK: - Constants
    private static let PHOTO_SEGUE = "PhotoSegue"
    private static let VIEW_CHALLENGE_SEGUE = "ViewChallengeSegue"
    private static let PHOTO_SEGUE_PICTURE_DATA_INDEX = 0
    private static let PHOTO_SEGUE_PICTURE_INDEX = 1
    private static let TAKE_PIC_FROM_RECENT = "Recent Photos (+1 point)"
    private static let TAKE_PIC_FROM_WEEK = "Photos over a week ago (+5 points)"
    private static let TAKE_PIC_FROM_MONTH = "Photos over a month ago (+15 points)"
    private static let TAKE_PIC_FROM_YEAR = "Photos from over a year ago (+50 points)"
    private static let CHALLENGE_RECENT_POINTS = 1
    private static let CHALLENGE_WEEK_POINTS = 5
    private static let CHALLENGE_MONTH_POINTS = 10
    private static let CHALLENGE_YEAR_POINTS = 20
    private var dispatchGroup: DispatchGroup!
    static let PHOTO_LIB_MODE = 0
    static let CHALLENGE_MODE = 1
    static let SECONDS_IN_WEEK = 604800
    static let SECONDS_IN_MONTH = PhotoLibChallengeVC.SECONDS_IN_WEEK * 4
    static let SECONDS_IN_YEAR = PhotoLibChallengeVC.SECONDS_IN_MONTH * 12
    private static let MILE_THRESH = 10.0
    
    var challengeDelegate: RCPictureChallengeDelegate?
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if self.userData == nil {
            self.userData = DataManager.currentAppUser
        }
        
        if mode == 1 {
            self.userData = DataManager.currentAppUser
        }
    
        applyBlurEffect(image: #imageLiteral(resourceName: "Gradient"))
        setup()
        
//        #error("Need to set delegate here")
        
    }
    
    private func setup() {
        setupSpinner()
        tableSectionArray = []
        collectionDictionaryData = [:]
        if self.mode == PhotoLibChallengeVC.PHOTO_LIB_MODE {
            self.setupPhotoLib()
        } else if mode == PhotoLibChallengeVC.CHALLENGE_MODE  {
            self.setupChallenge()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Outlet Action Methods
    
    
    @IBAction func backPressed(_ sender: Any) {
        print("Back Pressed")
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Setup Methods

    
    private func setupPhotoLib() {
        let username = self.userData.name
        self.title = "\(username)'s Photos"
        self.tableView.allowsSelection = false
        var groupIDArray: [String] = []
        // Get all user pictures and sort them by time, the most recent will be at the start
        
        FirebaseHandler.database.child("PictureData").queryOrdered(byChild: "owner").queryEqual(toValue: userData.id).observeSingleEvent(of: .value) { (snap) in
            if let objects = snap.children.allObjects as? [DataSnapshot] {
                var pictures: [RCPicture] = []
                for object in objects {
                    let picture = RCPicture(snapshot: object)
                    let location = picture.locationName
                    if !self.tableSectionArray.contains(location) {
                        // Location is not in the locations array
                        // Add it to the array and initialize
                        // an empty array for the key location
                        self.tableSectionArray.append(location)
                        self.collectionDictionaryData[location] = []
                    }
                    if !groupIDArray.contains(picture.groupID) {
                        // If the picture in a group has not yet been added
                        groupIDArray.append(picture.groupID)
                        self.collectionDictionaryData[location]?.append(picture)
                    }
                }
                self.tableView.reloadData()
            }
        }
    }
    
    private func getFiftyChallenges(results: [RCPicture]) -> [RCPicture] {
        var count = 0
        let max = 50
        var pictureArray: [RCPicture] = []
        for pictureData in results {
            if count < max {
                pictureArray.append(pictureData)
                count = count + 1
            }
            else {
                break
            }
        }
        return pictureArray
    }
    
    private func setupChallenge() {
        self.title = "Challenges"
        self.dispatchGroup = DispatchGroup()
        self.collectionDictionaryData = [PhotoLibChallengeVC.TAKE_PIC_FROM_RECENT : [], PhotoLibChallengeVC.TAKE_PIC_FROM_WEEK : [], PhotoLibChallengeVC.TAKE_PIC_FROM_MONTH : [], PhotoLibChallengeVC.TAKE_PIC_FROM_YEAR : []]
        self.tableView.allowsSelection = false
        print("Part 2")
        let lat = self.userData.latitude
        let long = self.userData.longitude
        let degreeThresh = ((1/69)*PhotoLibChallengeVC.MILE_THRESH) / 2
        let latHigh = lat + degreeThresh
        let latLow = lat - degreeThresh
        let longHigh = long + degreeThresh
        let longLow = long - degreeThresh
        let currentTime = Int(Date().timeIntervalSince1970)
        let weekTime = currentTime - PhotoLibChallengeVC.SECONDS_IN_WEEK
        let monthTime = currentTime - PhotoLibChallengeVC.SECONDS_IN_MONTH
        let yearTime = currentTime - PhotoLibChallengeVC.SECONDS_IN_YEAR

        spinner?.startAnimating()
        
        let picturesRef = FirebaseHandler.database.child("PictureData")
        picturesRef.queryOrdered(byChild: "latitude").queryStarting(atValue: latLow).queryEnding(atValue: latHigh).observeSingleEvent(of: .value) { (snap) in
            if let objects = snap.children.allObjects as? [DataSnapshot] {
                var recentResults: [RCPicture] = []
                var weekResults: [RCPicture] = []
                var monthResults: [RCPicture] = []
                var yearResults: [RCPicture] = []
                for object in objects {
                    let picture = RCPicture(snapshot: object)
                    if picture.longitude <= longHigh && picture.longitude >= longLow {
                        if picture.isMostRecent {
                            if picture.time >= weekTime {
                                recentResults.append(picture)
                            } else if picture.time <= weekTime && picture.time >= monthTime {
                                weekResults.append(picture)
                            } else if picture.time <= monthTime && picture.time >= yearTime {
                                monthResults.append(picture)
                            } else if picture.time <= yearTime && picture.time <= yearTime {
                                yearResults.append(picture)
                            }
                        }
                    }
                }

                self.collectionDictionaryData[PhotoLibChallengeVC.TAKE_PIC_FROM_RECENT] = recentResults
                self.collectionDictionaryData[PhotoLibChallengeVC.TAKE_PIC_FROM_WEEK] = weekResults
                self.collectionDictionaryData[PhotoLibChallengeVC.TAKE_PIC_FROM_MONTH] = monthResults
                self.collectionDictionaryData[PhotoLibChallengeVC.TAKE_PIC_FROM_YEAR] = yearResults

                
                if self.collectionDictionaryData[PhotoLibChallengeVC.TAKE_PIC_FROM_RECENT]?.count != 0 {
                    self.tableSectionArray.append(PhotoLibChallengeVC.TAKE_PIC_FROM_RECENT)
                }
                if self.collectionDictionaryData[PhotoLibChallengeVC.TAKE_PIC_FROM_WEEK]?.count != 0 {
                    self.tableSectionArray.append(PhotoLibChallengeVC.TAKE_PIC_FROM_WEEK)
                }
                if self.collectionDictionaryData[PhotoLibChallengeVC.TAKE_PIC_FROM_MONTH]?.count != 0 {
                    self.tableSectionArray.append(PhotoLibChallengeVC.TAKE_PIC_FROM_MONTH)
                }
                if self.collectionDictionaryData[PhotoLibChallengeVC.TAKE_PIC_FROM_YEAR]?.count != 0 {
                    self.tableSectionArray.append(PhotoLibChallengeVC.TAKE_PIC_FROM_YEAR)
                }
                self.tableView.reloadData()
            }
        }
    }
    
    // MARK: - ImageButton Methods
    func imageButtonPressed(image: UIImage, pictureData: RCPicture) {
        print("Image Pressed")
        if mode == PhotoLibChallengeVC.CHALLENGE_MODE {
            let alert = UIAlertController(title: nil, message: "What would you like to do with this challenge?", preferredStyle: .actionSheet)
            let withoutNav = UIAlertAction(title: "Make Active", style: .default, handler: {(action) in
                self.addChallengeToUser(pictureData: pictureData)
                self.navigationController?.dismiss(animated: true, completion: nil)
                self.displaySuccessAlert(message: "You just set your active challenge! Make sure to navigate to the pin when you're ready to begin!")
            })
            let viewChallenge = UIAlertAction(title: "View This Challenge", style: .default, handler: {(action) in
                self.performSegue(withIdentifier: "PhotoSegue", sender: [pictureData, image])
                
            })
            let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            alert.addAction(withoutNav)
            alert.addAction(viewChallenge)
            alert.addAction(cancel)
            self.present(alert, animated: true, completion: nil)
        } else if mode == PhotoLibChallengeVC.PHOTO_LIB_MODE {
            self.performSegue(withIdentifier: "PhotoSegue", sender: [pictureData, image])
        }
    }
    
    private func displaySuccessAlert(message: String) {
        let alert = FCAlertView()
        alert.makeAlertTypeSuccess()
        alert.dismissOnOutsideTouch = true
        
        
        let titleString = "Success!"
        let subtitleString = message
        
        alert.showAlert(inView: self,
                        withTitle: titleString,
                        withSubtitle: subtitleString,
                        withCustomImage: nil,
                        withDoneButtonTitle: "Let's Go!",
                        andButtons: nil)
    }
    
    /*
     Gets the time difference between now and
     when the picture was taken. Returns a constant
     representing what type of challenge category the pic
     falls into
     */
    private func getPicChallengeCategory(pictureData: RCPicture, currentDate: Date) -> String {
        //let pictureDate = DateGetter.getDateFromString(string: pictureData.time)
        let dateDiffSec = Int(abs(TimeInterval(pictureData.time) - currentDate.timeIntervalSince1970))
        //let dateDiffSec = Int(abs(pictureDate.timeIntervalSince(currentDate)))
        if dateDiffSec >= PhotoLibChallengeVC.SECONDS_IN_YEAR {
            return PhotoLibChallengeVC.TAKE_PIC_FROM_YEAR
        }
        else if dateDiffSec >= PhotoLibChallengeVC.SECONDS_IN_MONTH {
            return PhotoLibChallengeVC.TAKE_PIC_FROM_MONTH
        }
        else if dateDiffSec >= PhotoLibChallengeVC.SECONDS_IN_WEEK {
            return PhotoLibChallengeVC.TAKE_PIC_FROM_WEEK
        }
        else {
            return PhotoLibChallengeVC.TAKE_PIC_FROM_RECENT
        }
    }
    
    private func addChallengeToUser(pictureData: RCPicture) {
        let challengeCategory = getPicChallengeCategory(pictureData: pictureData, currentDate: Date())
        var points = 0
        if challengeCategory == PhotoLibChallengeVC.TAKE_PIC_FROM_WEEK {
            points = PhotoLibChallengeVC.CHALLENGE_WEEK_POINTS
        }
        else if challengeCategory == PhotoLibChallengeVC.TAKE_PIC_FROM_MONTH {
            points = PhotoLibChallengeVC.CHALLENGE_MONTH_POINTS
        }
        else if challengeCategory == PhotoLibChallengeVC.TAKE_PIC_FROM_YEAR {
            points = PhotoLibChallengeVC.CHALLENGE_YEAR_POINTS
        }
        else if challengeCategory == PhotoLibChallengeVC.TAKE_PIC_FROM_RECENT {
            points = PhotoLibChallengeVC.CHALLENGE_RECENT_POINTS
        }
        
        challengeDelegate?.userDidAddNewChallenge(picture: pictureData)
        
        self.userData.update(values: [ChallengeSetup.Properties.activeChallenge : pictureData.id,
                                      .activeChallengePoints: points])
        
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return tableSectionArray.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 1
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return tableSectionArray[section]
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TableCell", for: indexPath) as! PhotoChallengeTableCell
        // Configure the cell...
        
        return cell
    }
    
    /*
     This method also sets the collection view delegate in
     every table cell. It also tags each collection view
     to determine what table cell it is apart of
     */
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let tableCell = cell as! PhotoChallengeTableCell
        tableCell.setPictureCollectionViewDataSourceDelegate(dataSourceDelegate: self, forSection: indexPath.section)
        
        cell.backgroundColor = UIColor.clear
        cell.textLabel?.textColor = UIColor.white
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 40))
        headerView.backgroundColor = UIColor.clear
        
        let label = UILabel(frame: headerView.frame)
        label.font.withSize(30)
        label.text = self.tableSectionArray[section]
        label.textColor = UIColor.white
        label.textAlignment = .center
        headerView.addSubview(label)
        
        return headerView
        
    }
    
    // MARK: - Collection View Methods
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionIndex = collectionView.tag
        let sectionTitle = self.tableSectionArray[sectionIndex]
        return (self.collectionDictionaryData[sectionTitle]?.count)!
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PictureCell", for: indexPath) as! PhotoChalColCell
        cell.setImageViewDelegate(delegate: self)
        let sectionIndex = collectionView.tag
        let row = indexPath.row
        var pictureData: RCPicture?
        let sectionTitle = self.tableSectionArray[sectionIndex]
        let collectionDataArray = self.collectionDictionaryData[sectionTitle]
        pictureData = collectionDataArray?[row]
        cell.pictureData = pictureData
        if let realPictureData = pictureData {
            FirebaseHandler.downloadPicture(pictureData: realPictureData) { (image) in
                if let image = image {
                    cell.imageView.image = image
                } else {
                    Log.i("Could not get image from callback")
                }
            }
            return cell
        }
        return cell
    }
    
    var spinner: UIActivityIndicatorView?
    func setupSpinner() {
        spinner = UIActivityIndicatorView(style: .whiteLarge)
        spinner?.center = self.view.center
        spinner?.hidesWhenStopped = true
        self.view.addSubview(spinner!)
        stopSpinner()
    }
    
    func stopSpinner() {
        Timer.scheduledTimer(withTimeInterval: 4, repeats: false) { (timer) in
            timer.invalidate()
            self.spinner?.stopAnimating()
        }
    }
    
    
    
    /*
     // Override to support conditional editing of the table view.
     override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the specified item to be editable.
     return true
     }
     */
    
    /*
     // Override to support editing the table view.
     override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
     if editingStyle == .delete {
     // Delete the row from the data source
     tableView.deleteRows(at: [indexPath], with: .fade)
     } else if editingStyle == .insert {
     // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
     }
     }
     */
    
    /*
     // Override to support rearranging the table view.
     override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
     
     }
     */
    
    /*
     // Override to support conditional rearranging of the table view.
     override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the item to be re-orderable.
     return true
     }
     */
    
    
    
    
    
    func applyBlurEffect(image: UIImage){
        let imageToBlur = CIImage(image: image)
        let blurfilter = CIFilter(name: "CIGaussianBlur")
        blurfilter?.setValue(imageToBlur, forKey: "inputImage")
        let resultImage = blurfilter?.value(forKey: "outputImage") as! CIImage
        let blurredImage = UIImage(ciImage: resultImage)
        
        let blurredView = UIImageView(image: blurredImage)
        blurredView.contentMode = .center
        self.tableView.backgroundView = blurredView
        
        
    }
    
    @IBAction func photoDeletedUnwindSegue(segue: UIStoryboardSegue) {
        // Determines if a photo has been deleted, updates the view if one has
        self.setup()
    }
    
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        let segueID = segue.identifier
        if segueID == PhotoLibChallengeVC.PHOTO_SEGUE {
            let destination = segue.destination as! UINavigationController
            let photoView = destination.topViewController as! PhotoTimelineVC
            let infoArray = sender as! [Any]
            let pictureData = infoArray[PhotoLibChallengeVC.PHOTO_SEGUE_PICTURE_DATA_INDEX] as! RCPicture
            let picture = infoArray[PhotoLibChallengeVC.PHOTO_SEGUE_PICTURE_INDEX] as! UIImage
            photoView.userData = self.userData
            photoView.pictureData = pictureData
            photoView.image = picture
            photoView.mode = self.mode
        }
    }
    
    deinit {
        print("PhotoLibChallenge destroyed")
    }
    
}

