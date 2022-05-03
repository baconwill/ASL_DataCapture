//
//  CaptureOptionsUIViewController.swift
//  Example
//
//  Created by Etienne Goulet-Lang on 4/29/22.
//  Copyright © 2022 Tomoya Hirano. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

private class BaseCollectParameterUIView<CollectionView: UIView>: UIView {
  
  var spacing: CGFloat {
    return 12
  }
  
  var shouldAddBorder: Bool {
    return true
  }
  
  let labelView = UILabel(frame: .zero)
  let collectionView = CollectionView(frame: .zero)
  
  convenience init(label: String) {
    self.init(frame: .zero)
    
    if self.shouldAddBorder {
      self.layer.cornerRadius = 4
      self.layer.borderWidth = 1
      self.layer.borderColor = UIColor.systemGray.cgColor
    }
    
    self.addSubview(labelView)
    self.labelView.text = label
    
    self.addSubview(collectionView)
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    
    let availableSize = CGSize(width: .greatestFiniteMagnitude, height: self.frame.height)
    let requiredLabelWidth = self.labelView.sizeThatFits(availableSize).width
    
    self.labelView.frame = CGRect(x: self.spacing, y: 0,
                                  width: requiredLabelWidth, height: self.frame.height)
    let textViewWidth = self.frame.width - requiredLabelWidth - 2 * self.spacing
    self.setCollectionFrame(suggestedWidth: textViewWidth)
  }
  
  func setCollectionFrame(suggestedWidth: CGFloat) {
    self.collectionView.frame = CGRect(x: self.frame.width - suggestedWidth,
                                       y: 0, width: suggestedWidth, height: self.frame.height)
  }
  
  func contains(_ collectionView: CollectionView) -> Bool {
    return collectionView === self.collectionView
  }
  
  @discardableResult
  override func resignFirstResponder() -> Bool {
    if self.collectionView.isFirstResponder {
      return self.collectionView.resignFirstResponder()
    }
    return super.resignFirstResponder()
  }
  
}

private class CollectBoolParameterUIView: BaseCollectParameterUIView<UISwitch> {
  
  override var spacing: CGFloat {
     return 0
  }
  
  override var shouldAddBorder: Bool {
    return false
  }
  
  var isOn: Bool {
    get {
      return collectionView.isOn
    }
    set {
      collectionView.setOn(newValue, animated: false)
    }
  }

  func addTarget(_ target: Any?, action: Selector, for event: UIControl.Event) {
    self.collectionView.addTarget(target, action: action, for: event)
  }

  override func setCollectionFrame(suggestedWidth: CGFloat) {
    let yOffset = (self.frame.height - self.collectionView.frame.height) / 2
    let xOffset = self.frame.width - self.collectionView.frame.width - self.spacing
    self.collectionView.frame.origin = CGPoint(x: xOffset, y: yOffset)
  }
}

private class CollectTextParameterUIView: BaseCollectParameterUIView<UITextField> {

  var text: String? {
    get {
      return collectionView.text
    }
    set {
      self.collectionView.text = newValue
    }
  }
  
  var placeholder: String = "" {
    didSet {
      self.collectionView.placeholder = self.placeholder
    }
  }
  
  func addTarget(_ target: Any?, action: Selector, for event: UIControl.Event) {
    collectionView.addTarget(target, action: action, for: event)
  }
  
}

final class CaptureOptionsUIViewController: UIViewController, CaptureSessionUIViewControllerDelegate {
  
  // MARK: - UI Definition

  private let contentView = UIView(frame: .zero)
  
  // MARK: Sampling Information
  private let samplingTitleLabel = UILabel(frame: .zero)
  private let samplingLabelCollectionView = CollectTextParameterUIView(label: "Model Label:")
  private let samplingCountCollectionView = CollectTextParameterUIView(label: "Number of Samples:")
  
  // MARK: Network Information
  private let networkTitleLabel = UILabel(frame: .zero)
  private let sendToNetworkCollectionView = CollectBoolParameterUIView(label: "Send to server:")
  private let ngrokCollectionView = CollectTextParameterUIView(label: "ngrok:")
  
  private let startButton = UIButton(frame: .zero)
  private let classifyButton = UIButton(frame: .zero)
  
  
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
  
