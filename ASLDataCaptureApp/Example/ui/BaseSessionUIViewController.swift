//
//  BaseSessionUIViewController.swift
//  Example
//
//  Created by Etienne Goulet-Lang on 5/3/22.
//  Copyright © 2022 Tomoya Hirano. All rights reserved.
//

import Foundation
import UIKit
import CoreML
import AVFoundation

class BaseSessionUIViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, TrackerDelegate {
  
  // MARK: - Constructors & Constants
  
  convenience init(sessionInfo: CaptureSessionInformation) {
    self.init()
    self.sessionInfo = sessionInfo
  }
  
  // MARK: - UIImageView
  
  var imageView = UIImageView(frame: .zero)
  
  // MARK: UIImageView Properties
  
  var currentImageViewWidth: CGFloat?
  
  var imageToViewScale: CGFloat? {
    guard let image = self.imageView.image else { return nil }
    
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
    
    return nil
  }
  
  // MARK: - Capture Session
  
  var sessionInfo: CaptureSessionInformation! // Set by the constructor
  
  // MARK: - Do Work
  private var isHandlingFrame = false
  
  // MARK: - Debug
  var shouldDrawLandmarks: Bool {
    return true
  }
  private var landmarksPointsLayer = CAShapeLayer()
  
  var shouldDrawFrame: Bool {
    return true
  }
  private var framePointsLayer = CAShapeLayer()
  
  // MARK: - ViewController Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.view.addSubview(imageView)
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.contentMode = .scaleAspectFill
    self.imageView.alpha = 0.1
    NSLayoutConstraint.activate([
      self.imageView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
      self.imageView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
      self.imageView.topAnchor.constraint(equalTo: self.view.topAnchor),
      self.imageView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
    ])
    
    view.layer.addSublayer(landmarksPointsLayer)
    landmarksPointsLayer.frame = view.frame
    landmarksPointsLayer.strokeColor = UIColor.green.cgColor
    landmarksPointsLayer.lineCap = .round
    
    view.layer.addSublayer(framePointsLayer)
    framePointsLayer.frame = view.frame
    framePointsLayer.strokeColor = UIColor.red.cgColor
    framePointsLayer.lineCap = .round
    
    self.startCapture()
  }
  
  // MARK: - Capture Sessioin Interface
  
  func startCapture() {
    CameraManager.shared.camera.setSampleBufferDelegate(self)
    CameraManager.shared.camera.start()
    CameraManager.shared.tracker.delegate = self
  }
  
  func stopCapture() {
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
      self.currentImageViewWidth = self.imageView.image?.size.width
    }
  }
  
  // MARK: - Hand Tracker Delegate
  
  func handTracker(
    _ handTracker: HandTracker!,
    didOutputLandmarks landmarks: [Landmark]!,
    andHand handSize: CGSize
  ) {
    guard !isHandlingFrame else { return }
    isHandlingFrame = true
    DispatchQueue.global().async { [weak self] in
      self?.handleLandmarks(landmarks: landmarks)
      self?.isHandlingFrame = false
    }
  }
  
  func handTracker(_ handTracker: HandTracker!, didOutputPixelBuffer pixelBuffer: CVPixelBuffer!) {}
  
  func handleLandmarks(landmarks: [Landmark]) {
    self.drawLandmarks(landmarks: landmarks)
    switch sessionInfo.transformData(landmarks, currentImageWidth: self.currentImageViewWidth) {
    case .some(let frame):
      self.handleFrame(landmarks: landmarks, frame: frame)
      self.drawFrame(frame: frame)
    case .none:
      self.handleNoFrame(landmarks: landmarks)
      self.drawFrame(frame: [])
    }
  }
  
  func handleFrame(landmarks: [Landmark], frame: [Float]) {
    
  }
  
  func handleNoFrame(landmarks: [Landmark]) {
    
  }
  
  func drawFrame(frame: [Float]) {
    guard shouldDrawFrame else { return }
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      guard let image = self.imageView.image else { return }
      guard let imageToViewScale = self.imageToViewScale else { return }
      
      let combinedPath = CGMutablePath()
      
      frame
        .chunked(into: 3)
        .compactMap { points -> CGRect? in
          guard points.count == 3 else { return nil }
          
          let x = points[0]
          let y = points[1]
          let z = points[2]
          
          guard x != 0 || y != 0 else { return nil }
          
          let x_transformed = (CGFloat(x) * image.size.width) / imageToViewScale + 20
          let y_transformed = (CGFloat(y) * image.size.height) / imageToViewScale + 40

          return CGRect(x: x_transformed, y: y_transformed, width: 3, height: 3)
        }
        .forEach { rect in
          let dotPath = UIBezierPath(ovalIn: rect)
          combinedPath.addPath(dotPath.cgPath)
        }
      
      self.framePointsLayer.path = combinedPath
      self.framePointsLayer.didChangeValue(for: \.path)
    }
  }
  
  private func drawLandmarks(landmarks: [Landmark]) {
    guard shouldDrawLandmarks else { return }
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      guard let image = self.imageView.image else { return }
      guard let imageToViewScale = self.imageToViewScale else { return }
    
    
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
          return CGRect(x: x, y: y, width: 3, height: 3)
        }
        .forEach { rect in
          let dotPath = UIBezierPath(ovalIn: rect)
          combinedPath.addPath(dotPath.cgPath)    
        }
      
      self.landmarksPointsLayer.path = combinedPath
      self.landmarksPointsLayer.didChangeValue(for: \.path)
    }
  }
}


extension Array {
  // split array into chunks of n
  func chunked(into size: Int) -> [[Element]] {
    return stride(from: 0, to: count, by: size).map {
      Array(self[$0 ..< Swift.min($0 + size, count)])
    }
  }
}
