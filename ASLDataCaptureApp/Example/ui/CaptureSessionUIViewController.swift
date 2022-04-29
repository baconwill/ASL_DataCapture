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

private typealias Model = unclassified2d

protocol CaptureSessionUIViewControllerDelegate: NSObjectProtocol {
  func sessionComplete(_ sessionInfo: CaptureSessionInformation!)
}


class CaptureSessionUIViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, TrackerDelegate {
  
  private var imageView = UIImageView(frame: .zero)
  
  private var sessionInfo: CaptureSessionInformation!
  
  private var camera: Camera?
  private var tracker: HandTracker?
  
  private var model: Model?
  
  private var dataframeBuffer = [[Float]]()
  
  public weak var sessionDelegate: CaptureSessionUIViewControllerDelegate? 
  
  convenience init(sessionInfo: CaptureSessionInformation) {
    self.init()
    self.sessionInfo = sessionInfo
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.view.addSubview(imageView)
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.contentMode = .scaleAspectFill
    
    NSLayoutConstraint.activate([
      self.imageView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
      self.imageView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
      self.imageView.topAnchor.constraint(equalTo: self.view.topAnchor),
      self.imageView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
    ])
    
    camera = Camera()
    camera?.setSampleBufferDelegate(self)
    camera?.start()
    
    tracker = HandTracker()
    tracker?.startGraph()
    tracker?.delegate = self
    
    self.model = try? Model()
  }
  
  private func stopCapture() {
    self.camera?.stop()
    self.camera = nil
    self.tracker?.delegate = nil
    self.tracker = nil
    
    DispatchQueue.main.async {
      self.dismiss(animated: true)
    }
  }
  
  func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
    tracker?.processVideoFrame(pixelBuffer)
    
    DispatchQueue.main.async {
      self.imageView.image = UIImage(ciImage: CIImage(cvPixelBuffer: pixelBuffer!))
    }
  }
  
  func handTracker(
    _ handTracker: HandTracker!,
    didOutputLandmarks landmarks: [Landmark]!,
    andHand handSize: CGSize
  ) {
    
    self.dataframeBuffer.append(sessionInfo.captureFrame(landmarks) + sessionInfo.createEmptyFrame())
    
    if self.dataframeBuffer.count == sessionInfo.dataframeSize {
      sessionInfo.dataframes.append(self.dataframeBuffer)
      self.dataframeBuffer = []
    }
    
    print("\(self.dataframeBuffer.count), \(sessionInfo.dataframes.count)")
    if sessionInfo.isSessionOver {
      self.sessionDelegate?.sessionComplete(self.sessionInfo)
      self.stopCapture()
    }
  }
  
  func handTracker(
    _ handTracker: HandTracker!,
    didOutputPixelBuffer pixelBuffer: CVPixelBuffer!
  ) {
    
  }
  
  
}

//CaptureSessionInformation
