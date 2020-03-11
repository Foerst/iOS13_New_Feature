//
//  ViewController.swift
//  AppleSignIn
//
//  Created by CXY on 2020/3/9.
//  Copyright © 2020 jc. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        AppleIdManager.shared.prepareForAuthorization(presentationAnchor: self, succeed: { [weak self]  (userIdentifier, code, token, email, fullName) in
            guard let strongSelf = self else { return }
            
            let viewController = ResultViewController()
            strongSelf.present(viewController, animated: true, completion: nil)
            
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+2) {
                viewController.userIdentifierLabel.text = userIdentifier
                if let givenName = fullName?.givenName {
                    viewController.givenNameLabel.text = givenName
                }
                if let familyName = fullName?.familyName {
                    viewController.familyNameLabel.text = familyName
                }
                if let email = email {
                    viewController.emailLabel.text = email
                }
            }
            
        }) { [weak self]  (errorMsg) in
            guard let strongSelf = self else { return }
            
            let alertController = UIAlertController(title: nil,
                                                    message: errorMsg,
                                                    preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "关闭", style: .cancel, handler: nil))
            strongSelf.present(alertController, animated: true, completion: nil)
        }
    }

    private func setupUI() {
        if #available(iOS 13.0, *) {
            let button = AppleIdManager.shared.createAppleIdButton(authorizationButtonType: .default, authorizationButtonStyle: .whiteOutline, cornerRadius: 20)
            let screenWidth = UIScreen.main.bounds.size.width
            button.frame = CGRect(x: (screenWidth-150)/2, y: 500, width: 150, height: 50)
            view.addSubview(button)
        } else {
            // Fallback on earlier versions
        }
        
    }
    


}


