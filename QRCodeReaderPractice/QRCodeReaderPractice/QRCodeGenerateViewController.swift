//
//  QRCodeGenerateViewController.swift
//  QRCodeReaderPractice
//
//  Created by ZK on 2016/9/23.
//  Copyright © 2016年 ZK. All rights reserved.
//

import UIKit

class QRCodeGenerateViewController: UIViewController {
    
    @IBOutlet weak var textView: UITextView?
    @IBOutlet weak var generateButton: UIButton?
    @IBOutlet weak var imageView: UIImageView?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    @IBAction func generateImage() -> Void {
        
        let text = self.textView?.text
        let data: Data? = text?.data(using: .utf8)

        let filter: CIFilter = CIFilter.init(name: "CIQRCodeGenerator")!
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("H", forKey: "inputCorrectionLevel")

        let onColor: CIColor = CIColor.init(cgColor: UIColor.brown.cgColor)
        let offColor: CIColor = CIColor.init(cgColor: UIColor.lightGray.cgColor)
        
        let colorFilter: CIFilter = CIFilter.init(name: "CIFalseColor")!
        colorFilter.setValue(filter.outputImage, forKey: "inputImage")
        colorFilter.setValue(onColor, forKey: "inputColor0")
        colorFilter.setValue(offColor, forKey: "inputColor1")

        let ciImage: CIImage? = colorFilter.outputImage
        guard (ciImage != nil) else {
            return
        }

        let size: CGSize = CGSize.init(width: 300, height: 300)
        let cgImage = CIContext.init().createCGImage(ciImage!, from: ciImage!.extent)
        UIGraphicsBeginImageContext(size)
        let context: CGContext? = UIGraphicsGetCurrentContext()
        context!.interpolationQuality = .none;
        context?.scaleBy(x: 1.0, y: -1.0)
        context?.draw(cgImage!, in: context!.boundingBoxOfClipPath)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        imageView?.image = image
        
//        // 通常,二维码都是定制的,中间都会放想要表达意思的图片
//        if let iconImage = UIImage(named: qrImageName!) {
//            let rect = CGRectMake(0, 0, codeImage.size.width, codeImage.size.height)
//            UIGraphicsBeginImageContext(rect.size)
//            
//            codeImage.drawInRect(rect)
//            let avatarSize = CGSizeMake(rect.size.width * 0.25, rect.size.height * 0.25)
//            let x = (rect.width - avatarSize.width) * 0.5
//            let y = (rect.height - avatarSize.height) * 0.5
//            iconImage.drawInRect(CGRectMake(x, y, avatarSize.width, avatarSize.height))
//            let resultImage = UIGraphicsGetImageFromCurrentImageContext()
//            
//            UIGraphicsEndImageContext()
//            return resultImage
//        }

        
    }
    
    @IBAction func generateBarCodeImage() -> Void {
        
        let text = self.textView?.text
        let data: Data? = text?.data(using: .utf8)
        
        let filter: CIFilter = CIFilter.init(name: "CICode128BarcodeGenerator")!
        filter.setValue(data, forKey: "inputMessage")
        
        let onColor: CIColor = CIColor.init(cgColor: UIColor.brown.cgColor)
        let offColor: CIColor = CIColor.init(cgColor: UIColor.lightGray.cgColor)
        
        let colorFilter: CIFilter = CIFilter.init(name: "CIFalseColor")!
        colorFilter.setValue(filter.outputImage, forKey: "inputImage")
        colorFilter.setValue(onColor, forKey: "inputColor0")
        colorFilter.setValue(offColor, forKey: "inputColor1")
        
        let ciImage: CIImage? = colorFilter.outputImage
        guard (ciImage != nil) else {
            return
        }
        
        let height = ciImage!.extent.height
        let width = ciImage!.extent.width

        imageView?.frame = CGRect.init(x: (self.view.bounds.size.width-width)/2, y: 300, width: width, height: height)
        imageView?.image = UIImage.init(ciImage: ciImage!)
        
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
