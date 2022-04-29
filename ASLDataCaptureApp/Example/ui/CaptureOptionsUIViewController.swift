//
//  CaptureOptionsUIViewController.swift
//  Example
//
//  Created by Etienne Goulet-Lang on 4/29/22.
//  Copyright © 2022 Tomoya Hirano. All rights reserved.
//

import Foundation
import UIKit

private class CollectParameterUIView: UIView {
  
  private static let LABEL_TO_TEXTFIELD_MARGIN: CGFloat = 8
  
  private let labelView = UILabel(frame: .zero)
  private let textView = UITextField(frame: .zero)
  
  convenience init(label: String) {
    self.init(frame: .zero)
    
    self.addSubview(labelView)
    self.labelView.text = label
    
    self.addSubview(textView)
    self.textView.layer.cornerRadius = 4
    self.textView.layer.borderWidth = 1
    self.textView.layer.borderColor = UIColor.systemGray.cgColor
    
    self.textView.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: 10))
    self.textView.leftViewMode = .always
  }
  
  var text: String? {
    return textView.text
  }
  
  var placeholder: String = "" {
    didSet {
      self.textView.placeholder = self.placeholder
    }
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    
    let availableSize = CGSize(width: .greatestFiniteMagnitude, height: self.frame.height)
    let requiredLabelWidth = self.labelView.sizeThatFits(availableSize).width
    
    self.labelView.frame = CGRect(x: 0, y: 0, width: requiredLabelWidth, height: self.frame.height)
    let textViewWidth = self.frame.width - requiredLabelWidth - Self.LABEL_TO_TEXTFIELD_MARGIN
    self.textView.frame = CGRect(x: self.frame.width - textViewWidth, y: 0, width: textViewWidth, height: self.frame.height)
  }
  
  @discardableResult
  override func resignFirstResponder() -> Bool {
    if self.textView.isFirstResponder {
      return self.textView.resignFirstResponder()
    }
    return super.resignFirstResponder()
  }
}

final class CaptureOptionsUIViewController: UIViewController, CaptureSessionUIViewControllerDelegate {
  
  // MARK: - UI Definition

  private let contentView = UIView(frame: .zero)
  
  // MARK: Sampling Information
  private let samplingTitleLabel = UILabel(frame: .zero)
  private let samplingLabelCollectionView = CollectParameterUIView(label: "Model Label:")
  private let samplingCountCollectionView = CollectParameterUIView(label: "Number of Samples:")
  
  private let startButton = UIButton(frame: .zero)
  
  // MARK: - UI Initialization
  
  private func configureSectionTitleView(label: UILabel) {
    label.backgroundColor = .systemBackground
    label.font = UIFont.systemFont(ofSize: Constants.SECTION_FONT_SIZE)
  }
  
