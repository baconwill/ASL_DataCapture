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

class ClassifySessionUIViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, TrackerDelegate {
  
  private var imageView = UIImageView(frame: .zero)
  private var currentImageViewWidth: CGFloat?
  
  private var sessionInfo: CaptureSessionInformation!
  
  private let model = try! Model()
  
  private var isClassifying = false
  
  // MARK: - Transform Input Data
  private var shouldTranslateInputData: Bool = true
  private static let factor: Float = 100
  
  fileprivate var dataframeBuffer = [[Float]]()
  
  private let sampleLabel = UILabel(frame: .zero)
  
  convenience init(sessionInfo: CaptureSessionInformation) {
    self.init()
    self.sessionInfo = sessionInfo
  }
  
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
    
    CameraManager.shared.camera.setSampleBufferDelegate(self)
    CameraManager.shared.camera.start()
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
      self.currentImageViewWidth = self.imageView.image?.size.width
    }
  }
  
  // MARK: - Hand Tracker Delegate
  
  func handTracker(
    _ handTracker: HandTracker!,
    didOutputLandmarks landmarks: [Landmark]!,
    andHand handSize: CGSize
  ) {
    guard !isClassifying else { return }
    isClassifying = true
    DispatchQueue.global().async { [weak self] in
      self?.classify(landmarks: landmarks)
      self?.isClassifying = false
    }
  }
  
  func handTracker(
    _ handTracker: HandTracker!,
    didOutputPixelBuffer pixelBuffer: CVPixelBuffer!
  ) {
    
  }
  
  // MARK: Data Collection
  private func transformData(landmarks: [Landmark]) -> [Float]? {
    guard shouldTranslateInputData else { return self.defaultDataTransformation(landmarks: landmarks) }
    
    guard let imageWidth = self.currentImageViewWidth else { return nil }
    
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
          round(Self.factor * scaleFactor * (lm.x - left)) / Self.factor,
          round(Self.factor * scaleFactor * (lm.y - top)) / Self.factor,
          0
        ]
      }
      .reduce([], +)
    
    return translatedLandmarks + sessionInfo.createEmptyFrame()
    
  }
  
  private func defaultDataTransformation(landmarks: [Landmark]) -> [Float]? {
    return sessionInfo.captureFrame(landmarks) + sessionInfo.createEmptyFrame()
  }
  
  private func classify(landmarks: [Landmark]) {
    guard let dataframe = transformData(landmarks: landmarks) else {
      DispatchQueue.main.async {
        self.showDebugLabel(label: "None", conf: 0)
      }
      return
    }
    
    self.dataframeBuffer.append(dataframe)
    
    if self.dataframeBuffer.count == sessionInfo.dataframeSize {
      self.guess()
      self.dataframeBuffer.removeFirst()
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
