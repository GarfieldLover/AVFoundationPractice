//
//  ViewController.swift
//  AVTakePhotoPractice
//
//  Created by ZK on 2016/9/28.
//  Copyright © 2016年 ZK. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

class ViewController: UIViewController, AVCapturePhotoCaptureDelegate {
    
    @IBOutlet weak var preview: UIView?

    var session: AVCaptureSession?
    var photoOutput: AVCapturePhotoOutput?
    var device: AVCaptureDevice?
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    var image: UIImage!
    var assetCollection: PHAssetCollection!
    var albumFound : Bool = false
    var photosAsset: PHFetchResult<PHAsset>!
    var assetThumbnailSize:CGSize!
    var collection: PHAssetCollection!
    var assetCollectionPlaceholder: PHObjectPlaceholder!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        device = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)

        //输入
        let input: AVCaptureDeviceInput?
        do{
            input = try AVCaptureDeviceInput.init(device: device)
        }catch{
            input = nil
        }
        
        photoOutput = AVCapturePhotoOutput.init()
        
        //捕获会话
        session = AVCaptureSession.init()
        session?.sessionPreset = AVCaptureSessionPresetPhoto;
        session?.addInput(input)
        session?.addOutput(photoOutput)
        
        //预览
        previewLayer = AVCaptureVideoPreviewLayer.init(session: session)
        previewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
        preview?.layer.insertSublayer(previewLayer!, at: 0)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        previewLayer?.frame = (preview?.layer.bounds)!
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        session?.startRunning()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        session?.stopRunning()
    }
    
    @IBAction func takePhoto(button: UIButton) -> Void {
//        button.isUserInteractionEnabled = false
        
        let settings = AVCapturePhotoSettings()
        let previewPixelType = settings.availablePreviewPhotoPixelFormatTypes.first!
        let previewFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewPixelType,
                             kCVPixelBufferWidthKey as String: 1080,
                             kCVPixelBufferHeightKey as String: 1920,
                             ]
        settings.previewPhotoFormat = previewFormat
        
        photoOutput?.capturePhoto(with: settings, delegate: self)
    }
    
    func capture(_ captureOutput: AVCapturePhotoOutput, didFinishCaptureForResolvedSettings resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        
    }
    
    func capture(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhotoSampleBuffer photoSampleBuffer: CMSampleBuffer?, previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        
        if let sampleBuffer = photoSampleBuffer, let previewBuffer = previewPhotoSampleBuffer, let dataImage = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: sampleBuffer, previewPhotoSampleBuffer: previewBuffer) {
            
            self.image = UIImage.init(data: dataImage)
            
            self.createAlbum()
            self.saveImage()
//            print(image: UIImage(data: dataImage).size)
            
        } else {
            
        }
    }
    
    func createAlbum() {
        //Get PHFetch Options
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", "camcam")
        let collection : PHFetchResult = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        //Check return value - If found, then get the first album out
        if let _: AnyObject = collection.firstObject {
            self.albumFound = true
            assetCollection = collection.firstObject
        } else {
            //If not found - Then create a new album
            PHPhotoLibrary.shared().performChanges({
                let createAlbumRequest : PHAssetCollectionChangeRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: "camcam")
                self.assetCollectionPlaceholder = createAlbumRequest.placeholderForCreatedAssetCollection
                }, completionHandler: { success, error in
                    self.albumFound = (success ? true: false)
                    
                    if (success) {
                        let collectionFetchResult = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [self.assetCollectionPlaceholder.localIdentifier], options: nil)
                        print(collectionFetchResult)
                        self.assetCollection = collectionFetchResult.firstObject
                    }
            })
        }
    }
    
    func saveImage(){
        PHPhotoLibrary.shared().performChanges({
            let assetRequest = PHAssetChangeRequest.creationRequestForAsset(from: self.image)
            let assetPlaceholder = assetRequest.placeholderForCreatedAsset
            let albumChangeRequest = PHAssetCollectionChangeRequest.init(for: self.assetCollection, assets: self.photosAsset)
            albumChangeRequest!.addAssets(assetPlaceholder as! NSFastEnumeration)
//            addAssets([assetPlaceholder!])
            }, completionHandler: { success, error in
                print("added image to album")
                print(error)
                
                //self.showImages()
        })
    }

    override var prefersStatusBarHidden: Bool{
        return true
    }
    
}

