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

class SessionManager {
  
  private(set) var shouldCollect: Bool = false
  
  func start() {
    shouldCollect = true
    AudioServicesPlaySystemSound(SystemSoundID(1110))
  }
  
  func end(shouldReschedule: Bool) {
    shouldCollect = false
    AudioServicesPlaySystemSound(SystemSoundID(1112))
    if shouldReschedule {
      DispatchQueue
        .global()
        .asyncAfter(deadline: DispatchTime.now() ) { [weak self] in
          self?.start()
      }
    }
  }
}


class CaptureSessionUIViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, TrackerDelegate {
  
  private var imageView = UIImageView(frame: .zero)
  
  private var sessionInfo: CaptureSessionInformation!
  
  fileprivate var dataframeBuffer = [[Float]]()
  private var sessionManager = SessionManager()
  
  // MARK: - Visual Feedback Debugging
  private var sizeVal: CGFloat = 3
  private var shouldDrawDebugPoints: Bool = true
  private var pointsLayer = CAShapeLayer()
  
  private let sampleLabel = UILabel(frame: .zero)
  
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
    
    DispatchQueue.global().asyncAfter(deadline: .now() + 5) { [weak self] in
      self?.sessionManager.start()
    }
    
    CameraManager.shared.camera.setSampleBufferDelegate(self)
    CameraManager.shared.camera.start()
    
    view.layer.addSublayer(pointsLayer)
    pointsLayer.frame = view.frame
    pointsLayer.strokeColor = UIColor.green.cgColor
    pointsLayer.lineCap = .round
    
    CameraManager.shared.tracker.delegate = self
    
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
  
  private func stopCapture() {
    CameraManager.shared.camera.removeSampleBufferDelegate()
    CameraManager.shared.camera.stop()
    
    CameraManager.shared.tracker.delegate = nil
    
    DispatchQueue.main.async {
      self.dismiss(animated: true)
    }
  }
  
  // MARK: - AVCapture Delegate
  
  func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
    CameraManager.shared.tracker.processVideoFrame(pixelBuffer)
    
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
    if sessionManager.shouldCollect {
      self.collect(landmarks: landmarks)
    }
    
    DispatchQueue.main.async { [weak self] in
      self?.drawDebugPoints(landmarks: landmarks)
      self?.showDebugLabel()
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
      self.sessionManager.end(shouldReschedule: !sessionInfo.isSessionOver)
    }
    
    if sessionInfo.isSessionOver {
      self.sessionDelegate?.sessionComplete(self.sessionInfo)
      self.stopCapture()
    }
  }
  
  // MARK: - Debug Points
  
  private func drawDebugPoints(landmarks: [Landmark]) {
    guard shouldDrawDebugPoints else { return }
    guard let image = self.imageView.image else { return }
    
    // the landmarks are in the image's coordinate system
    // the task here is to convert them to the imageview's coordinate system
  
    var imageToViewScale: CGFloat {
      
      switch self.imageView.contentMode {
      case .scaleAspectFill:
        // if the contentMode is "aspectFill", meaning part of the image
        // can get cropped in order to fill the whole image view.
        //
        // This can happen in two ways:
        //  - the image is scale such that the image.width matches imageview.width
        //  OR
        //  - the image is scale such that the image.height matches imageview.height
        
        // suppose the scaling is based on the width
        var scale = image.size.width / self.imageView.bounds.width
        let imageHeightInViewCoords = image.size.height / scale
        
        if imageHeightInViewCoords >= self.imageView.bounds.height {
          // When scaled to match the width, the height will get cropped,
          // and the image will "fit" in the view completely
          return scale
        }
        
        // the sanity check here that the width is larger than the
        // imageview width when scaled based on matching the heights
        // is probably unnecessary since one of them has to work...
        // but really, why not just check
        scale =  image.size.height / self.imageView.bounds.height
        
        let imageWidthInViewCoords = image.size.width / scale
        if imageWidthInViewCoords >= self.imageView.bounds.width {
          // When scaled to match the height, the width will get cropped,
          // and the image will "fit" in the view completely
          return scale
        }
      case .scaleAspectFit:
        // if the contentMode is "aspectFit", meaning the image will be
        // displayed in its entirity, the remaineder will be transaparent
        // This can happen in two ways:
        //  - the image is scale such that the image.width matches imageview.width
        //  OR
        //  - the image is scale such that the image.height matches imageview.height
        
        // suppose the scaling is based on the width
        var scale = image.size.width / self.imageView.bounds.width
        let imageHeightInViewCoords = image.size.height / scale
        
        if imageHeightInViewCoords <= self.imageView.bounds.height {
          // When scaled to match the width, the height will not get cropped
          return scale
        }
        
        scale =  image.size.height / self.imageView.bounds.height
        let imageWidthInViewCoords = image.size.width / scale
        if imageWidthInViewCoords <= self.imageView.bounds.width {
          // When scaled to match the height, the width will not get cropped,
          return scale
        }
      default:
        break
      }
      
      return -1
    }
    
    guard imageToViewScale != -1 else { return }
    
    // Compute the offsets
    
    let xOffset = (self.imageView.bounds.width - image.size.width / imageToViewScale) / 2
    let yOffset = (self.imageView.bounds.height - image.size.height / imageToViewScale) / 2
    
    let combinedPath = CGMutablePath()
    
    landmarks
      .compactMap { lm -> CGRect in
        // The landmarks are in the image coordinate system, we want to translate them to
        // the imageview's coordinate system
        let x = (CGFloat(lm.x) * image.size.width) / imageToViewScale + xOffset
        let y = (CGFloat(lm.y) * image.size.height) / imageToViewScale + yOffset
        return CGRect(x: x, y: y, width: sizeVal, height: sizeVal)
      }
      .forEach { rect in
        let dotPath = UIBezierPath(ovalIn: rect)
        combinedPath.addPath(dotPath.cgPath)
      }
    
    pointsLayer.path = combinedPath
    self.pointsLayer.didChangeValue(for: \.path)
  }
  
  private func showDebugLabel() {
    self.sampleLabel.text = "\(self.sessionInfo.dataframes.count) out of \(self.sessionInfo.targetNumberOfSamples)"
  }
  
}

