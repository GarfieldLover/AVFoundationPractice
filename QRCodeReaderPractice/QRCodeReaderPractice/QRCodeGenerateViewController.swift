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

        let ciImage: CIImage? = filter.outputImage
        guard (ciImage != nil) else {
            return
        }
        DemoQRcode
        //zk 不够清晰
        let size: CGSize = CGSize.init(width: 300, height: 300)
        let cgImage = CIContext.init().createCGImage(ciImage!, from: ciImage!.extent)
        UIGraphicsBeginImageContext(size)
        let context: CGContext? = UIGraphicsGetCurrentContext()
        context?.scaleBy(x: 1.0, y: -1.0)
        context?.draw(cgImage!, in: context!.boundingBoxOfClipPath)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        imageView?.image = image

        
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
