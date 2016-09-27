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

        let onColor: CIColor = CIColor.init(cgColor: UIColor.clear.cgColor)
        let offColor: CIColor = CIColor.init(cgColor: UIColor.blue.withAlphaComponent(0.7).cgColor)
        
        let colorFilter: CIFilter = CIFilter.init(name: "CIFalseColor")!
        colorFilter.setValue(filter.outputImage, forKey: "inputImage")
        colorFilter.setValue(onColor, forKey: "inputColor0")
        colorFilter.setValue(offColor, forKey: "inputColor1")

        let ciImage: CIImage? = colorFilter.outputImage
        guard (ciImage != nil) else {
            return
        }
        let avatar: UIImage = UIImage.init(named: "Snip20160927_1")!
        let size: CGSize = CGSize.init(width: 300, height: 300)
        let cgImage = CIContext.init().createCGImage(ciImage!, from: ciImage!.extent)
        UIGraphicsBeginImageContext(size)
        let context: CGContext? = UIGraphicsGetCurrentContext()
        context!.interpolationQuality = .none;
        context?.scaleBy(x: 1.0, y: -1.0)
        context?.draw(avatar.cgImage!, in: context!.boundingBoxOfClipPath)
        context?.draw(cgImage!, in: CGRect.init(x: 30, y: 30-300, width: 240, height: 240))
        context?.draw(avatar.cgImage!, in: CGRect.init(x: 130, y: 130-300, width: 40, height: 40))
        //得分开画头像，得到圆角头像再画在中间
        //let xx: UIBezierPath = UIBezierPath.init(roundedRect: CGRect.init(x: 130, y: 130-300, width: 40, height: 40), cornerRadius: 10)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        imageView?.image = image

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
    
    

}
