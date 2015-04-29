//
//  AppDelegate.swift
//  PersonLog
//
//  Created by Yasyf Mohamedali on 2015-03-17.
//  Copyright (c) 2015 Yasyf Mohamedali. All rights reserved.
//

import UIKit
import CoreData
import CoreBluetooth
import Localytics
import Fabric
import Crashlytics
import TwitterKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let settings = Settings()

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        #if !arch(i386)
            Localytics.autoIntegrate("eedd3e69e87dd4feba34968-c44ff1ae-ddb8-11e4-586b-00a426b17dd8", launchOptions: launchOptions)
            Fabric.with([Crashlytics(), Twitter()])
            Analytics.tagLaunchSource(launchOptions)
        #else
            Fabric.with([Twitter()])
        #endif

        let notificationSettings = UIUserNotificationSettings(forTypes: .Sound | .Alert | .Badge, categories: nil)
        application.registerUserNotificationSettings(notificationSettings)
        application.registerForRemoteNotifications()
        
        application.applicationIconBadgeNumber = 0
        
        if !settings.isLoggedIn() {
            self.showLoginScreen()
        } else if !settings.isDoneSetup() {
            self.showSetupScreen()
        } else {
            let discoverer =  MyAppDelege.sharedInstance.discoverer
            if discoverer.isDiscovering && discoverer.powerMode == .Low {
                discoverer.goHighPower()
            }
        }
        
        application.setStatusBarHidden(false, withAnimation: .None)
        
        #if DEMOMODE
            DemoMode().startLooping()
        #endif
        
        LocalNotification.scheduleDaily()
        
        return FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    func showLoginScreen() {
        let LoginViewController:UIViewController = UIStoryboard(name: "Main", bundle:nil).instantiateViewControllerWithIdentifier("Login") as! UIViewController
        self.window?.rootViewController = LoginViewController
    }
    
    func showSetupScreen() {
        let LoginViewController:UIViewController = UIStoryboard(name: "Main", bundle:nil).instantiateViewControllerWithIdentifier("Setup") as! UIViewController
        self.window?.rootViewController = LoginViewController
    }
    
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject?) -> Bool {
        return FBSDKApplicationDelegate.sharedInstance().application(application, openURL: url, sourceApplication: sourceApplication! as String, annotation: annotation)
    }
    
    func application(application: UIApplication, didReceiveLocalNotification notification: UILocalNotification) {
        if let type = notification.userInfo?["type"] as? String {
            Localytics.tagEvent("ReceiveLocalNotification", attributes: ["type": type])
        }
        application.applicationIconBadgeNumber = 0
        if let identifier = notification.userInfo?["identifier"] as? String {
            let url = NSURL(string: identifier)
            let interactionObjectID = persistentStoreCoordinator?.managedObjectIDForURIRepresentation(url!)
            let interaction = managedObjectContext?.objectWithID(interactionObjectID!) as! Interaction

            let navigationController = self.window?.rootViewController as! UINavigationController
            let viewControllers = navigationController.viewControllers as! [UIViewController]
            let timelineViewController = viewControllers[0] as! TimelineViewController
            
            timelineViewController.performSegueWithIdentifier("viewProfile", sender: interaction)
        }
        LocalNotification.scheduleDaily()
    }
    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        LocalNotification.scheduleDaily()
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        Localytics.tagEvent("AppStateChange", attributes: ["state": "background"])
        LocalNotification.scheduleDaily()
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        Localytics.tagEvent("AppStateChange", attributes: ["state": "foreground"])
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        application.applicationIconBadgeNumber = 0
        LocalNotification.scheduleDaily()
        FBSDKAppEvents.activateApp()
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        if settings.isLoggedIn() {
            let discoverer =  MyAppDelege.sharedInstance.discoverer
            if discoverer.isDiscovering {
                discoverer.goLowPower()
            }
        }
        LocalNotification.sendGeneric("Watch out! Quitting FishBowl will prevent you from discovering other users!")
        Localytics.tagEvent("AppTerminate")
        LocalNotification.scheduleDaily()
        self.saveContext()
    }

    // MARK: - Core Data stack

    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "com.yasyf.personlog.PersonLog" in the application's documents Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1] as! NSURL
    }()

    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("PersonLog", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()

    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("PersonLog.sqlite")
        var error: NSError? = nil
        var failureReason = "There was an error creating or loading the application's saved data."
        let options = [NSMigratePersistentStoresAutomaticallyOption: true,
            NSInferMappingModelAutomaticallyOption: true]
        if coordinator!.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: options, error: &error) == nil {
            coordinator = nil
            // Report any error we got.
            let dict = NSMutableDictionary()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            dict[NSUnderlyingErrorKey] = error
            error = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict as [NSObject : AnyObject])
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            CLS_LOG_SWIFT("Unresolved error \(error), \(error!.userInfo)")
            abort()
        }
        
        return coordinator
    }()

    lazy var managedObjectContext: NSManagedObjectContext? = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        if coordinator == nil {
            return nil
        }
        var managedObjectContext = NSManagedObjectContext()
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        if let moc = self.managedObjectContext {
            var error: NSError? = nil
            if moc.hasChanges && !moc.save(&error) {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                CLS_LOG_SWIFT("Unresolved error \(error), \(error!.userInfo)")
                abort()
            }
        }
    }

}

