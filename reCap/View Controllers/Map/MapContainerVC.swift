//
//  MapContainerVC.swift
//  reCap
//
//  Created by Kaleb Cooper on 2/4/18.
//  Copyright © 2018 Kaleb Cooper. All rights reserved.
//

import UIKit
import Firebase


class MapContainerVC: UIViewController {
    
    // MARK: - Properties
    var userData: ChallengeSetup!
    private static let CHALLENGE_SEGUE = "ChallengeSegue"

    override func viewDidLoad() {
        super.viewDidLoad()
        print("Map container loaded")
        self.userData = DataManager.currentAppUser
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    
    // MARK: - Outlet Actions
    
    @IBAction func challengesFixed(_ sender: Any) {
        self.performSegue(withIdentifier: "ChallengeSegue", sender: nil)
    }
    var mapVC: MapVC?
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        let id = segue.identifier
        if id == MapContainerVC.CHALLENGE_SEGUE {
            let desination = segue.destination as! UINavigationController
            let challengeVC = desination.topViewController as! PhotoLibChallengeVC
            challengeVC.mode = PhotoLibChallengeVC.CHALLENGE_MODE
            challengeVC.userData = self.userData
            if let mapVC = mapVC  {
                challengeVC.challengeDelegate = mapVC
            }
        } else if id == "MapSegue" {
            let desination = segue.destination as! MapVC
            self.mapVC = desination
            //desination.user = self.user
        }
    }

}
