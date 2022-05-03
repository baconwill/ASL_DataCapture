//
//  ClassifySessionUIViewController.swift
//  Example
//
//  Created by Etienne Goulet-Lang on 5/2/22.
//  Copyright © 2022 Tomoya Hirano. All rights reserved.
//

import Foundation
import UIKit
import CoreML
import AVFoundation

typealias Model = shitpost

class ClassifySessionUIViewController: BaseSessionUIViewController {
  
  private let model = try! Model()
  
  fileprivate var dataframeBuffer = [[Float]]()
  private let sampleLabel = UILabel(frame: .zero)
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.view.addSubview(sampleLabel)
    self.sampleLabel.textAlignment = .center
    self.sampleLabel.font = UIFont.systemFont(ofSize: 20)
    self.sampleLabel.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.4)
  }
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    
    self.sampleLabel.frame = CGRect(x: 0, y: self.view.frame.height - 100,
                                    width: self.view.frame.width, height: 100)
  }
  
  override func handleFrame(landmarks: [Landmark], frame: [Float]) {
    self.dataframeBuffer.append(frame)
    
    if self.dataframeBuffer.count == sessionInfo.dataframeSize {
      self.guess()
      self.dataframeBuffer.removeFirst()
    }
  }
  
  override func handleNoFrame(landmarks: [Landmark]) {
    DispatchQueue.main.async {
      self.showDebugLabel(label: "None", conf: 0)
    }
  }
  
  private func guess() {
    if let bufferInput = try? MLMultiArray(shape: [1, 10, 126], dataType: .float32) {
      for (fidx, frame) in self.dataframeBuffer.enumerated() {
        for (vidx, frameValue) in frame.enumerated() {
          bufferInput[[0,fidx, vidx] as [NSNumber]] = frameValue as NSNumber
        }
      }
      if let output = try? self.model.prediction(lstm_input: bufferInput) {
        let outlabel = output.classLabel
        let outprob = output.Identity[outlabel]!
        DispatchQueue.main.async {
          self.showDebugLabel(label: output.classLabel, conf: outprob)
        }
      }
    }
  }
  
  private func showDebugLabel(label: String, conf: Double) {
    let c = round(conf * 100) / 100.0
    self.sampleLabel.text = "\(label) -- \(c)"
  }
}
