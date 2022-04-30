//
//  CaptureSessionInformation.swift
//  Example
//
//  Created by Etienne Goulet-Lang on 4/29/22.
//  Copyright © 2022 Tomoya Hirano. All rights reserved.
//

import Foundation

public struct CaptureSessionInformation {
  
  var label: String
  var targetNumberOfSamples: Int
  
  // Where to place the samples
  var dataframeSize = 10 // 10 samples per dataframe
  var shouldMirrorX = true
  var is3d = true
  var dataframes: [
    [[Float]]   
  ] = []
  
  func captureFrame(_ landmarks: [Landmark]) -> [Float32] {
    return landmarks
      .compactMap { lm -> [Float32] in
        let x = shouldMirrorX ? (1 - lm.x) : lm.x
        if is3d {
          return [x, lm.y, lm.z]
        } else {
          return [x, lm.y]
        }
        
      }
      .reduce([], +)
  }
  
  func createEmptyFrame(_ numberOfLandmarks: Int = 21) -> [Float32] {
    if self.is3d {
      return [Float32](repeating: 0, count: numberOfLandmarks * 3)
    } else {
      return [Float32](repeating: 0, count: numberOfLandmarks * 2)
    }
  }
  
  var isSessionOver: Bool {
    return self.dataframes.count >= self.targetNumberOfSamples
  }
  
}
