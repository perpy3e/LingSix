import UIKit
import Flutter
import FirebaseCore
import GoogleSignIn   
@main
@objc class AppDelegate: FlutterAppDelegate {
    
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
   
    FirebaseApp.configure()
    
    
    GeneratedPluginRegistrant.register(with: self)
    
    
    GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
      if let error = error {
        print("Error restoring previous sign-in: \(error.localizedDescription)")
      } else if let user = user {
        print("✅ Restored previous Google user: \(user.profile?.email ?? "unknown")")
      } else {
        print("ℹ️ No previous Google sign-in found")
      }
    }

    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
   
    if GIDSignIn.sharedInstance.handle(url) {
      return true
    }
    return super.application(app, open: url, options: options)
  }
}
