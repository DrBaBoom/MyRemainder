//
//  AppDelegate.swift
//  MyRemainder
//
//  Created by Yura on 21.09.2023.
//

import UIKit
import UserNotifications
import BackgroundTasks

@main
class AppDelegate: UIResponder, UIApplicationDelegate {


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        BGTaskScheduler.shared.register(
          forTaskWithIdentifier: "com.mycompany.myapp.task.refresh",
          using: nil) { task in
            self.refresh() // 1
            task.setTaskCompleted(success: true) // 2
            self.scheduleNextRefresh() // 3
        }
        scheduleNextRefresh()
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    func refresh() {
        print("Want to create note")
        let content = UNMutableNotificationContent()
        content.body = "HiiiiiiiHHH"
        content.sound = .defaultCritical
        let dateMatching = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute],
                                                           from: Date.now)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateMatching, repeats: false)
        let id = "MyRemainder\(dateMatching.year!)\(dateMatching.month!)\(dateMatching.day!)\(dateMatching.hour!)\(dateMatching.minute!)"
        let request = UNNotificationRequest(identifier: id ,
                                            content: content,
                                            trigger: trigger)
        
        UNUserNotificationCenter.current().add(request, withCompletionHandler: { error in
            if error != nil {
                print("Something went wrong with Notification")
            }
        })
//      let formattedDate = Self.dateFormatter.string(from: Date())
//      UserDefaults.standard.set(formattedDate, forKey: "YuraKey")
//      print("refresh occurred")
    }

    func scheduleNextRefresh() {
      let request = BGAppRefreshTaskRequest(identifier: "com.mycompany.myapp.task.refresh")
      request.earliestBeginDate = Date(timeIntervalSinceNow: 5)
      do {
        try BGTaskScheduler.shared.submit(request)
        print("background refresh scheduled")
      } catch {
        print("Couldn't schedule app refresh \(error.localizedDescription)")
      }
    }
}

