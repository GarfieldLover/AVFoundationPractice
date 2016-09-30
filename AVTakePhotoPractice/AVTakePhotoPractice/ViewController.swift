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
        //好像也没啥用
        let settings = AVCapturePhotoSettings()
        let previewPixelType = settings.availablePreviewPhotoPixelFormatTypes.first!
        let previewFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewPixelType,
                             kCVPixelBufferWidthKey as String: 1080,
                             kCVPixelBufferHeightKey as String: 1920,
                             ]
        settings.previewPhotoFormat = previewFormat
        
        photoOutput?.capturePhoto(with: settings, delegate: self)
    }
    
    func capture(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhotoSampleBuffer photoSampleBuffer: CMSampleBuffer?, previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        
    
        DispatchQueue.global().async {
            if let sampleBuffer = photoSampleBuffer, let previewBuffer = previewPhotoSampleBuffer, let dataImage = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: sampleBuffer, previewPhotoSampleBuffer: previewBuffer) {
                
                //            - width : 2448.0
                //            - height : 3264.0
                let image: UIImage = UIImage.init(data: dataImage)!
                
                self.createAlbum()
                self.saveImage(image)
                
            } else {
                
            }
        }
    }
    
    func createAlbum() {
        //筛选相册
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", "AVTakePhotoPractice")
        let fetchResult : PHFetchResult = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        //筛选结果，如果有结果，第一个是资源集合
        if let _: AnyObject = fetchResult.firstObject {
            self.assetCollection = fetchResult.firstObject
        } else {
            
            //如果没，创建
            PHPhotoLibrary.shared().performChanges({
                let createAlbumRequest : PHAssetCollectionChangeRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: "AVTakePhotoPractice")
                self.assetCollectionPlaceholder = createAlbumRequest.placeholderForCreatedAssetCollection
                }, completionHandler: { success, error in
                    if (success) {
                        let collectionFetchResult = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [self.assetCollectionPlaceholder.localIdentifier], options: nil)
                        self.assetCollection = collectionFetchResult.firstObject
                    }
            })
        }
    }
    
    func saveImage(_ image: UIImage){
        //执行更新
        PHPhotoLibrary.shared().performChanges({
            //创建资源
            let assetRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
            let assetPlaceholder = assetRequest.placeholderForCreatedAsset
            //相册更新请求
            let albumChangeRequest = PHAssetCollectionChangeRequest.init(for: self.assetCollection)
            //更新添加资源
            let fastEnumeration = NSArray(array: [assetPlaceholder!])
            albumChangeRequest?.addAssets(fastEnumeration)
        }) { (success, error) in
            if success {
            
            } else {
            
            }
        }
    }

    override var prefersStatusBarHidden: Bool{
        return true
    }
    
}

