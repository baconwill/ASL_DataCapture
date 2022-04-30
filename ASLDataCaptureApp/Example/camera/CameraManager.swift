//
//  CameraManager.swift
//  Example
//
//  Created by Etienne Goulet-Lang on 4/30/22.
//  Copyright © 2022 Tomoya Hirano. All rights reserved.
//

import Foundation

private typealias Model = unclassified2d

class CameraManager {
  
  private static let shared = CameraManager()
  
  let camera: Camera
  
  let tracker: HandTracker
  
  private init() {
    camera = Camera()
    tracker = HandTracker()
    tracker.startGraph()
  }
  
}
