//
//  SignInTransitionVC.swift
//  reCap
//
//  Created by Kaleb Cooper on 2/6/18.
//  Copyright © 2020 OSU App Center. All rights reserved.
//

import UIKit

class SignInTransitionVC: UIViewController {
    
    var gradientLayer: CAGradientLayer!
    
    // region UIViewController
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        createGradientLayer()
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: {
            
            self.performSegue(withIdentifier: "SignInTransition", sender: self)
            
        })

        // Do any additional setup after loading the view.
    }
    
    // endregion

    func createGradientLayer() {
        gradientLayer = CAGradientLayer()
        
        gradientLayer.frame = self.view.bounds
        
        let bottomColor = UIColor(displayP3Red: 99/255, green: 207/255, blue: 155/255, alpha: 1).cgColor
        let topColor = UIColor(displayP3Red: 9/255, green: 85/255, blue: 95/255, alpha: 1).cgColor
        
        gradientLayer.colors = [topColor, bottomColor]
        
        self.view.layer.insertSublayer(gradientLayer, at: 0)
    }

}
