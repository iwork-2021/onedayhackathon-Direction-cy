//
//  PhotoViewController.swift
//  Onedayhackathon
//
//  Created by nju on 2021/12/21.
//

import UIKit
import CoreML
import Vision

protocol AddItemDelegate{
    func addItem(item:Item)
}

class PhotoViewController: UIViewController {

    
    @IBOutlet weak var photoButton: UIButton!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var resultsView: UIView!
    @IBOutlet weak var resultsLabel: UILabel!
    var firstTime = true
    var addItemDelegate:AddItemDelegate?
    var label:String = ""
    
      lazy var classificationRequest: VNCoreMLRequest = {
              do{
                  let classifier = try snacks(configuration: MLModelConfiguration())
                  let model = try VNCoreMLModel(for: classifier.model)
                  let request = VNCoreMLRequest(model: model, completionHandler: {
                      [weak self] request,error in
                      self?.processObservations(for: request, error: error)
                  })
                  request.imageCropAndScaleOption = .centerCrop
                  return request
                  
                  
              } catch {
                  fatalError("Failed to create request")
              }
          }()
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    @IBAction func choosePhoto(_ sender: Any) {
        presentPhotoPicker(sourceType: .photoLibrary)
    }
    @IBAction func done(_ sender: Any) {
        self.addItemDelegate?.addItem(item: Item(image: imageView.image!, label: label))
        self.dismiss(animated: true, completion: nil)
    }
    func presentPhotoPicker(sourceType: UIImagePickerController.SourceType) {
      let picker = UIImagePickerController()
      picker.delegate = self
      picker.sourceType = sourceType
      present(picker, animated: true)
      hideResultsView()
    }
    
    func showResultsView(delay: TimeInterval = 0.1) {
      //resultsConstraint.constant = 100
      view.layoutIfNeeded()

      UIView.animate(withDuration: 0.5,
                     delay: delay,
                     usingSpringWithDamping: 0.6,
                     initialSpringVelocity: 0.6,
                     options: .beginFromCurrentState,
                     animations: {
        self.resultsView.alpha = 1
        //self.resultsConstraint.constant = -10
        self.view.layoutIfNeeded()
      },
      completion: nil)
    }

    func hideResultsView() {
      UIView.animate(withDuration: 0.3) {
        self.resultsView.alpha = 0
      }
    }

    func classify(image: UIImage) {
        let pixelBuffer = imageToCVPixelBuffer(image: image)!
        DispatchQueue.main.async {
            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer)
            do {
                try handler.perform([self.classificationRequest])
            } catch {
                print("Failed to perform classification: \(error)")
            }
                  
          }
    }
      func imageToCVPixelBuffer(image:UIImage) -> CVPixelBuffer? {
          let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
          var pixelBuffer : CVPixelBuffer?
          let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(image.size.width), Int(image.size.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
          guard (status == kCVReturnSuccess) else {
              return nil
          }
          
          CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
          let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)
          
          let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
          let context = CGContext(data: pixelData, width: Int(image.size.width), height: Int(image.size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue)
          
          context?.translateBy(x: 0, y: image.size.height)
          context?.scaleBy(x: 1.0, y: -1.0)
          
          UIGraphicsPushContext(context!)
          image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
          UIGraphicsPopContext()
          CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
          return pixelBuffer
      }

}

extension PhotoViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
    picker.dismiss(animated: true)

    let image = info[.originalImage] as! UIImage
    imageView.image = image

    classify(image: image)
  }
    
    func processObservations(for request: VNRequest, error: Error?) {
            if let results = request.results as? [VNClassificationObservation] {
                if results.isEmpty {
                    self.resultsLabel.text = "Nothing found"
                } else {
                    let identifier = results[0].identifier
                    let confidence = results[0].confidence
                    if confidence < 0.6 {
                        label = "notsure"
                        self.resultsLabel.text = "I'm Not Sure\n"
                    } else {
                        label = identifier
                        self.resultsLabel.text = String(format:"%@: %.1f%%\n", identifier, confidence * 100)
                    }
                }
            } else if let error = error {
                self.resultsLabel.text = "Error: \(error.localizedDescription)"
            } else {
                self.resultsLabel.text = "???"
            }
            self.showResultsView()
        }
    
}
