//
//  AppDelegate.swift
//  AppleSignIn
//
//  Created by CXY on 2020/3/9.
//  Copyright © 2020 jc. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        AppleIdManager.verifyCredentialState {[weak self] (isValid, msg) in
            guard let strongSelf = self else { return }
            if !isValid {
                let alertController = UIAlertController(title: nil,
                                                        message: msg,
                                                        preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                strongSelf.window?.rootViewController?.present(alertController, animated: true, completion: nil)
            }
        }
        AppleIdManager.addCredentialRevokedListener()
        
        return true
    }
    
    

}

