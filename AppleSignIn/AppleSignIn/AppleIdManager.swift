//
//  AppleIdManager.swift
//  AppleSignIn
//
//  Created by CXY on 2020/3/10.
//  Copyright © 2020 ubtechinc. All rights reserved.
//

import UIKit
import AuthenticationServices


class AppleIdManager: NSObject {
    static let shared = AppleIdManager()
    private override init() {
        super.init()
    }
    
    private var presentationAnchor: UIViewController?
    
    typealias AuthorizationSucceed = (_ uid: String, _ authorizationCode: Data?, _ identityToken: Data?, _ email: String?, _ fullName: PersonNameComponents?) -> Void
    
    typealias AuthorizationFailed = (_ errorMsg: String) -> Void
    
    typealias VerifyCredentialState = (_ isValid: Bool, _ errorMsg: String) -> Void
    
    private var authorizeSucceedCallBack: AuthorizationSucceed?
    
    private var authorizeFailedCallBack: AuthorizationFailed?
    
    // 用户可能注销Appleid或者在设置中停用Apple Sign in功能。我们需要在 App 启动的时候，通过 getCredentialState:completion: 来获取当前用户的授权状态。
    static func verifyCredentialState(callback: VerifyCredentialState? = nil) {
        do {
            let userIdentifier = try KeychainPasswordItem(service: KeychainConfiguration.serviceName, account: "userIdentifier").readPassword()
            
            print("userIdentifier === \(userIdentifier)")
            if #available(iOS 13.0, *) {
                ASAuthorizationAppleIDProvider().getCredentialState(forUserID: userIdentifier) { (state, error) in
                    
                    var msg = ""
                    
                    switch (state) {
                    case .authorized:// 授权状态有效
                        msg = "授权状态有效"
                    case .revoked:// 上次使用苹果账号登录的凭据已被移除，需解除绑定并重新引导用户使用苹果登录
                        msg = "凭据已被移除"
                    case .notFound:// 未登录授权，直接弹出登录页面，引导用户登录
                        msg = "未登录授权"
                    default: break
                        
                    }
                    
                    DispatchQueue.main.async {
                        callback?(state == .authorized, msg)
                    }
                }
            } else {
                // Fallback on earlier versions
            }
            
        } catch {
            print("Unable to read userIdentifier to keychain.")
        }
    }
    
    
    static func addCredentialRevokedListener() {
        if #available(iOS 13.0, *) {
            NotificationCenter.default.addObserver(AppleIdManager.shared, selector: #selector(credentialRevokedNotification(_:)), name: ASAuthorizationAppleIDProvider.credentialRevokedNotification, object: nil)
        }
    }

    
    @objc private func credentialRevokedNotification(_ notification: Notification) {
        // Sign the user out, optionally guide them to sign in again
        print("credentialRevoked \(String(describing: notification.userInfo))")
    }
    
    
    // MARK: 加入 Sign in with Apple Button,可以调整的只有圆角cornerRadius和size
    
    @available(iOS 13.0, *)
    func createAppleIdButton(authorizationButtonType: ASAuthorizationAppleIDButton.ButtonType, authorizationButtonStyle: ASAuthorizationAppleIDButton.Style, cornerRadius: CGFloat = 8) -> UIView {
        let button = ASAuthorizationAppleIDButton(authorizationButtonType: authorizationButtonType, authorizationButtonStyle: authorizationButtonStyle)
        button.cornerRadius = cornerRadius
        button.addTarget(self, action: #selector(appleLoginButtonTapped), for: .touchUpInside)
        return button
    }
    
    func prepareForAuthorization(presentationAnchor: UIViewController, succeed: AuthorizationSucceed?, failed: AuthorizationFailed?) {
        self.presentationAnchor = presentationAnchor
        self.authorizeFailedCallBack = failed
        self.authorizeSucceedCallBack = succeed
    }
    
    // MARK: 发起登录请求
    
    /// Prompts the user if an existing iCloud Keychain credential or Apple ID credential is found.
    @objc private func appleLoginButtonTapped() {
        if #available(iOS 13.0, *) {
            let idRequest = ASAuthorizationAppleIDProvider().createRequest()
            idRequest.requestedScopes = [.fullName, .email]
            // 如果用户之前已经登陆过，那么我们可以提醒用户输入密码直接登录之前的账号,避免产生新的账户
            //  https://developer.apple.com/documentation/signinwithapplerestapi/authenticating_users_with_sign_in_with_apple

            let pwdRequest = ASAuthorizationPasswordProvider().createRequest()
            let authorizationController =
                ASAuthorizationController(authorizationRequests: [idRequest, pwdRequest])
            authorizationController.delegate = self
            authorizationController.presentationContextProvider = self
            authorizationController.performRequests()
        } else {
            // Fallback on earlier versions
        }
        
    }
}


//Credential 裡面會包含以下的資料：
//Authorization Code
//Identity Token
//Email (Optional)
//User Identifier
//Name (Family Name / Given Name…) (Optional)
// MARK: ASAuthorizationControllerDelegate

extension AppleIdManager: ASAuthorizationControllerDelegate {
    
    @available(iOS 13.0, *)
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        switch authorization.credential {
        case let appleIdCredential as ASAuthorizationAppleIDCredential:
            let userIdentifier = appleIdCredential.user
            let fullName = appleIdCredential.fullName
            let email = appleIdCredential.email
            
            // Create an account in your system.
            // For the purpose of this demo app, store the userIdentifier in the keychain.
            do {
                try KeychainPasswordItem(service: KeychainConfiguration.serviceName, account: "userIdentifier").savePassword(userIdentifier)
            } catch {
                print("Unable to save userIdentifier to keychain.")
            }
            // Actually, should upload credential to server api
            // balabalabala
            
            // For the purpose of this demo app, show the Apple ID credential information in the ResultViewController.
            
            DispatchQueue.main.async {
                self.authorizeSucceedCallBack?(userIdentifier, appleIdCredential.authorizationCode, appleIdCredential.identityToken, email, fullName)
            }
            
        case let passwordCredential as ASPasswordCredential:
            // Sign in using an existing iCloud Keychain credential.
            let username = passwordCredential.user
            let password = passwordCredential.password
            
            // For the purpose of this demo app, show the password credential as an alert.
            DispatchQueue.main.async {
                let message = "The app has received your selected credential from the keychain. \n\n Username: \(username)\n Password: \(password)"
                let alertController = UIAlertController(title: "Keychain Credential Received",
                                                        message: message,
                                                        preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
//                self.present(alertController, animated: true, completion: nil)
            }
        default:
            break
        }
        
    }
    
    
    @available(iOS 13.0, *)
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        // Handle error.
        var errorMsg = "授权失败"
        
        switch (error) {
        case ASAuthorizationError.canceled:
                errorMsg = "用户取消了授权请求"
        case ASAuthorizationError.failed:
                errorMsg = "授权请求失败"
        case ASAuthorizationError.invalidResponse:
                errorMsg = "授权请求响应无效"
        case ASAuthorizationError.notHandled:
                errorMsg = "未能处理授权请求"
        case ASAuthorizationError.unknown:
                errorMsg = "授权请求失败未知原因"
        
        default:
            break
        }
        
        authorizeFailedCallBack?(errorMsg)
    }
}

// MARK: ASAuthorizationControllerPresentationContextProviding

extension AppleIdManager: ASAuthorizationControllerPresentationContextProviding {
    @available(iOS 13.0, *)
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return presentationAnchor!.view.window!
    }
}

