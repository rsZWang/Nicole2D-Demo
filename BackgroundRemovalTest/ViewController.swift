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
import AVFoundation

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, AVCapturePhotoCaptureDelegate {

    var captureSession: AVCaptureSession!
    var currentCameraPosition: CameraPosition?
    var frontCamera: AVCaptureDevice?
    var frontCameraInput: AVCaptureDeviceInput?
    var photoOutput: AVCapturePhotoOutput?
    var rearCamera: AVCaptureDevice?
    var rearCameraInput: AVCaptureDeviceInput?
    
    var previewLayer: AVCaptureVideoPreviewLayer?
    @IBOutlet var screen_view: UIView!
    @IBOutlet weak var capture_button: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        prepare() { error in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            print("camera configured successfully")
            do {
                try self.displayPreview(on: self.screen_view)
            } catch {
                print(error)
            }
            self.styleCaptureButton(button: self.capture_button)
        }
    }
    
    var photoCaptureCompletion: ((Data?, Error?) -> Void)?
    @IBAction func catpure_button_action(_ sender: Any) {
        captureImage { (imageData, error) in
            guard let imageData = imageData else {
                print(error ?? "Image capture error")
                return
            }
            
            self.uploadRemoveBg(fileName: "test.jpg", imageData: imageData) { imageData in
                let imageView = CustomUIImageView(imageData: imageData)
                let halfRootViewWidth = self.view.frame.size.width/3*2
                let halfRootViewHeight = self.view.frame.size.height/3*2
                imageView.frame = CGRect(
                    x: self.view.center.x - halfRootViewWidth/2,
                    y: self.view.center.y - halfRootViewHeight/2,
                    width: halfRootViewWidth,
                    height: halfRootViewHeight)
                self.view.addSubview(imageView)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
    }
}

// Camera configuration step
extension ViewController {
    func prepare(completionHandler: @escaping (Error?) -> Void) {
        func createCaptureSession() {
            self.captureSession = AVCaptureSession()
        }
 
        func configureCaptureDevices() throws {
            let cameras = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInDualCamera], mediaType: AVMediaType.video, position: .unspecified)
                                        .devices
                                        .compactMap { $0 }
            guard !cameras.isEmpty else { throw CameraError.noCamerasAvailable }
            for camera in cameras {
                if camera.position == .front {
                    self.frontCamera = camera
                }
 
                if camera.position == .back {
                    self.rearCamera = camera
 
                    try camera.lockForConfiguration()
                    camera.focusMode = .autoFocus
                    camera.unlockForConfiguration()
                }
            }
        }
 
        func configureDeviceInputs() throws {
            if let rearCamera = self.rearCamera {
                self.rearCameraInput = try AVCaptureDeviceInput(device: rearCamera)
                if captureSession.canAddInput(self.rearCameraInput!) { captureSession.addInput(self.rearCameraInput!) }
                self.currentCameraPosition = .rear
            }
//            } else if let frontCamera = self.frontCamera {
//                self.frontCameraInput = try AVCaptureDeviceInput(device: frontCamera)
//                if captureSession.canAddInput(self.frontCameraInput!) { captureSession.addInput(self.frontCameraInput!) }
//                else { throw CameraError.inputsAreInvalid }
//
//                self.currentCameraPosition = .front
//            }
 
            else { throw CameraError.noCamerasAvailable }
        }
 
        func configurePhotoOutput() throws {
            self.photoOutput = AVCapturePhotoOutput()
            self.photoOutput!.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format: [AVVideoCodecKey : AVVideoCodecType.jpeg])], completionHandler: nil)
 
            if captureSession.canAddOutput(self.photoOutput!) { captureSession.addOutput(self.photoOutput!) }
            captureSession.startRunning()
        }
        
        DispatchQueue(label: "prepare").async {
            do {
                createCaptureSession()
                try configureCaptureDevices()
                try configureDeviceInputs()
                try configurePhotoOutput()
            } catch {
                DispatchQueue.main.async {
                    completionHandler(error)
                }
                return
            }
 
            DispatchQueue.main.async {
                completionHandler(nil)
            }
        }
    }
    
    func displayPreview(on view: UIView) throws {
        guard let captureSession = self.captureSession, captureSession.isRunning else { throw CameraError.captureSessionIsMissing }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        previewLayer?.connection?.videoOrientation = .portrait

        view.layer.insertSublayer(previewLayer!, at: 0)
        DispatchQueue.main.async {
            self.previewLayer?.frame = view.frame
        }
    }
    
    func styleCaptureButton(button: UIButton) {
        button.layer.borderColor = UIColor.white.cgColor
        button.layer.borderWidth = 5
        button.layer.cornerRadius = min(button.frame.width, button.frame.height) / 2
    }
    
    func captureImage(completion: @escaping (Data?, Error?) -> Void) {
        self.photoCaptureCompletion = completion
        self.photoOutput?.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
    }
    
    // Delegation for AVCapturePhotoCaptureDelegate
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            self.photoCaptureCompletion?(nil, error)
        } else if let imageData = photo.fileDataRepresentation() {
            self.photoCaptureCompletion?(imageData, nil)
        } else {
            self.photoCaptureCompletion?(nil, CameraError.unknown)
        }
    }
    
    enum CameraError: Swift.Error {
       case captureSessionAlreadyRunning
       case captureSessionIsMissing
       case inputsAreInvalid
       case invalidOperation
       case noCamerasAvailable
       case unknown
   }
    
   enum CameraPosition {
       case front
       case rear
   }
}

// Upload to remove.bg and retrive result
extension ViewController {
    func uploadRemoveBg(fileName: String, imageData: Data, completion: @escaping (Data) -> ()) {
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
                    if let imageData = result {
                        completion(imageData)
                    } else {
                        print("return data error")
                        return
                    }
                    
                case .failure(let err):
                    print("upload err: \(err)")
                }
            }
        }
}
