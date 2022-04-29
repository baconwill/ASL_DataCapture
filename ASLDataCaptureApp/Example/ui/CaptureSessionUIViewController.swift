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
  
  // MARK: - Visual Feedback Debugging
  private var sizeVal: CGFloat = 3
  private var shouldDrawDebugPoints: Bool = true
  private var pointsLayer = CAShapeLayer()
  private var viewSize = CGSize()
  
    
  
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
    
    self.view.layer.addSublayer(pointsLayer)
    pointsLayer.frame = view.frame
    pointsLayer.strokeColor = UIColor.green.cgColor
    pointsLayer.lineCap = .round
    
    camera = Camera()
    camera?.setSampleBufferDelegate(self)
    camera?.start()
    
    tracker = HandTracker()
    tracker?.startGraph()
    tracker?.delegate = self
    
    self.model = try? Model()
    
    self.viewSize = self.view.frame.size
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
  
  // MARK: - AVCapture Delegate
  
  func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
    tracker?.processVideoFrame(pixelBuffer)
    
    DispatchQueue.main.async {
      self.imageView.image = UIImage(ciImage: CIImage(cvPixelBuffer: pixelBuffer!))
    }
  }
  
  // MARK: - Hand Tracker Delegate
  
  func handTracker(
    _ handTracker: HandTracker!,
    didOutputLandmarks landmarks: [Landmark]!,
    andHand handSize: CGSize
  ) {
    self.collect(landmarks: landmarks)
    DispatchQueue.main.async { [weak self] in
      self?.drawDebugPoints(landmarks: landmarks)
    }
  }
  
  func handTracker(
    _ handTracker: HandTracker!,
    didOutputPixelBuffer pixelBuffer: CVPixelBuffer!
  ) {
    
  }
  
  // MARK: Data Collection
  private func collect(landmarks: [Landmark]) {
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
  
  // MARK: - Debug Points
  
  private func drawDebugPoints(landmarks: [Landmark]) {
    guard shouldDrawDebugPoints else { return }
    var displayedPoints: [CGPoint] = []
    var z_vals: [CGFloat] = []
    
    for (_, lm) in landmarks.enumerated()
    {
//            print("\(num): (\(lm.x), \(lm.y)")
//            print("w: \(w), h: \(h)")
      let x = CGFloat(lm.x) * self.view.frame.size.width
      let y = CGFloat(lm.y) * self.view.frame.size.height
      let point = CGPoint(x: x, y: y)
      displayedPoints.append(point)
      let z = CGFloat(lm.z)
//            let zf = Float32(lm.z)
//            print("CGFloat: \(z), Float32: \(zf)")
      z_vals.append(z)
    }
    
    let combinedPath = CGMutablePath()
    for (_, point) in displayedPoints.enumerated() {
      let rect = CGRect(x: point.x, y: point.y, width: sizeVal, height: sizeVal)
      let dotPath = UIBezierPath(ovalIn: rect)
      combinedPath.addPath(dotPath.cgPath)
    }
    pointsLayer.path = combinedPath
    self.pointsLayer.didChangeValue(for: \.path)
  }
  
}

//CaptureSessionInformation
