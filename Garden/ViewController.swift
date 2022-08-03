//
//  ViewController.swift
//  Garden
//
//  Created by Павел Черноок on 27.07.22.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var flowerDescriptionLabel: UILabel!
    
    private let imagePicker = UIImagePickerController()
    
    private let wikipediaURL = "https://en.wikipedia.org/w/api.php"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Garden"
        
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        imagePicker.sourceType = .photoLibrary
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let userPickedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            guard let convertedCIImage = CIImage(image: userPickedImage) else {
                fatalError("Cannot convert to CIImage")
            }
            
            detect(image: convertedCIImage)
        }
        
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    func detect(image: CIImage) {
        guard let model = try? VNCoreMLModel(for: FlowerClassifierModel_1().model) else {
            fatalError("Cannot import model")
        }
        
        let request = VNCoreMLRequest(model: model) { request, error in
            guard let classification = request.results?.first as? VNClassificationObservation else {
                fatalError("fail")
            }

            self.navigationItem.title = classification.identifier.capitalized
            
            self.requestInfo(flowerName: classification.identifier)
        }
        
        let handler = VNImageRequestHandler(ciImage: image)
        
        do {
            try handler.perform([request])
        } catch {
            print(error)
        }
    }
    
    func requestInfo(flowerName: String) {
        let parameters : [String:String] = [
          "format" : "json",
          "action" : "query",
          "prop" : "extracts|pageimages",
          "exintro" : "",
          "explaintext" : "",
          "titles" : flowerName,
          "indexpageids" : "",
          "redirects" : "1",
          "pithumbsize" : "500"]
        
        AF.request(wikipediaURL, method: .get, parameters: parameters).responseJSON { response in
            switch response.result {
            case .success(let resultValue):
                let flowerJSON: JSON = JSON(resultValue)
                
                let pageID = flowerJSON["query"]["pageids"][0].stringValue
                let flowerDescription = flowerJSON["query"]["pages"][pageID]["extract"].string
                let flowerImageURL = flowerJSON["query"]["pages"][pageID]["thumbnail"]["source"].stringValue
                
                self.imageView.sd_setImage(with: URL(string: flowerImageURL))
                self.flowerDescriptionLabel.text = flowerDescription
            case .failure(let error):
                print(error)
            }
        }
    }
    
    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
        present(imagePicker, animated: true, completion: nil)
    }
}

