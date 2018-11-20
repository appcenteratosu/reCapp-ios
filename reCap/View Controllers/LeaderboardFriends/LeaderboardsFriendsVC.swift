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
    var userData: RCUser!
    private var friendsList: [RCUser]!
    private var leaderboardsList: [RCUser]!
    private var stateLeaderboards: [RCUser]!
    private var countryLeaderboards: [RCUser]!
    private var globalLeaderboards: [RCUser]!
    
    private static let STATE_FILTER = 0
    private static let COUNTRY_FILTER = 1
    private static let GLOBAL_FILTER = 2
    
    override func viewDidLoad() {
        super.viewDidLoad()
        applyBlurEffect(image: #imageLiteral(resourceName: "Gradient"))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        self.realm = try! Realm()
//        self.userData = realm.object(ofType: UserData.self, forPrimaryKey: SyncUser.current?.identity)
        
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
        }
        else if mode == LeaderboardsFriendsVC.LEADERBOARD_MODE {
            return leaderboardsList.count
        }
        else {
            return 0
        }
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
                for child in snaps {
                    if self.stateLeaderboards.count < 50 {
                        let rcuser = RCUser(snapshot: child)
                        self.stateLeaderboards.append(rcuser)
                    }
                }
                self.leaderboardsList = self.stateLeaderboards
                self.tableView.reloadData()
            }
        }
        
        usersDataRef.queryOrdered(byChild: "country").queryEqual(toValue: userData.country).observeSingleEvent(of: .value) { (snap) in
            if let snaps = snap.children.allObjects as? [DataSnapshot] {
                for child in snaps {
                    if self.countryLeaderboards.count < 50 {
                        let rcuser = RCUser(snapshot: child)
                        self.countryLeaderboards.append(rcuser)
                    }
                }
                self.tableView.reloadData()
            }
        }
        

        usersDataRef.observeSingleEvent(of: .value) { (snap) in
            if let snaps = snap.children.allObjects as? [DataSnapshot] {
                for child in snaps {
                    if self.globalLeaderboards.count < 50 {
                        let rcuser = RCUser(snapshot: child)
                        self.globalLeaderboards.append(rcuser)
                    }
                }
                self.tableView.reloadData()
            }
        }
        
        self.leaderboardsList = self.stateLeaderboards
        self.tableView.reloadData()
    }
    
    private func setupFriendsList() {
        self.title = "Friends List"
        self.locationControl.isHidden = true
        for friend in self.userData.friends {
            FirebaseHandler.database.child("UserData").child(friend).observeSingleEvent(of: .value) { (snap) in
                let friend = RCUser(snapshot: snap)
                self.friendsList.append(friend)
            }
            self.tableView.reloadData()
        }
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CustomCell", for: indexPath) as! LeaderboardFriendsTableCell
        let user: RCUser!
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
        FirebaseHandler.getProfilePicture(userID: user.id, completion: { (image) in
            if let pic = image {
                cell.imageOutlet.image = pic
            } else {
                print("Could not get Image")
            }
        }) { (progress) in
            print("Profile Image Progress:", progress)
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
                    FirebaseHandler.database.child("UserData").child(email).observeSingleEvent(of: .value, with: { (snap) in
                        if snap.value != nil {
                            let friend = RCUser(snapshot: snap)
                            self.friendsList.append(friend)
                            self.tableView.beginUpdates()
                            let index = IndexPath(row: self.friendsList.count-1, section: 0)
                            self.tableView.insertRows(at: [index], with: .automatic)
                            self.tableView.endUpdates()
                            self.userData.add(friend: friend)
                        } else {
                            FCAlertView.displayAlert(title: "Oops!", message: "That email doesn't exist", buttonTitle: "Okay", type: "warning", view: self)
                        }
                    })
                }
                
//                if let friend = self.realm.objects(UserData.self).filter("email = '\(email!.description)'").first {
//                    // The user exists
//                    self.friendsList.append(friend)
//                    self.tableView.beginUpdates()
//                    let index = IndexPath(row: self.friendsList.count-1, section: 0)
//                    self.tableView.insertRows(at: [index], with: .automatic)
//                    self.tableView.endUpdates()
//                    try! self.realm.write {
//                        self.userData.friends.append(friend)
//                    }
//                } else {
//                    FCAlertView.displayAlert(title: "Oops!", message: "Please make sure to type a email", buttonTitle: "Got It!", type: "warning", view: self)
//                }
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
        }
        else if mode == LeaderboardsFriendsVC.LEADERBOARD_MODE {
            self.performSegue(withIdentifier: "PhotoLibSegue", sender: leaderboardsList[indexPath.row])

        }
    }
    
    // MARK: - Outlet Actions
    @IBAction func backButtonPressed(_ sender: Any) {
        self.navigationController?.dismiss(animated: true, completion: nil)
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
            let friend = sender as! RCUser
            let destination = segue.destination as! UINavigationController
            let photoLibVC = destination.topViewController as! PhotoLibChallengeVC
            photoLibVC.userData = friend
            photoLibVC.mode = PhotoLibChallengeVC.PHOTO_LIB_MODE
        }
    }
    
    
}
