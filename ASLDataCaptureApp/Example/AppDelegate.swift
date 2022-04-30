//
//  AppDelegate.swift
//  Example
//
//  Created by Tomoya Hirano on 2020/04/02.
//  Copyright © 2020 Tomoya Hirano. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  
  var window: UIWindow?

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    // Override point for customization after application launch.
    self.window = UIWindow(frame: UIScreen.main.bounds)
    
//    let session = CaptureSessionInformation(ngrok: "f8fb-75-85-187-237", label: "A", targetNumberOfSamples: 100)
//    let vc = CaptureSessionUIViewController(sessionInfo: session)
    
    let vc = CaptureOptionsUIViewController()
    self.window?.rootViewController = vc
    self.window?.makeKeyAndVisible()
    return true
  }

}

