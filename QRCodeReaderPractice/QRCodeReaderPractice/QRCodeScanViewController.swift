//
//  QRCodeScanViewController.swift
//  QRCodeReaderPractice
//
//  Created by ZK on 2016/9/23.
//  Copyright © 2016年 ZK. All rights reserved.
//

import UIKit
import AVFoundation

//class imagecc: AnyClass {
//    func <#name#>(<#parameters#>) -> <#return type#> {
//        <#function body#>
//    }
//}

class QRCodeScanViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    @IBOutlet weak var scanRectView: UIImageView?
    @IBOutlet weak var scanBackView: UIImageView?

    var output: AVCaptureMetadataOutput?

    override func viewDidLoad() {
        super.viewDidLoad()

        let device = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        
        let input: AVCaptureDeviceInput?
        do{
            input = try AVCaptureDeviceInput.init(device: device)
        }catch{
            input = nil
        }
        
        output = AVCaptureMetadataOutput.init()
        output?.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        
        let session = AVCaptureSession.init()
        session.sessionPreset = AVCaptureSessionPresetHigh
        session.addInput(input)
        session.addOutput(output)
        output?.metadataObjectTypes = [AVMetadataObjectTypeQRCode]

        let previewLayer = AVCaptureVideoPreviewLayer.init(session: session)
        previewLayer?.frame = self.view.bounds
        self.view.layer.insertSublayer(previewLayer!, at: 0)
        
        session.startRunning()

    }
    
    override func viewDidLayoutSubviews() {
        let rectOfInterestWidth = (scanRectView?.bounds.size.height)!/self.view.bounds.size.height
        let rectOfInterestHeight = (scanRectView?.bounds.size.width)!/self.view.bounds.size.width
        let rectOfInterestX = (scanRectView?.frame.origin.y)!/self.view.bounds.size.height
        let rectOfInterestY = (scanRectView?.frame.origin.x)!/self.view.bounds.size.width

        output?.rectOfInterest = CGRect.init(x: rectOfInterestX, y: rectOfInterestY, width: rectOfInterestWidth, height: rectOfInterestHeight);

        let rect = CGRect.init(x: self.view.frame.origin.x, y: self.view.frame.origin.y, width: self.view.frame.size.width, height: self.view.frame.size.height-49)
        
        UIGraphicsBeginImageContext(rect.size)
        let context: CGContext? = UIGraphicsGetCurrentContext()
        context?.setFillColor(UIColor.black.withAlphaComponent(0.6).cgColor);
        context?.fill(rect)
        context?.clear((scanRectView?.frame)!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        scanBackView?.image = image
    }
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        if(metadataObjects.count>0){
            let object: AVMetadataMachineReadableCodeObject = metadataObjects.first as! AVMetadataMachineReadableCodeObject
//             object.stringValue
            
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
