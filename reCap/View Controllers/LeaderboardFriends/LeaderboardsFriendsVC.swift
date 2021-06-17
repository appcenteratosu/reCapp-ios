//
//  LeaderboardsFriendsVC.swift
//  reCap
//
//  Created by Jackson Delametter on 2/11/18.
//  Copyright © 2018 Kaleb Cooper. All rights reserved.
//

import UIKit
import Firebase
import SwiftLocation
import CoreLocation
import FCAlertView


class LeaderboardsFriendsVC: UITableViewController, FCAlertViewDelegate {
    
    @IBOutlet weak var backButtonOutlet: UIBarButtonItem!
    @IBOutlet weak var locationControl: UISegmentedControl!
    
    @IBAction func locationFilterChanged(_ sender: Any) {
        let currentLocationIndex = self.locationControl.selectedSegmentIndex
        if currentLocationIndex == LeaderboardsFriendsVC.STATE_FILTER {
            self.leaderboardsList = self.stateLeaderboards
        }
        else if currentLocationIndex == LeaderboardsFriendsVC.COUNTRY_FILTER {
            self.leaderboardsList = self.countryLeaderboards
        }
        else if currentLocationIndex == LeaderboardsFriendsVC.GLOBAL_FILTER {
            self.leaderboardsList = self.globalLeaderboards
        }
        self.tableView.reloadData()
    }
    
    // MARK: - Properties
    static var LEADERBOARD_MODE = 0
    static var FRIENDS_LIST_MODE = 1
    var mode: Int!
    var user: User!
    var userData: ChallengeSetup!
    private var friendsList: [ChallengeSetup]!
    private var leaderboardsList: [ChallengeSetup]!
    private var stateLeaderboards: [ChallengeSetup]!
    private var countryLeaderboards: [ChallengeSetup]!
    private var globalLeaderboards: [ChallengeSetup]!
    
    private static let STATE_FILTER = 0
    private static let COUNTRY_FILTER = 1
    private static let GLOBAL_FILTER = 2
    
