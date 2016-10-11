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


class FaceObject: Any {
    var face: AVMetadataFaceObject?
    var faceView: UIView?

}

class ViewController: UIViewController, AVCapturePhotoCaptureDelegate, AVCaptureMetadataOutputObjectsDelegate {
    
    @IBOutlet weak var preview: UIView?
    @IBOutlet weak var focusImageView: UIImageView?
    @IBOutlet weak var flashButton: UIButton?

    var session: AVCaptureSession?
    var photoOutput: AVCapturePhotoOutput?
    var device: AVCaptureDevice?
    var deviceInput: AVCaptureDeviceInput?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var deviceScale: CGFloat = 0.0
    var metadataOutput: AVCaptureMetadataOutput?
    
    var image: UIImage!
    var assetCollection: PHAssetCollection!
    var photosAsset: PHFetchResult<PHAsset>!
    var assetThumbnailSize:CGSize!
    var collection: PHAssetCollection!
    var assetCollectionPlaceholder: PHObjectPlaceholder!
    
    var latestFaces: NSMutableArray = NSMutableArray.init()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        device = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        
        //输入
        do{
            deviceInput = try AVCaptureDeviceInput.init(device: device)
        }catch{
            deviceInput = nil
        }
        
        photoOutput = AVCapturePhotoOutput.init()
        
        //捕获会话
        session = AVCaptureSession.init()
        session?.sessionPreset = AVCaptureSessionPresetPhoto;
        session?.addInput(deviceInput)
        session?.addOutput(photoOutput)
        
        //预览
        previewLayer = AVCaptureVideoPreviewLayer.init(session: session)
        previewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
        preview?.layer.insertSublayer(previewLayer!, at: 0)
        
        //元数据输出
        metadataOutput = AVCaptureMetadataOutput.init()
        metadataOutput?.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        session?.addOutput(metadataOutput)
        metadataOutput?.metadataObjectTypes = [AVMetadataObjectTypeFace]

        
        self.setPreviewGesture()
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
    
    func setPreviewGesture() -> Void {
        let pinch = UIPinchGestureRecognizer.init(target: self, action: #selector(pinchPreview))
        let tap = UITapGestureRecognizer.init(target: self, action: #selector(tapPreview))
        preview?.addGestureRecognizer(pinch)
        preview?.addGestureRecognizer(tap)
    }
    
    //调焦
    func pinchPreview(_ recognizer: UIPinchGestureRecognizer) -> Void {
        var scale = recognizer.scale - 1;
        //if(scale<0){
        //    scale*=1.3;
        //}
        scale += deviceScale ;
        
        if scale>5 {
            scale = 5
        } else if scale<1 {
            scale = 1
        }
        
        try! device?.lockForConfiguration()
        device?.videoZoomFactor = scale;
        device?.unlockForConfiguration()
        
        if recognizer.state == UIGestureRecognizerState.ended {
            deviceScale = scale
        }

    }
    
    //对焦
    func tapPreview(_ recognizer: UITapGestureRecognizer) -> Void {
        let point = recognizer.location(in: preview)
        let devicePoint = previewLayer?.captureDevicePointOfInterest(for: point)
        
        if (device?.isFocusModeSupported(.autoFocus))! && (device?.isFocusPointOfInterestSupported)! {
            try! device?.lockForConfiguration()
            device?.focusPointOfInterest = devicePoint!
            device?.exposurePointOfInterest = devicePoint!
            device?.focusMode = .autoFocus
            device?.unlockForConfiguration()
        }
        
        focusImageView?.layer.removeAllAnimations()
        focusImageView?.isHidden = false
        focusImageView?.center = point
        focusImageView?.transform = CGAffineTransform.init(scaleX: 1.5, y: 1.5)
        UIView.animate(withDuration: 0.3, animations: {
            self.focusImageView?.transform = CGAffineTransform.identity
        }) { (finish) in
            //连续点击需要cancel
            DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
                self.focusImageView?.isHidden = true
            })
        }
    }
    
    //切换摄像头
    @IBAction func switchCamera() -> Void {
        var position: AVCaptureDevicePosition = .front
        if deviceInput?.device.position == .front {
            position = .back
        }else {
            position = .front
        }
        
        let device: AVCaptureDevice = AVCaptureDevice.defaultDevice(withDeviceType: .builtInWideAngleCamera, mediaType: AVMediaTypeVideo, position: position)
        let newInput = try! AVCaptureDeviceInput.init(device: device)

        session?.beginConfiguration()
        session?.removeInput(deviceInput)
        session?.addInput(newInput)
        session?.commitConfiguration()
        deviceInput = newInput
        flashButton?.isHidden = device.isFlashAvailable

    }
    
    
    //拍照
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
    
    //代理
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
    
    
    //MARK: -人脸
    //定义了多个用于描述被检测到的人脸的属性,包括人脸的边界(设备坐标系),以及斜倾角(roll angle,表示人头部向肩膀方向的侧倾角度)和偏转角(yaw angle,表示人脸绕Y轴旋转的角度).
    //功能太简单，不能识别人眼，眨眼。
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        
        self.didDetectFaces(faces: metadataObjects)
    }
    
    //先转换坐标，再添加view，更新view，删除已经不识别的人脸， 可以做过1秒删除，
    func didDetectFaces(faces: [Any]) {
        //1. 创建一个数组用于保存转换后的人脸数据
        var transformedFaces = [AVMetadataObject]()
        
        //2. 遍历传入的人脸数据进行转换
        for face in faces {
            //3. 元数据对象就会被转化成图层的坐标
            let transformedFace = previewLayer?.transformedMetadataObject(for: face as! AVMetadataObject)
            transformedFaces.append(transformedFace!)
        }
        
        //.遍历新检测到的人脸信息
        //ADD
        for metadataFace in transformedFaces {
            let faceID =  (metadataFace as! AVMetadataFaceObject).faceID

            for object in latestFaces {
                let face: FaceObject = object as! FaceObject
                if face.face?.faceID == faceID {
                    UIView.animate(withDuration: 0.15, animations: {
                        face.faceView?.frame = (metadataFace as! AVMetadataFaceObject).bounds
                    })
                    continue
                }
            }
            
            let view = UIView(frame: (metadataFace as! AVMetadataFaceObject).bounds)
            view.layer.borderColor = UIColor(colorLiteralRed: 1.000, green: 0.421, blue: 0.054, alpha: 1.000).cgColor
            view.layer.borderWidth = 2
            previewLayer?.insertSublayer(view.layer, above: previewLayer)
            
            let face: FaceObject = FaceObject.init()
            face.face = metadataFace as? AVMetadataFaceObject
            face.faceView = view
            latestFaces.add(face)
        }
        //remove
        let removeFaces: NSMutableArray = NSMutableArray.init()

        for object in latestFaces {
            let face: FaceObject = object as! FaceObject
            
            var remove = true
            for metadataFace in transformedFaces {
                let faceID =  (metadataFace as! AVMetadataFaceObject).faceID
                if face.face?.faceID == faceID {
                    remove = false
                    break
                }
            }
            if remove {
                removeFaces.add(face)
            }
        }
        for face in removeFaces {
            let object: FaceObject = face as! FaceObject
            object.faceView?.removeFromSuperview()
            latestFaces.remove(face)
        }
        
    }

    override var prefersStatusBarHidden: Bool{
        return true
    }
    
}

