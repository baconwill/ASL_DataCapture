//
//  CaptureSessionInformation.swift
//  Example
//
//  Created by Etienne Goulet-Lang on 4/29/22.
//  Copyright © 2022 Tomoya Hirano. All rights reserved.
//

import Foundation

public enum CaptureSessionInformationMode {
  case `default`
  case scaleAndTranslate
}

public struct CaptureSessionInformation {
  
  var label: String
  var targetNumberOfSamples: Int
  
  // Where to place the samples
  var mode = CaptureSessionInformationMode.scaleAndTranslate
  var dataframeSize = 10 // 10 samples per dataframe
  var shouldMirrorX = false
  var is3d = true
  var rounding: Float = 100
  
  var dataframes: [
    [[Float]]   
  ] = []
  
  func transformData(
    _ landmarks: [Landmark],
    currentImageWidth: CGFloat?
  ) -> [Float32]? {
    switch mode {
    case .`default`:
      let data = landmarks
        .compactMap { lm -> [Float32] in
          let x = shouldMirrorX ? (1 - lm.x) : lm.x
          if is3d {
            return [x, lm.y, lm.z]
          } else {
            return [x, lm.y]
          }
          
        }
        .reduce([], +)
      return data + self.createEmptyFrame()
    case .scaleAndTranslate:
      guard let imageWidth = currentImageWidth else { return nil }
      
      let left = landmarks
        .compactMap { $0.x }
        .min() ?? 0
      
      let right = landmarks
        .compactMap { $0.x }
        .max() ?? 0
      
      let top = landmarks
        .compactMap { $0.y }
        .min() ?? 0
      
      guard left > 0.001, right > 0.001, top > 0.001 else { return nil }
      
      let widthInImage = Float(imageWidth) * (right - left)
      
      guard widthInImage > 0 else { return nil }
      
      let scaleFactor = 400 / widthInImage
      
      let translatedLandmarks = landmarks
        .compactMap { lm -> [Float] in
          return [
            // todo: what do do about mirroring?
            round(self.rounding * scaleFactor * (lm.x - left)) / self.rounding,
            round(self.rounding * scaleFactor * (lm.y - top)) / self.rounding,
            0 //round(Self.factor * scaleFactor * lm.z) / Self.factor
          ]
        }
        .reduce([], +)
      
      return translatedLandmarks + self.createEmptyFrame()
    }
  }
  
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
