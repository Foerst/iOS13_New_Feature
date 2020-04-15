//
//  AppDelegate.swift
//  BgTasks
//
//  Created by CXY on 2020/4/2.
//  Copyright © 2020 jc. All rights reserved.
//

import UIKit
import BackgroundTasks

let fileUrl = "http://assets-new.ubtrobot.com/pc/static/cn/media/walker.mp4"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        registerBackgroundTaks()
        registerLocalNotification()
        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        cancelAllBgTasks()
        scheduleAppRefresh()
        scheduleDatabaseCleaningIfNeeded()
    }
}

extension AppDelegate {
    
    private func cancelAllBgTasks() {
        BGTaskScheduler.shared.cancelAllTaskRequests()
    }
    
    //MARK: Regiater BackGround Tasks
    private func registerBackgroundTaks() {
        // MARK: Registering Launch Handlers for Tasks
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.jc.app-refresh", using: nil) { task in
            // Downcast the parameter to an app refresh task as this identifier is used for a refresh request.
            self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }
    
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.jc.processing", using: nil) { task in
            // Downcast the parameter to a processing task as this identifier is used for a processing request.
            self.handleDatabaseCleaning(task: task as! BGProcessingTask)
        }
    }
    
    // MARK: - Scheduling Tasks
    
    func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.jc.app-refresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // Fetch no earlier than 15 minutes from now
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule app refresh: \(error)")
        }
    }
    
    func scheduleDatabaseCleaningIfNeeded() {
        let request = BGProcessingTaskRequest(identifier: "com.jc.processing")
        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = true
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule database cleaning: \(error)")
        }
    }
    
    // MARK: - Handling Launch for Tasks

    // Fetch the latest feed entries from server.
    func handleAppRefresh(task: BGAppRefreshTask) {
        scheduleAppRefresh() // Recall
        scheduleLocalNotification()
        
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        
        let operation = FetchFilesOperation(url: fileUrl)
        
        task.expirationHandler = {
            // After all operations are cancelled, the completion block below is called to set the task to complete.
            queue.cancelAllOperations()
        }
        
        operation.completionBlock = {
            task.setTaskCompleted(success: !operation.isCancelled)
        }

        queue.addOperations([operation], waitUntilFinished: false)
        
    }
    
    // Delete feed entries older than one day.
    func handleDatabaseCleaning(task: BGProcessingTask) {

    }
}

extension AppDelegate {
    
    func registerLocalNotification() {
        let notificationCenter = UNUserNotificationCenter.current()
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        
        notificationCenter.requestAuthorization(options: options) {
            (didAllow, error) in
            if !didAllow {
                print("User has declined notifications")
            }
        }
    }
    
    func scheduleLocalNotification() {
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.getNotificationSettings { (settings) in
            if settings.authorizationStatus == .authorized {
                self.fireNotification()
            }
        }
    }
    
    func fireNotification() {
        // Create Notification Content
        let notificationContent = UNMutableNotificationContent()
        
        // Configure Notification Content
        notificationContent.title = "Bg"
        notificationContent.body = "BG Notifications."
        
        // Add Trigger
        let notificationTrigger = UNTimeIntervalNotificationTrigger(timeInterval: 1.0, repeats: false)
        
        // Create Notification Request
        let notificationRequest = UNNotificationRequest(identifier: "local_notification", content: notificationContent, trigger: notificationTrigger)
        
        // Add Request to User Notification Center
        UNUserNotificationCenter.current().add(notificationRequest) { (error) in
            if let error = error {
                print("Unable to Add Notification Request (\(error), \(error.localizedDescription))")
            }
        }
    }
}

