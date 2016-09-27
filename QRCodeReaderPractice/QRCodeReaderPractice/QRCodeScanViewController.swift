//
//  QRCodeScanViewController.swift
//  QRCodeReaderPractice
//
//  Created by ZK on 2016/9/23.
//  Copyright © 2016年 ZK. All rights reserved.
//

import UIKit
import AVFoundation

class QRCodeScanViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    @IBOutlet weak var scanRectView: UIImageView?
    @IBOutlet weak var scanBackView: UIImageView?
    @IBOutlet weak var scanLineView: UIImageView?
    @IBOutlet weak var scanZoomView: UIView?

    var output: AVCaptureMetadataOutput?
    var session: AVCaptureSession?
    var stillImageOutput: AVCaptureStillImageOutput?

    override func viewDidLoad() {
        super.viewDidLoad()

        let device = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        
        //输入
        let input: AVCaptureDeviceInput?
        do{
            input = try AVCaptureDeviceInput.init(device: device)
        }catch{
            input = nil
        }
        //元数据输出
        output = AVCaptureMetadataOutput.init()
        output?.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        
        stillImageOutput = AVCaptureStillImageOutput.init()

        
        //捕获会话
        session = AVCaptureSession.init()
        session?.sessionPreset = AVCaptureSessionPresetHigh
        session?.addInput(input)
        session?.addOutput(output)
        session?.addOutput(stillImageOutput)

        
        //扫条形码不太好用，很多扫不出
        output?.metadataObjectTypes = [AVMetadataObjectTypeQRCode, AVMetadataObjectTypeCode39Code, AVMetadataObjectTypeCode39Mod43Code, AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeCode93Code, AVMetadataObjectTypePDF417Code, AVMetadataObjectTypeAztecCode]
        
        //预览
        let previewLayer = AVCaptureVideoPreviewLayer.init(session: session)
        previewLayer?.frame = (self.view?.bounds)!
        scanZoomView?.layer.insertSublayer(previewLayer!, at: 0)

        session?.startRunning()
        

    }

    //设置比例
    func setVideoScale(scale: CGFloat) -> Void {
        let connection: AVCaptureConnection! = stillImageOutput?.connections.first as! AVCaptureConnection
//        self.connectionWith(mediaType: AVMediaTypeVideo, connections: (stillImageOutput?.connections)!)
        guard (connection != nil) else {
            return
        }
        let zoom = scale / connection!.videoScaleAndCropFactor
        connection!.videoScaleAndCropFactor = scale
        
        scanZoomView?.transform = CGAffineTransform.init(scaleX: zoom, y: zoom)
    }
    
    //找出AVCaptureStillImageOutput的AVCaptureConnection
    func connectionWith(mediaType: String, connections: [Any]) -> AVCaptureConnection? {
        for connection in connections {
            let connectionItem = connection as! AVCaptureConnection
            for port in connectionItem.inputPorts {
                let portItem = port as! AVCaptureInputPort
                if portItem.mediaType == mediaType {
                    return connection as? AVCaptureConnection
                }
            }
        }
        return nil
    }
 
    
    override func viewDidLayoutSubviews() {
        let rectOfInterestWidth = (scanRectView?.bounds.size.height)!/self.view.bounds.size.height
        let rectOfInterestHeight = (scanRectView?.bounds.size.width)!/self.view.bounds.size.width
        let rectOfInterestX = (scanRectView?.frame.origin.y)!/self.view.bounds.size.height
        let rectOfInterestY = (scanRectView?.frame.origin.x)!/self.view.bounds.size.width
        //扫码范围
        output?.rectOfInterest = CGRect.init(x: rectOfInterestX, y: rectOfInterestY, width: rectOfInterestWidth, height: rectOfInterestHeight);

        //扫码遮罩
        let rect = CGRect.init(x: self.view.frame.origin.x, y: self.view.frame.origin.y, width: self.view.frame.size.width, height: self.view.frame.size.height-49)
        UIGraphicsBeginImageContext(rect.size)
        let context: CGContext? = UIGraphicsGetCurrentContext()
        context?.setFillColor(UIColor.black.withAlphaComponent(0.6).cgColor);
        context?.fill(rect)
        context?.clear((scanRectView?.frame)!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        scanBackView?.image = image
        
        startAnimation()
        
        //TODO xxxxx
        let zoomView = LBXScanVideoZoomView.init(frame: CGRect.init(x: (self.view.frame.size.width-200)/2, y: (scanRectView?.frame.origin.y)!+(scanRectView?.frame.size.height)!+100, width: 200, height: 18))
        zoomView.block = {(value: Float) in
            self.setVideoScale(scale: CGFloat.init(value) )
        }
        self.view.addSubview(zoomView)
    }
    
    func startAnimation() -> Void {
        UIView.beginAnimations("scanLineView", context: nil)
        UIView.setAnimationDuration(1.5)
        UIView.setAnimationCurve(.linear)
        UIView.setAnimationRepeatCount(MAXFLOAT)
        scanLineView?.frame = CGRect.init(x: (scanLineView?.frame.origin.x)!, y: (scanLineView?.frame.origin.y)!+(scanRectView?.frame.size.height)!-8, width: (scanLineView?.frame.size.width)!, height: (scanLineView?.frame.size.height)!)
        UIView.commitAnimations()
    }
    
    func stopAnimation() -> Void {
        self.view.layer.removeAllAnimations()
        scanLineView?.frame = CGRect.init(x: (scanLineView?.frame.origin.x)!, y: (scanRectView?.frame.origin.y)!, width: (scanLineView?.frame.size.width)!, height: (scanLineView?.frame.size.height)!)
    }

    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        if(metadataObjects.count>0){
            //扫码识别结果
            let object: AVMetadataMachineReadableCodeObject = metadataObjects.first as! AVMetadataMachineReadableCodeObject
            let alert: UIAlertController = UIAlertController.init(title: object.stringValue, message: nil, preferredStyle: .alert)
            let alertAction: UIAlertAction = UIAlertAction.init(title: "好", style: .cancel, handler: { (alert) in
            })
            alert.addAction(alertAction)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
}