  private func createContentView() {
    self.view.addSubview(contentView)
    
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleContentViewTapped))
    contentView.addGestureRecognizer(tapGesture)
    contentView.isUserInteractionEnabled = true
  }
  
  private func createSamplingInformation() {
    self.contentView.addSubview(samplingTitleLabel)
    self.configureSectionTitleView(label: samplingTitleLabel)
    samplingTitleLabel.text = "Sampling Information"
    
    self.contentView.addSubview(samplingLabelCollectionView)
    samplingLabelCollectionView.placeholder = "eg. A, B, C"
    
    self.contentView.addSubview(samplingCountCollectionView)
    samplingCountCollectionView.placeholder = "eg. 1, 10, 100"
  }
  
  private func createStartButton() {
    self.contentView.addSubview(startButton)
    startButton.backgroundColor = .systemGreen
    startButton.setTitle("Start Collecting Samples", for: .normal)
    startButton.addTarget(self, action: #selector(handleStartButtonTapped), for: .touchUpInside)
    startButton.layer.cornerRadius = 12
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.view.backgroundColor = .systemBackground
    self.createContentView()
    self.createSamplingInformation()
    self.createStartButton()
  }
  
  // MARK: - UI Frame Updates
  
  private func setSectionTitleFrame(section: UILabel, yOffset: inout CGFloat) {
    section.frame = CGRect(x: 0, y: yOffset,
                           width: self.contentView.bounds.width,
                           height: Constants.SECTION_TITLE_HEIGHT)
    yOffset += Constants.SECTION_TITLE_HEIGHT
  }
  
  private func setCollectionViewFrame(collect: CollectParameterUIView, yOffset: inout CGFloat) {
    collect.frame = CGRect(x: 0, y: yOffset,
                           width: self.contentView.bounds.width,
                           height: Constants.TEXT_FIELD_HEIGHT).insetBy(dx: 8, dy: 0)
    yOffset += Constants.TEXT_FIELD_HEIGHT
  }
  
  private func updateContentViewFrame() {
    self.contentView.frame = self.view.safeFrame.insetBy(
      dx: Constants.CONTENT_VIEW_MARGIN.width ,
      dy: Constants.CONTENT_VIEW_MARGIN.height
    )
  }
  
  private func updateSampleInformationFrames(yOffset: inout CGFloat) {
    self.setSectionTitleFrame(section: self.samplingTitleLabel, yOffset: &yOffset)
    yOffset += 8
    self.setCollectionViewFrame(collect: self.samplingLabelCollectionView, yOffset: &yOffset)
    yOffset += 8
    self.setCollectionViewFrame(collect: self.samplingCountCollectionView, yOffset: &yOffset)
  }
  
  private func updateStartButtonFrame() {
    
    let xOffset = (self.contentView.frame.width - Constants.BUTTON_SIZE.width) / 2
    let yOffset = self.contentView.frame.height - Constants.BUTTON_SIZE.height
    self.startButton.frame = CGRect(x: xOffset, y: yOffset, width: Constants.BUTTON_SIZE.width, height: Constants.BUTTON_SIZE.height)
  }
  
  // MARK: - View Controller LifeCycle
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.updateContentViewFrame()
    
    var yOffset: CGFloat = 0 // Tracks the Y offset when layout the current component
    self.updateSampleInformationFrames(yOffset: &yOffset)
    
    self.updateStartButtonFrame()
  }
  
  // MARK: - Handle Interaction
  @objc func handleContentViewTapped() {
    [
      self.samplingLabelCollectionView,
      self.samplingCountCollectionView
    ]
    .forEach { $0.resignFirstResponder()}
  }
  
  @objc func handleStartButtonTapped() {
    guard let modelLabel = self.samplingLabelCollectionView.text, !modelLabel.isEmpty else {
      let alertController = Self.createAlertView(
        title: "Missing Model Label",
        msg: "You must specify a label for the data you are about to collect")
      self.present(alertController, animated: true)
      return
    }
    
    guard
      let targetNumberofSamples = self.samplingCountCollectionView.text,
      let targetNumberofSamplesInt = Int(targetNumberofSamples)
    else {
      let alertController = Self.createAlertView(
        title: "Number of Samples",
        msg: "You must specify the number of samples you want to collect")
      self.present(alertController, animated: true)
      return
    }
    
    let captureSessionInformation = CaptureSessionInformation(
      ngrok: "f8fb-75-85-187-237",
      label: modelLabel,
      targetNumberOfSamples: targetNumberofSamplesInt
    )
    
    let vc = CaptureSessionUIViewController(sessionInfo: captureSessionInformation)
    vc.sessionDelegate = self
    self.present(vc, animated: true)
  }
  
  func sessionComplete(_ sessionInfo: CaptureSessionInformation!) {
    return
    print("call network stack here")
    print(sessionInfo.dataframes.count)
    print("here")
    
//    print(sessionInfo.dataframes)
    
    
    // prepare json data
    let json: [String: Any] = [
      sessionInfo.label: sessionInfo.dataframes
    ]
    
    let jsonData = try? JSONSerialization.data(withJSONObject: json)
    
    // create post request
    let url = URL(string: "https://\(sessionInfo.ngrok).ngrok.io/save")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    
    // insert json data to the request
    request.httpBody = jsonData
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
      guard let data = data, error == nil else {
        print(error?.localizedDescription ?? "No data")
        return
      }
      let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
      if let responseJSON = responseJSON as? [String: Any] {
        print(responseJSON)
      }
    }
    
    task.resume()
    
  }
  
}

private struct Constants {
  static let CONTENT_VIEW_MARGIN = CGSize(width: 12, height: 0)
  static let SECTION_FONT_SIZE: CGFloat = 20
  static let SECTION_TITLE_HEIGHT: CGFloat = 32
  
  static let TEXT_FIELD_HEIGHT: CGFloat = 44
  
  static let BUTTON_SIZE = CGSize(width: 240, height: 60)
}

extension UIView {
  var safeFrame: CGRect {
    let safeWidth = self.frame.width - self.safeAreaInsets.left - self.safeAreaInsets.right
    let safeHeight = self.frame.height - self.safeAreaInsets.top - self.safeAreaInsets.bottom
    return CGRect(x: self.frame.origin.x + self.safeAreaInsets.left,
                  y: self.frame.origin.y + self.safeAreaInsets.top, width: safeWidth, height: safeHeight)
  }
}

extension UIViewController {
  
  class func createAlertView(title: String, msg: String) -> UIViewController {
    let alertController = UIAlertController(title: title, message: msg, preferredStyle: .alert)
    
    let action = UIAlertAction(title: "Ok", style: .default) { [weak alertController] _ in
      alertController?.dismiss(animated: true)
    }
    
    alertController.addAction(action)
    return alertController
  }
  
}
