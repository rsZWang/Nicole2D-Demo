//
//  ViewController.swift
//  BackgroundRemovalTest
//
//  Created by Nihontabako on 2020/7/9.
//  Copyright © 2020 YHWang. All rights reserved.
//

import UIKit
import Alamofire
import Photos
import CoreLocation

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBOutlet weak var pickedImageUIImage: UIImageView!
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        print("image picked")
        var pickedImage: UIImage
    
        if let selectedImage = info[.editedImage] as? UIImage {
            pickedImage = selectedImage
        } else if let selectedImage = info[.originalImage] as? UIImage {
            pickedImage = selectedImage
        } else {
            return
        }
                
        guard let url = info[.imageURL] as? URL else {
            print("no url")
            return
        }
        let fileName = url.lastPathComponent
        
        guard let jpegImageData = pickedImage.jpegData(compressionQuality: 1) else {
            print("no file")
            return
        }

        dismiss(animated: true)
        uploadRemoveBg(fileName: fileName, imageData: jpegImageData)
    }
    
    func uploadRemoveBg(fileName: String, imageData: Data) {
        _ = AF.upload(
            multipartFormData: { builder in
                builder.append(
                    imageData,
                    withName: "image_file",
                    fileName: fileName,
                    mimeType: "image/jpeg"
                )
            },
            to: URL(string: "https://api.remove.bg/v1.0/removebg")!,
            method: .post,
            headers: [
                "X-Api-Key": "r2eWd8CpjHd1V6VWGSNpXDgP"
            ]
        ).uploadProgress(queue: .main, closure: { progress in
            print("Upload Progress: \(progress.fractionCompleted)")
        }).responseJSON(completionHandler: { data in
            print("upload finished: \(data)")
        }).response { (response) in
            switch response.result {
            case .success(let result):
                guard let imageData = result else {
                    print("return data error")
                    return
                }
                self.pickedImageUIImage.image = UIImage(data: imageData)
                
            case .failure(let err):
                print("upload err: \(err)")
            }
        }
    }
    
    @IBAction func openGallery(_ sender: Any) {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.photoLibrary) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
//            imagePicker.allowsEditing = true
            imagePicker.sourceType = UIImagePickerController.SourceType.photoLibrary
            self.present(imagePicker, animated: true, completion: nil)
        } else {
            let alert  = UIAlertController(title: "Warning", message: "You don't have permission to access gallery.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
}

