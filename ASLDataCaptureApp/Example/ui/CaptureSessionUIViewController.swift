  //
//  CaptureSessionUIViewController.swift
//  Example
//
//  Created by Etienne Goulet-Lang on 4/29/22.
//  Copyright © 2022 Tomoya Hirano. All rights reserved.
//

import Foundation
import UIKit
import CoreML
import AVFoundation

protocol CaptureSessionUIViewControllerDelegate: NSObjectProtocol {
  func sessionComplete(_ sessionInfo: CaptureSessionInformation!)
}

class SessionManager {
  
  private(set) var shouldCollect: Bool = false
  
  func start() {
    shouldCollect = true
//    AudioServicesPlaySystemSound(SystemSoundID(1110))
  }
  
  func end(shouldReschedule: Bool) {
    shouldCollect = false
//    AudioServicesPlaySystemSound(SystemSoundID(1112))
    if shouldReschedule {
      DispatchQueue
        .global()
        .asyncAfter(deadline: DispatchTime.now() ) { [weak self] in
          self?.start()
      }
    }
  }
}


class CaptureSessionUIViewController: BaseSessionUIViewController {
  fileprivate var dataframeBuffer = [[Float]]()
  private var sessionManager = SessionManager()
  
  private let sampleLabel = UILabel(frame: .zero)
  
  public weak var sessionDelegate: CaptureSessionUIViewControllerDelegate?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.view.addSubview(sampleLabel)
    self.sampleLabel.textAlignment = .center
    self.sampleLabel.font = UIFont.systemFont(ofSize: 20)
    self.sampleLabel.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.4)
    
    
    DispatchQueue.global().asyncAfter(deadline: .now() + 5) { [weak self] in
      self?.sessionManager.start()
    }
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()

    self.sampleLabel.frame = CGRect(x: 0, y: self.view.frame.height - 100,
                                    width: self.view.frame.width, height: 100)
  }
  
  override func handleFrame(landmarks: [Landmark], frame: [Float]) {
    guard sessionManager.shouldCollect else { return }
    self.dataframeBuffer.append(frame)
    
    if self.dataframeBuffer.count == sessionInfo.dataframeSize {
      sessionInfo.dataframes.append(self.dataframeBuffer)
      self.dataframeBuffer = []
      self.sessionManager.end(shouldReschedule: !sessionInfo.isSessionOver)
      
      DispatchQueue.main.async { [weak self] in
        self?.updateSampleLabel()
      }
    }
    
    if sessionInfo.isSessionOver {
      self.sessionDelegate?.sessionComplete(self.sessionInfo)
      self.stopCapture()
    }
  }
  
  private func updateSampleLabel() {
    self.sampleLabel.text = "\(self.sessionInfo.dataframes.count) out of \(self.sessionInfo.targetNumberOfSamples)"
  }
  
}
