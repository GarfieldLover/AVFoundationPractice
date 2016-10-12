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

class ViewController: UIViewController, AVCapturePhotoCaptureDelegate, AVCaptureMetadataOutputObjectsDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    @IBOutlet weak var preview: UIView!
    @IBOutlet weak var focusImageView: UIImageView?
    @IBOutlet weak var flashButton: UIButton?
    @IBOutlet weak var previewOverView: UIView?
    @IBOutlet weak var xxxxxxxx: UIImageView?

    var session: AVCaptureSession?
    var device: AVCaptureDevice?
    var deviceInput: AVCaptureDeviceInput?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var deviceScale: CGFloat = 0.0
    var metadataOutput: AVCaptureMetadataOutput?
    var photoOutput: AVCapturePhotoOutput?
    var videoDataOutput: AVCaptureVideoDataOutput?
    
    var assetCollection: PHAssetCollection!
    var photosAsset: PHFetchResult<PHAsset>!
    var assetThumbnailSize:CGSize!
    var collection: PHAssetCollection!
    var assetCollectionPlaceholder: PHObjectPlaceholder!
    
    var latestFaces: NSMutableArray = NSMutableArray.init()
    
    var context: CIContext! {
        let testEAGLContext = EAGLContext.init(api: .openGLES3)
        let testContext = CIContext.init(eaglContext: testEAGLContext!)
        return testContext
    }
    
    var faceView: UIView?
    var LeftEyeView: UIView?
    var RightEyeView: UIView?
    
    
    var filter: CIFilter!
    var faceObject: AVMetadataFaceObject?
    var ciImage: CIImage!

    // Video Records
    @IBOutlet var recordsButton: UIButton!
    var assetWriter: AVAssetWriter?
    var assetWriterPixelBufferInput: AVAssetWriterInputPixelBufferAdaptor?
    var isWriting = false
    var currentSampleTime: CMTime?
    var currentVideoDimensions: CMVideoDimensions?
    
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
        
        videoDataOutput = AVCaptureVideoDataOutput.init()
        
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
        //metadataOutput?.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        //session?.addOutput(metadataOutput)
        //metadataOutput?.metadataObjectTypes = [AVMetadataObjectTypeFace]
        
        //帧数据输出
        session?.addOutput(videoDataOutput)
        videoDataOutput?.setSampleBufferDelegate(self, queue: DispatchQueue.global())
        videoDataOutput?.videoSettings  = NSDictionary(object: Int(kCVPixelFormatType_32BGRA), forKey: kCVPixelBufferPixelFormatTypeKey as String as NSCopying) as [NSObject : AnyObject]
        
        
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
        #if false
            //第1种方法
            //好像也没啥用
            let settings = AVCapturePhotoSettings()
            let previewPixelType = settings.availablePreviewPhotoPixelFormatTypes.first!
            let previewFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewPixelType,
                                 kCVPixelBufferWidthKey as String: 1080,
                                 kCVPixelBufferHeightKey as String: 1920,
                                 ]
            settings.previewPhotoFormat = previewFormat
            
            photoOutput?.capturePhoto(with: settings, delegate: self)
            
        #else
            //第2种
            //这种方法清晰度不够啊
            if ciImage == nil || isWriting {
                return
            }
            
            let cgImage = context.createCGImage(ciImage, from: ciImage.extent)
            let image = UIImage.init(cgImage: cgImage!)
            
            DispatchQueue.global().async {
                self.createAlbum()
                self.saveImage(image)
            }
            
        #endif
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
    
    // MARK: - Video Records
    func saveVideo(){
        PHPhotoLibrary.shared().performChanges({
            let assetRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: self.movieURL() as URL)
            let assetPlaceholder = assetRequest?.placeholderForCreatedAsset
            let albumChangeRequest = PHAssetCollectionChangeRequest.init(for: self.assetCollection)
            let fastEnumeration = NSArray(array: [assetPlaceholder!])
            albumChangeRequest?.addAssets(fastEnumeration)
        }) { (success, error) in
            if success {
                
            } else {
                
            }
        }
    }
    
    @IBAction func record() {
        if isWriting {
            self.isWriting = false
            assetWriterPixelBufferInput = nil
            assetWriter?.finishWriting(completionHandler: {[unowned self] () -> Void in
                print("录制完成")
                self.createAlbum()
                self.saveVideo()
                })
        } else {
            createWriter()
            assetWriter?.startWriting()
            assetWriter?.startSession(atSourceTime: currentSampleTime!)
            isWriting = true
        }
    }
    
    func movieURL() -> NSURL {
        let tempDir = NSTemporaryDirectory()
        let url = NSURL(fileURLWithPath: tempDir).appendingPathComponent("tmpMov.mov")
        return url! as NSURL
    }
    
    func checkForAndDeleteFile() {
        let fm = FileManager.default
        let url = movieURL()
        let exist = fm.fileExists(atPath: url.path!)
        
        if exist {
            print("删除之前的临时文件")
            do {
                try fm.removeItem(at: url as URL)
            } catch let error as NSError {
                print(error.localizedDescription)
            }
        }
    }
    
    func createWriter() {
        self.checkForAndDeleteFile()
        
        do {
            assetWriter = try AVAssetWriter.init(url: movieURL() as URL, fileType: AVFileTypeQuickTimeMovie)
        } catch let error as NSError {
            print("创建writer失败")
            print(error.localizedDescription)
            return
        }
        
        let outputSettings = [
            AVVideoCodecKey : AVVideoCodecH264,
            AVVideoWidthKey : Int(currentVideoDimensions!.width),
            AVVideoHeightKey : Int(currentVideoDimensions!.height)
        ] as [String : Any]
        
        let assetWriterVideoInput = AVAssetWriterInput(mediaType: AVMediaTypeVideo, outputSettings: outputSettings)
        assetWriterVideoInput.expectsMediaDataInRealTime = true
        assetWriterVideoInput.transform = CGAffineTransform(rotationAngle: CGFloat(M_PI / 2.0))
        
        let sourcePixelBufferAttributesDictionary = [
            String(kCVPixelBufferPixelFormatTypeKey) : Int(kCVPixelFormatType_32BGRA),
            String(kCVPixelBufferWidthKey) : Int(currentVideoDimensions!.width),
            String(kCVPixelBufferHeightKey) : Int(currentVideoDimensions!.height),
            String(kCVPixelFormatOpenGLESCompatibility) : Int(kCFBooleanTrue)
        ]
        
        assetWriterPixelBufferInput = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: assetWriterVideoInput,
                                                                           sourcePixelBufferAttributes: sourcePixelBufferAttributesDictionary)
        
        if assetWriter!.canAdd(assetWriterVideoInput) {
            assetWriter!.add(assetWriterVideoInput)
        } else {
            print("不能添加视频writer的input \(assetWriterVideoInput)")
        }
    }
    
    func makeFaceWithCIImage(inputImage: CIImage, bounds: CGRect) -> CIImage {
        let filter = CIFilter(name: "CIPixellate")!
        filter.setValue(inputImage, forKey: kCIInputImageKey)
        // 1.
        filter.setValue(max(inputImage.extent.size.width, inputImage.extent.size.height) / 60, forKey: kCIInputScaleKey)
        
        let fullPixellatedImage = filter.outputImage
        
        var maskImage: CIImage!
        let faceBounds = bounds
        
        // 2.
        let centerX = inputImage.extent.size.width * (faceBounds.origin.x + faceBounds.size.width / 2)
        let centerY = inputImage.extent.size.height * (1 - faceBounds.origin.y - faceBounds.size.height / 2)
        let radius = faceBounds.size.width * inputImage.extent.size.width / 2
        let radialGradient = CIFilter(name: "CIRadialGradient",
                                      withInputParameters: [
                                        "inputRadius0" : radius,
                                        "inputRadius1" : radius + 1,
                                        "inputColor0" : CIColor(red: 0, green: 1, blue: 0, alpha: 1),
                                        "inputColor1" : CIColor(red: 0, green: 0, blue: 0, alpha: 0),
                                        kCIInputCenterKey : CIVector(x: centerX, y: centerY)
            ])!
        
        let radialGradientOutputImage = radialGradient.outputImage!.cropping(to: inputImage.extent)
        if maskImage == nil {
            maskImage = radialGradientOutputImage
        } else {
            print(radialGradientOutputImage)
            maskImage = CIFilter(name: "CISourceOverCompositing",
                                 withInputParameters: [
                                    kCIInputImageKey : radialGradientOutputImage,
                                    kCIInputBackgroundImageKey : maskImage
                ])!.outputImage
        }
        
        let blendFilter = CIFilter(name: "CIBlendWithMask")!
        blendFilter.setValue(fullPixellatedImage, forKey: kCIInputImageKey)
        blendFilter.setValue(inputImage, forKey: kCIInputBackgroundImageKey)
        blendFilter.setValue(maskImage, forKey: kCIInputMaskImageKey)
        
        return blendFilter.outputImage!
    }


    //先画layer，再合成
    //MARK: -通过摄像头读取每一帧的图片，并且做识别做人脸识别
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        

            
            DispatchQueue.main.sync {
                
                autoreleasepool {
                    let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer)!
                    self.currentVideoDimensions = CMVideoFormatDescriptionGetDimensions(formatDescription)
                    self.currentSampleTime = CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer)
                    
                    let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
                    var outputImage = CIImage(cvPixelBuffer: imageBuffer!)
                    
                    let orientation = UIDevice.current.orientation
                    var t: CGAffineTransform!
                    if orientation == UIDeviceOrientation.portrait {
                        t = CGAffineTransform(rotationAngle: CGFloat(-M_PI / 2.0))
                    } else if orientation == UIDeviceOrientation.portraitUpsideDown {
                        t = CGAffineTransform(rotationAngle: CGFloat(M_PI / 2.0))
                    } else if (orientation == UIDeviceOrientation.landscapeRight) {
                        t = CGAffineTransform(rotationAngle: CGFloat(M_PI))
                    } else {
                        t = CGAffineTransform(rotationAngle: 0)
                    }
                    outputImage = outputImage.applying(t)
                
                
                let detecotr = CIDetector(ofType:CIDetectorTypeFace,  context:context, options:[CIDetectorAccuracy: CIDetectorAccuracyHigh])
                let faceFeatures: [CIFaceFeature]? = detecotr!.features(in: outputImage) as? [CIFaceFeature]
                
                if faceFeatures?.count==0 {
                    return
                }
                
                //只做单人的
                let faceFeature: CIFaceFeature = faceFeatures!.first!
                
                // 1.
                let inputImageSize = outputImage.extent.size
                var transform = CGAffineTransform.identity
                transform = transform.scaledBy(x: 1, y: -1)
                
                //坐标反转？
                var faceViewBounds = faceFeature.bounds.applying(transform)
                // 2.
                let scale = min(preview.bounds.size.width / inputImageSize.width,
                                preview.bounds.size.height / inputImageSize.height)
                let offsetX = (preview.bounds.size.width - inputImageSize.width * scale) / 2
                let offsetY = (preview.bounds.size.height - inputImageSize.height * scale) / 2
                //按图片 view比例
                faceViewBounds = faceViewBounds.applying(CGAffineTransform(scaleX: scale, y: scale))
                faceViewBounds.origin.x += offsetX
                faceViewBounds.origin.y += offsetY
                
                if faceView != nil {
                    faceView?.frame = faceViewBounds
                }else {
                    faceView = UIView(frame: faceViewBounds)
                    faceView?.layer.borderColor = UIColor.orange.cgColor
                    faceView?.layer.borderWidth = 1
                    
                    previewOverView?.addSubview(faceView!)
                }
                
                if faceFeature.hasLeftEyePosition {
                    var leftEyePosition = faceFeature.leftEyePosition.applying(transform)
                    leftEyePosition = leftEyePosition.applying(CGAffineTransform(scaleX: scale, y: scale))
                    let LeftEyeBounds = CGRect.init(x: leftEyePosition.x-faceViewBounds.size.width/4/2, y: leftEyePosition.y-faceViewBounds.size.width/4/2, width: faceViewBounds.size.width/4, height: faceViewBounds.size.width/4)
                    
                    if LeftEyeView != nil {
                        LeftEyeView?.frame = LeftEyeBounds
                    }else {
                        LeftEyeView = UIView(frame: LeftEyeBounds)
                        LeftEyeView?.layer.borderColor = UIColor.green.cgColor
                        LeftEyeView?.layer.borderWidth = 1
                        previewOverView?.addSubview(LeftEyeView!)
                    }
                }
                
                if faceFeature.hasRightEyePosition {
                    var RightEyePosition = faceFeature.rightEyePosition.applying(transform)
                    RightEyePosition = RightEyePosition.applying(CGAffineTransform(scaleX: scale, y: scale))
                    let RightEyeBounds = CGRect.init(x: RightEyePosition.x-faceViewBounds.size.width/4/2, y: RightEyePosition.y-faceViewBounds.size.width/4/2, width: faceViewBounds.size.width/4, height: faceViewBounds.size.width/4)
                    
                    if RightEyeView != nil {
                        RightEyeView?.frame = RightEyeBounds
                    }else {
                        RightEyeView = UIView(frame: RightEyeBounds)
                        RightEyeView?.layer.borderColor = UIColor.green.cgColor
                        RightEyeView?.layer.borderWidth = 1
                        previewOverView?.addSubview(RightEyeView!)
                    }
                }
                
                if faceFeature.hasMouthPosition {
                    
                }
                if faceFeature.hasFaceAngle {
                    
                }
                //没法检测出闭眼，太弱了，侧脸也没法检测
                if faceFeature.hasSmile {
                    
                }
                if faceFeature.leftEyeClosed {
                    LeftEyeView?.isHidden = true
                }
                if faceFeature.rightEyeClosed {
                    RightEyeView?.isHidden = true
                }

                    
                UIGraphicsBeginImageContext((previewOverView?.bounds.size)!)
                    let cgcontext: CGContext? = UIGraphicsGetCurrentContext()
                previewOverView?.layer.render(in: cgcontext!)
                let image = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                
                xxxxxxxx?.image = image
                
            
                let cixxx = CIImage.init(image: image!)
                    
                let blendFilter = CIFilter(name: "CISourceOverCompositing")!
                blendFilter.setValue(outputImage, forKey: kCIInputImageKey)
                blendFilter.setValue(cixxx, forKey: kCIInputBackgroundImageKey)
                
                outputImage = blendFilter.outputImage!
                
                //截图合成不了，直接读图片可以，真是操了单了
                    
                    //outputImage = self.makeFaceWithCIImage(inputImage: outputImage, bounds: (faceView?.frame)!)

                self.ciImage = outputImage
                
                // 录制视频的处理
                if self.isWriting {
                    if self.assetWriterPixelBufferInput?.assetWriterInput.isReadyForMoreMediaData == true {
                        var newPixelBuffer: CVPixelBuffer? = nil
                        
                        CVPixelBufferPoolCreatePixelBuffer(nil, self.assetWriterPixelBufferInput!.pixelBufferPool!, &newPixelBuffer)
                        
                        self.context.render(outputImage, to: newPixelBuffer!, bounds: outputImage.extent, colorSpace: CGColorSpaceCreateDeviceRGB())
                        
                        let success = self.assetWriterPixelBufferInput?.append(newPixelBuffer!, withPresentationTime: self.currentSampleTime!)
                        
                        if success == false {
                            print("Pixel Buffer没有附加成功")
                        }
                    }
                }
            }
            
            
            

        }
    }
  
    func sampleBufferToImage(sampleBuffer: CMSampleBuffer!) -> UIImage {
        let imageBuffer: CVImageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
        let baseAddress = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0)
        
        let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
        let width = CVPixelBufferGetWidth(imageBuffer)
        let height = CVPixelBufferGetHeight(imageBuffer)
        
        let colorSpace: CGColorSpace = CGColorSpaceCreateDeviceRGB()
        
        let bitmapInfo = CGBitmapInfo(rawValue: (CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue) as UInt32)
        
        let newContext: CGContext = CGContext.init(data: baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)!
        
        let imageRef: CGImage = newContext.makeImage()!
        let resultImage = UIImage(cgImage: imageRef, scale: 1.0, orientation: UIImageOrientation.right)
        
        return resultImage
    }
    
    
    //MARK: -人脸
    //定义了多个用于描述被检测到的人脸的属性,包括人脸的边界(设备坐标系),以及斜倾角(roll angle,表示人头部向肩膀方向的侧倾角度)和偏转角(yaw angle,表示人脸绕Y轴旋转的角度).
    //功能太简单，不能识别人眼，眨眼。
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        
        //self.didDetectFaces(faces: metadataObjects)
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

