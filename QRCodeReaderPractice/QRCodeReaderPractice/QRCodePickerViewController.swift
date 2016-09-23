//
//  QRCodePickerViewController.swift
//  QRCodeReaderPractice
//
//  Created by ZK on 2016/9/23.
//  Copyright © 2016年 ZK. All rights reserved.
//

import UIKit

class QRCodePickerViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var pickerButton: UIButton?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    @IBAction func pickerImage() -> Void {
        let imagePicker: UIImagePickerController = UIImagePickerController.init()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        self.present(imagePicker, animated: true, completion: nil)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true, completion: nil)
        
        let image: UIImage = info[UIImagePickerControllerOriginalImage] as! UIImage
        
        let context: CIContext = CIContext.init()
        //检测器
        let detector: CIDetector = CIDetector.init(ofType: CIDetectorTypeQRCode, context: context, options: [CIDetectorAccuracy:CIDetectorAccuracyHigh])!
        let ciimage = CIImage.init(image: image)
        //识别
        let features: Array = detector.features(in: ciimage!)
        //是否有二维码
        guard features.count>0 else {
            let alert: UIAlertController = UIAlertController.init(title: "无法识别", message: nil, preferredStyle: .alert)
            let alertAction: UIAlertAction = UIAlertAction.init(title: "好", style: .cancel, handler: { (alert) in
            })
            alert.addAction(alertAction)
            self.present(alert, animated: true, completion: nil)
            return;
        }
        
        let feature: CIQRCodeFeature = features.first as! CIQRCodeFeature
        
        let alert: UIAlertController = UIAlertController.init(title: feature.messageString, message: nil, preferredStyle: .alert)
        let alertAction: UIAlertAction = UIAlertAction.init(title: "好", style: .cancel, handler: { (alert) in
        })
        alert.addAction(alertAction)
        self.present(alert, animated: true, completion: nil)
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