    override func viewDidLoad() {
        super.viewDidLoad()
        applyBlurEffect(image: #imageLiteral(resourceName: "Gradient"))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.userData = DataManager.currentAppUser
        
        friendsList = []
        leaderboardsList = []
        stateLeaderboards = []
        countryLeaderboards = []
        globalLeaderboards = []
        if mode != nil {
            // If the mode has been selected
            if mode == LeaderboardsFriendsVC.FRIENDS_LIST_MODE, userData != nil {
                // Friends list mode has been picked
                setupFriendsList()
            } else if mode == LeaderboardsFriendsVC.LEADERBOARD_MODE {
                setupLeaderboards()
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if mode == LeaderboardsFriendsVC.FRIENDS_LIST_MODE {
            return friendsList.count
        } else if mode == LeaderboardsFriendsVC.LEADERBOARD_MODE {
            return leaderboardsList.count
        } else {
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    // MARK: - Setup Methods
    private func setupLeaderboards() {
        self.title = "Leaderboards"
        self.navigationItem.leftBarButtonItem = nil
        self.navigationItem.rightBarButtonItem = nil
        
        let usersDataRef = FirebaseHandler.database.child("UserData")
        // State Results
        
        usersDataRef.queryOrdered(byChild: "state").queryEqual(toValue: userData.state).observeSingleEvent(of: .value) { (snap) in
            if let snaps = snap.children.allObjects as? [DataSnapshot] {
                var state: [ChallengeSetup] = []
                for child in snaps {
                    let rcuser = ChallengeSetup(snapshot: child)
                    state.append(rcuser)
                }
                
                state.sort(by: { (p1, p2) -> Bool in
                    return p1.points > p2.points
                })
                
                let top50 = Array(state.prefix(50))
                self.stateLeaderboards = top50
                self.leaderboardsList = top50
                self.tableView.reloadData()
            }
        }
        
        usersDataRef.queryOrdered(byChild: "country").queryEqual(toValue: userData.country).observeSingleEvent(of: .value) { (snap) in
            if let snaps = snap.children.allObjects as? [DataSnapshot] {
                var country = [ChallengeSetup]()
                for child in snaps {
                    let rcuser = ChallengeSetup(snapshot: child)
                    country.append(rcuser)
                }
                
                country.sort(by: { (p1, p2) -> Bool in
                    return p1.points > p2.points
                })
                
                let top50 = Array(country.prefix(50))
                self.countryLeaderboards = top50
            }
        }
        

        usersDataRef.observeSingleEvent(of: .value) { (snap) in
            if let snaps = snap.children.allObjects as? [DataSnapshot] {
                var global = [ChallengeSetup]()
                for child in snaps {
                    let rcuser = ChallengeSetup(snapshot: child)
                    global.append(rcuser)
                }
                
                global.sort(by: { (p1, p2) -> Bool in
                    return p1.points > p2.points
                })
                
                let top50 = Array(global.prefix(50))
                self.globalLeaderboards = top50
            }
        }
    }
    
    private func setupFriendsList() {
        self.title = "Friends List"
        self.locationControl.isHidden = true
        for friend in self.userData.friends {
            FirebaseHandler.database.child("UserData").child(friend).observeSingleEvent(of: .value) { (snap) in
                let friend = ChallengeSetup(snapshot: snap)
                self.friendsList.append(friend)
            }
            self.tableView.reloadData()
        }
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CustomCell", for: indexPath) as! LeaderboardFriendsTableCell
        let user: ChallengeSetup!
        if mode == LeaderboardsFriendsVC.FRIENDS_LIST_MODE {
            user = friendsList[indexPath.row]
            cell.pointsOutlet.text = "\(user.points) points"
        } else if mode == LeaderboardsFriendsVC.LEADERBOARD_MODE {
            user = leaderboardsList[indexPath.row]
            cell.pointsOutlet.text = "\(user.points) points"
        } else {
            return cell
        }
        cell.fullNameOutlet.text = user.name
        cell.usernameOutlet.text = user.email
        
        if let image = ProfileImageCacher.requestProfilePictureFor(uid: user.id) {
            cell.imageOutlet.image = image
        } else {
            FirebaseHandler.getProfilePicture(userID: user.id, completion: { (image) in
                if let pic = image {
                    cell.imageOutlet.image = pic
                    ProfileImageCacher.AddNewProfilePicture(uid: user.id, image: pic)
                } else {
                    Log.e("Defaulting - Couldn't get image from FirebaseHandler.getProfilePicture()")
                    cell.imageOutlet.image = #imageLiteral(resourceName: "icons8-user-30 (1)")
                }
            }) { (progress) in
                print("Profile Image Progress:", progress)
            }
        }
        
        
        return cell
    }
    
    // MARK: - Outlet Action Methods
    @IBAction func addFriendPressed(_ sender: Any) {
        
        let alert = FCAlertView()
        alert.makeAlertTypeCaution()
        alert.dismissOnOutsideTouch = false
        alert.darkTheme = true
        alert.bounceAnimations = true
        alert.addTextField(withPlaceholder: "Enter Friends Username") { (email) in
            if email != "", email != self.userData.email {
                FCAlertView.displayAlert(title: "Adding...", message: "Adding friend to your friends list...", buttonTitle: "Dismiss", type: "progress", view: self)
                
                if let email = email {
                    
                    FirebaseHandler.findAccount(for: email, completion: { (user, done) in
                        guard let user = user else {
                            FCAlertView.displayAlert(title: "Oops!",
                                                     message: "That email doesn't exist",
                                                     buttonTitle: "OK",
                                                     type: "warning",
                                                     view: self)
                            return
                        }
                        
                        self.friendsList.append(user)
                        self.tableView.beginUpdates()
                        let index = IndexPath(row: self.friendsList.count-1, section: 0)
                        self.tableView.insertRows(at: [index], with: .automatic)
                        self.tableView.endUpdates()
                        
                        self.userData.add(friend: user)
                        
                    })
                }
            }
        }
        alert.addButton("Cancel") {
            
        }
        alert.showAlert(withTitle: "Add Friend", withSubtitle: "Please enter your friends username.", withCustomImage: nil, withDoneButtonTitle: "Add", andButtons: nil)
        
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if mode == LeaderboardsFriendsVC.FRIENDS_LIST_MODE {
            self.performSegue(withIdentifier: "PhotoLibSegue", sender: friendsList[indexPath.row])
        } else if mode == LeaderboardsFriendsVC.LEADERBOARD_MODE {
            self.performSegue(withIdentifier: "PhotoLibSegue", sender: leaderboardsList[indexPath.row])

        }
    }
    
    // MARK: - Outlet Actions
    @IBAction func backButtonPressed(_ sender: Any) {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    
    
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
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        let segueID = segue.identifier
        if segueID == "PhotoLibSegue" {
            let friend = sender as! ChallengeSetup
            let destination = segue.destination as! UINavigationController
            let photoLibVC = destination.topViewController as! PhotoLibChallengeVC
            photoLibVC.userData = friend
            photoLibVC.mode = PhotoLibChallengeVC.PHOTO_LIB_MODE
        }
    }
    
    
}