  private func createNetworkInformation() {
    self.contentView.addSubview(networkTitleLabel)
    self.configureSectionTitleView(label: networkTitleLabel)
    networkTitleLabel.text = "Network Information"
    
    self.contentView.addSubview(sendToNetworkCollectionView)
    sendToNetworkCollectionView.isOn = CaptureSessionParameterStore.shared.shouldSendToServer
    sendToNetworkCollectionView.addTarget(self, action: #selector(switchValueDidChange), for: .valueChanged)
    
    self.contentView.addSubview(ngrokCollectionView)
    ngrokCollectionView.placeholder = "eg. f1f4-75-85-187-237"
    ngrokCollectionView.text = CaptureSessionParameterStore.shared.ngrok
    ngrokCollectionView.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
    
    updateNetworkUIBaseOnState()
  }
  
  private func createStartButton() {
    self.contentView.addSubview(startButton)
    startButton.backgroundColor = .systemGreen
    startButton.setTitle("Start Collecting Samples", for: .normal)
    startButton.addTarget(self, action: #selector(handleStartButtonTapped), for: .touchUpInside)
    startButton.layer.cornerRadius = 12
  }
  
  private func createClassifyButton() {
    self.contentView.addSubview(classifyButton)
    classifyButton.backgroundColor = .systemBlue
    classifyButton.setTitle("Start Classifying", for: .normal)
    classifyButton.addTarget(self, action: #selector(handleClassifyButtonTapped), for: .touchUpInside)
    classifyButton.layer.cornerRadius = 12
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.view.backgroundColor = .systemBackground
    self.createContentView()
    self.createSamplingInformation()
    self.createNetworkInformation()
    self.createStartButton()
    self.createClassifyButton()
  }
  
  // MARK: - UI State
  
  private func updateNetworkUIBaseOnState() {
    if CaptureSessionParameterStore.shared.shouldSendToServer {
      ngrokCollectionView.alpha = 1
    } else {
      ngrokCollectionView.alpha = 0.5
    }
  }
  
  // MARK: - UI Frame Updates
  
  private func setSectionTitleFrame(section: UILabel, yOffset: inout CGFloat) {
    section.frame = CGRect(x: 0, y: yOffset,
                           width: self.contentView.bounds.width,
                           height: Constants.SECTION_TITLE_HEIGHT)
    yOffset += Constants.SECTION_TITLE_HEIGHT
  }
  
  private func setCollectionViewFrame<T: UIView>(collect: BaseCollectParameterUIView<T>, yOffset: inout CGFloat) {
    collect.frame = CGRect(x: 0, y: yOffset,
                           width: self.contentView.bounds.width,
                           height: Constants.TEXT_FIELD_HEIGHT)
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
  
  private func updateNetworkInformationFrames(yOffset: inout CGFloat) {
    self.setSectionTitleFrame(section: self.networkTitleLabel, yOffset: &yOffset)
    yOffset += 8
    self.setCollectionViewFrame(collect: self.sendToNetworkCollectionView, yOffset: &yOffset)
    yOffset += 8
    self.setCollectionViewFrame(collect: self.ngrokCollectionView, yOffset: &yOffset)
  }
  
  private func updateStartButtonFrame() {
    let xOffset = (self.contentView.frame.width - Constants.BUTTON_SIZE.width) / 2
    let yOffset = self.contentView.frame.height - Constants.BUTTON_SIZE.height
    self.startButton.frame = CGRect(x: xOffset, y: yOffset, width: Constants.BUTTON_SIZE.width, height: Constants.BUTTON_SIZE.height)
  }
  
  private func updateClassifyButtonFrame() {
    let xOffset = (self.contentView.frame.width - Constants.BUTTON_SIZE.width) / 2
    let yOffset = self.contentView.frame.height - Constants.BUTTON_SIZE.height - Constants.BUTTON_SIZE.height - 8
    self.classifyButton.frame = CGRect(x: xOffset, y: yOffset, width: Constants.BUTTON_SIZE.width, height: Constants.BUTTON_SIZE.height)
  }
  
  // MARK: - View Controller LifeCycle
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.updateContentViewFrame()
    
    var yOffset: CGFloat = 0 // Tracks the Y offset when layout the current component
    self.updateSampleInformationFrames(yOffset: &yOffset)
    yOffset += 16
    self.updateNetworkInformationFrames(yOffset: &yOffset)
    self.updateStartButtonFrame()
    self.updateClassifyButtonFrame()
  }
  
  // MARK: - Handle Interaction
  @objc func textFieldDidChange(_ sender: UITextField) {
    if self.ngrokCollectionView.contains(sender),
       let ngrok = sender.text {
      CaptureSessionParameterStore.shared.ngrok = ngrok
    }
  }
  
  @objc func switchValueDidChange(_ sender: UISwitch) {
    if self.sendToNetworkCollectionView.contains(sender) {
      CaptureSessionParameterStore.shared.shouldSendToServer = sender.isOn
      updateNetworkUIBaseOnState()
      self.view.setNeedsLayout()
    }
  }
  
  @objc func handleContentViewTapped() {
    [
      self.samplingLabelCollectionView,
      self.samplingCountCollectionView,
      self.ngrokCollectionView,
    ]
    .forEach { $0.resignFirstResponder()}
  }
  
  @objc func handleClassifyButtonTapped() {
    let captureSessionInformation = CaptureSessionInformation(
      label: "",
      targetNumberOfSamples: 1000
    )
    
    let vc = ClassifySessionUIViewController(sessionInfo: captureSessionInformation)
    vc.modalPresentationStyle = .fullScreen
    self.present(vc, animated: true)
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
    
    // Do we have the proper ngrok information
    if CaptureSessionParameterStore.shared.shouldSendToServer {
      // if we are planning to send it to the server validate the ngrok parameter
      guard let ngrok = self.ngrokCollectionView.text, !ngrok.isEmpty else {
        let alertController = Self.createAlertView(
          title: "Missing Ngrok",
          msg: "You must specify the data collection server")
        self.present(alertController, animated: true)
        return
      }
    }
    
    
    
    let captureSessionInformation = CaptureSessionInformation(
      label: modelLabel,
      targetNumberOfSamples: targetNumberofSamplesInt
    )
    
    let vc = CaptureSessionUIViewController(sessionInfo: captureSessionInformation)
    vc.modalPresentationStyle = .fullScreen
    vc.sessionDelegate = self
    self.present(vc, animated: true)
  }
  
  func sessionComplete(_ sessionInfo: CaptureSessionInformation!) {
    let ngrok = CaptureSessionParameterStore.shared.ngrok
    guard CaptureSessionParameterStore.shared.shouldSendToServer else { return }
    
    let label = sessionInfo.label
    let count = sessionInfo.dataframes.count
    
    // prepare json data
    let json: [String: Any] = [
      sessionInfo.label: sessionInfo.dataframes
    ]
    
    let jsonData = try? JSONSerialization.data(withJSONObject: json)
    
    // create post request
    let url = URL(string: "https://\(ngrok).ngrok.io/save")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    
    // insert json data to the request
    request.httpBody = jsonData
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
      if let err = error {
        DispatchQueue.main.async {
          let alertController = Self.createAlertView(
            title: "Oops!",
            msg: "Something went wrong: \(err.localizedDescription)")
          self.present(alertController, animated: true)
        }
        return
      }
      
      guard let data = data else {
        DispatchQueue.main.async {
          let alertController = Self.createAlertView(
            title: "Oops!",
            msg: "Something went wrong: no data in response")
          self.present(alertController, animated: true)
        }
        return
      }
      
      guard let resp = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
        DispatchQueue.main.async {
          let alertController = Self.createAlertView(
            title: "Oops!",
            msg: "Something went wrong: could not parse response")
          self.present(alertController, animated: true)
        }
        return
      }
      
      guard let status = resp["status"] as? String, status == "success" else {
        DispatchQueue.main.async {
          let alertController = Self.createAlertView(
            title: "Oops!",
            msg: "Something went wrong: server error, check python logs")
          self.present(alertController, animated: true)
        }
        return
      }
      
      DispatchQueue.main.async {
        let alertController = Self.createAlertView(
          title: "Success!",
          msg: "\(count) samples were uploaded to the server with label \"\(label)\"")
        self.present(alertController, animated: true)
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
