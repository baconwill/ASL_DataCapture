//
//  CaptureSessionParameterStore.swift
//  Example
//
//  Created by Etienne Goulet-Lang on 4/30/22.
//  Copyright © 2022 Tomoya Hirano. All rights reserved.
//

import Foundation

class CaptureSessionParameterStore {
  
  static let shared = CaptureSessionParameterStore()
  
  private init() {} // Use the singleton
  
  var ngrok: String {
    get {
      UserDefaults.standard.string(forKey: "network:ngrok") ?? "f8fb-75-85-187-237"
    }
    set {
      UserDefaults.standard.set(newValue, forKey: "network:ngrok")
    }
  }
  
  var shouldSendToServer: Bool {
    get {
      UserDefaults.standard.bool(forKey: "network:should-send") ?? false
    }
    set {
      UserDefaults.standard.set(newValue, forKey: "network:should-send")
    }
  }
  
}
