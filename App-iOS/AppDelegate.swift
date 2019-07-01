/*
    <samplecode>
        <abstract>
            Main app controller.
        </abstract>
    </samplecode>
 */

import UIKit
import UserNotifications

@UIApplicationMain
class AppDelegate : UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    var window: UIWindow?
    var manager: AppProxyManager?
    var center: UNUserNotificationCenter! = nil

    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        let manager = AppProxyManager()
        self.manager = manager

        self.center = UNUserNotificationCenter.current()
        self.center.delegate = self
        self.center.requestAuthorization(options: [.alert]) { (granted, error) in
            if granted {
                NSLog("granted")
            } else {
                NSLog("not granted")
            }
        }
        
        let nav = (self.window!.rootViewController! as! UINavigationController)
        let main = (nav.viewControllers[0] as! MainViewController)
        main.manager = manager
        
        return true
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        NSLog("will present")
        completionHandler([])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        NSLog("did receive")
        completionHandler()
    }
}
