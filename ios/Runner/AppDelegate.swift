import UIKit
import Flutter
import Firebase
import FirebaseAuth
import FirebaseMessaging
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate { // Remove redundant UNUserNotificationCenterDelegate
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Register Firebase
    FirebaseApp.configure()

    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
      // let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
      // UNUserNotificationCenter.current().requestAuthorization(
      //   options: authOptions,
      //   completionHandler: { granted, error in
      //     if let error = error {
      //       print("Error requesting notification authorization: \(error)")
      //     }
      //   })
    } else {
      // let settings: UIUserNotificationSettings =
      // UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
      // application.registerUserNotificationSettings(settings)
    }

    // Register for remote notifications
    application.registerForRemoteNotifications()

    // Register Flutter plugins
    GeneratedPluginRegistrant.register(with: self)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Handle APNs token registration and pass it to Firebase Auth
  override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    // Pass the APNs token to Firebase Auth for authentication purposes
    Auth.auth().setAPNSToken(deviceToken, type: .unknown)
    
    // Also set the APNs token for Firebase Messaging to handle notifications
    Messaging.messaging().apnsToken = deviceToken
  }

  // Handle incoming remote notifications and pass to Firebase Auth
  override func application(_ application: UIApplication, didReceiveRemoteNotification notification: [AnyHashable: Any],
                            fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    if Auth.auth().canHandleNotification(notification) {
      completionHandler(.noData)
      return
    }
    completionHandler(.newData)
  }

  // Display notifications in the foreground
  @available(iOS 10.0, *)
  override func userNotificationCenter(_ center: UNUserNotificationCenter, 
                                       willPresent notification: UNNotification, 
                                       withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    // Display notifications with alert, sound, and badge while app is in foreground
    completionHandler([.alert, .badge, .sound])
  }

  // Handle notification taps (when app is opened from a notification)
  @available(iOS 10.0, *)
  override func userNotificationCenter(_ center: UNUserNotificationCenter, 
                                       didReceive response: UNNotificationResponse, 
                                       withCompletionHandler completionHandler: @escaping () -> Void) {
    // This can be used to navigate to a specific screen when a notification is tapped
    completionHandler()
  }
}
