//
//  ViewController.swift
//  Example
//
//  Created by Tomoya Hirano on 2020/04/02.
//  Copyright © 2020 Tomoya Hirano. All rights reserved.
//

import UIKit
import CoreML
import AVFoundation

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, TrackerDelegate {
  
  private static let IS_3D = false
  
  @IBOutlet weak var imageView: UIImageView!
  @IBOutlet weak var toggleView: UISwitch!
  var previewLayer: AVCaptureVideoPreviewLayer!
  @IBOutlet weak var xyLabel:UILabel!
  @IBOutlet weak var featurePoint: UIView!
  let camera = Camera()
  let tracker: HandTracker = HandTracker()!
  
  var model: unclassified2d?
  var buffer = [[Float32]]()
  
  private func createEmptyFrame() -> [Float32] {
    if Self.IS_3D {
      return [Float32](repeating: 0, count: 21 * 3)
    } else {
      return [Float32](repeating: 0, count: 21 * 2)
    }
  }
    
    
  override func viewDidLoad() {
    super.viewDidLoad()
    camera.setSampleBufferDelegate(self)
    camera.start()
    tracker.startGraph()
    tracker.delegate = self
    
    self.xyLabel.backgroundColor = .white
    
    self.model = try? unclassified2d()
    print(self.model)
    print("here")
  }
    
  func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
    tracker.processVideoFrame(pixelBuffer)

    DispatchQueue.main.async {
//      if !self.toggleView.isOn {
      self.imageView.image = UIImage(ciImage: CIImage(cvPixelBuffer: pixelBuffer!))
//      }
    }
  }
    
    func handTracker(_ handTracker: HandTracker!, didOutputLandmarks landmarks: [Landmark]!, andHand handSize: CGSize) {
      
      guard handSize.width > 0.001 else { return }
      print(handSize)
      
      // Add to buffer
      let frame: [Float32] = landmarks
        .compactMap { lm -> [Float32] in
          if Self.IS_3D {
            return [1 - lm.x, lm.y, lm.z]
          } else {
            return [1 - lm.x, lm.y]
          }
          
        }
        .reduce([], +)
      
      self.buffer.append(frame + createEmptyFrame())
      
      if self.buffer.count == 10 {
        var shape: [NSNumber] {
          if Self.IS_3D {
            return [1, 10, 126]
          } else {
            return [1, 10, 84]
          }
        }
        
        if let bufferInput = try? MLMultiArray(shape: shape, dataType: .float32) {
          for (fidx, frame) in self.buffer.enumerated() {
            for (vidx, frameValue) in frame.enumerated() {
              bufferInput[[0,fidx, vidx] as [NSNumber]] = frameValue as NSNumber
            }
          }
          
          if let output = try? self.model?.prediction(lstm_input: bufferInput) {
            let label = output.classLabel
            print("\(label) - \(output.Identity[label])")
          }
        }
      }
      
      if self.buffer.count == 10 {
        _ = self.buffer.removeFirst()
      }
    }
    
    func handTracker(_ handTracker: HandTracker!, didOutputPixelBuffer pixelBuffer: CVPixelBuffer!) {
//        DispatchQueue.main.async {
//            if self.toggleView.isOn {
//                self.imageView.image = UIImage(ciImage: CIImage(cvPixelBuffer: pixelBuffer))
//            }
//        }
    }
}

extension Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

extension CGFloat {
    func ceiling(toDecimal decimal: Int) -> CGFloat {
        let numberOfDigits = CGFloat(abs(pow(10.0, Double(decimal))))
        if self.sign == .minus {
            return CGFloat(Int(self * numberOfDigits)) / numberOfDigits
        } else {
            return CGFloat(ceil(self * numberOfDigits)) / numberOfDigits
        }
    }
}

extension Double {
    func ceiling(toDecimal decimal: Int) -> Double {
        let numberOfDigits = abs(pow(10.0, Double(decimal)))
        if self.sign == .minus {
            return Double(Int(self * numberOfDigits)) / numberOfDigits
        } else {
            return Double(ceil(self * numberOfDigits)) / numberOfDigits
        }
    }
}
