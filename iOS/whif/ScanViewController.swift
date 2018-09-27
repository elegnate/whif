
import UIKit
import AVKit


class ScanViewController: UIViewController {

    @IBOutlet weak var viewFinder: UIView!
    @IBOutlet weak var viewNonDetector: UIView!
    @IBOutlet weak var viewDetector: DesignableView!
    @IBOutlet weak var buttonFlash: UIButton!
    
    var rectViewFinder: CGRect!
    var scalePicture: CGSize!
    var cardLayerMask: CALayer!
    let lineDetectId = CAShapeLayer()
    
    var tesseract: G8Tesseract = G8Tesseract(language: "kor")
    var beforeSeconds: Int = 0
    var captureSession: AVCaptureSession!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .hd1920x1080
        
        guard let captureDevice = AVCaptureDevice.default(for: .video) else { return }
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else { return }
        captureSession.addInput(input)
        captureSession.startRunning()
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        viewFinder.layer.addSublayer(previewLayer)
        previewLayer.frame = viewFinder.frame
        
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(dataOutput)
        
        lineDetectId.frame = viewDetector.bounds
        lineDetectId.fillColor = UIColor(red:1.0, green:1.0, blue:1.0, alpha:0.5).cgColor
        lineDetectId.strokeColor = UIColor.clear.cgColor
        lineDetectId.cornerRadius = 12
        cardLayerMask = GetShapeCardLayer(targetViewRect: viewNonDetector.bounds,
                                          cardViewRect: viewDetector.frame)
        viewNonDetector.layer.mask = cardLayerMask
        scalePicture = CGSize(width: 1920 / viewFinder.frame.height,
                                   height: 1080  / viewFinder.frame.width)
        rectViewFinder = viewDetector.getAbsoluteRect(viewFinder.frame.origin.y, scale: scalePicture)
        
        tesseract.delegate = self
        tesseract.charWhitelist = "0123456789-~'`_"
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        get { return .portrait }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func GetShapeCardLayer(targetViewRect: CGRect,
                                   cardViewRect: CGRect,
                                   cornerRadius: CGFloat = 12) -> CALayer {
        let maskLayer = CALayer()
        let cardLayer = CAShapeLayer()
        
        maskLayer.frame = targetViewRect
        cardLayer.frame = targetViewRect
        
        let finalPath = UIBezierPath(roundedRect: targetViewRect, cornerRadius: 0)
        let cardPath  = UIBezierPath(roundedRect: cardViewRect, cornerRadius: cornerRadius)
        
        finalPath.append(cardPath.reversing())
        cardLayer.path = finalPath.cgPath
        maskLayer.addSublayer(cardLayer)
        return maskLayer
    }
    
    
    @IBAction func pressFlash(_ sender: Any) {
        guard let device = AVCaptureDevice.default(for: .video) else { return }
        
        if device.hasTorch {
            do {
                try device.lockForConfiguration()
                
                if device.torchMode == .on {
                    device.torchMode = .off
                    self.buttonFlash.setImage(#imageLiteral(resourceName: "flashoff"), for: .normal)
                } else {
                    device.torchMode = .on
                    self.buttonFlash.setImage(#imageLiteral(resourceName: "flashon"), for: .normal)
                }
                device.unlockForConfiguration()
            } catch {
            }
        }
    }
    
    @IBAction func pressExit(_ sender: Any) {
        dismiss(animated: false, completion: nil)
    }
}


extension ScanViewController: G8TesseractDelegate {
    
}


extension ScanViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        let seconds = Int(CMSampleBufferGetPresentationTimeStamp(sampleBuffer).seconds * 10)
        
        if seconds % 5 != 0 || beforeSeconds == seconds {
            return
        } else {
            beforeSeconds = seconds
        }
        if connection.videoOrientation != .portrait {
            connection.videoOrientation = .portrait
            return
        }
        
        if let imageBuf: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
            let ciimage = CIImage(cvImageBuffer: imageBuf)
            let context = CIContext(options: nil)
            
            guard let image = self.DetectCard(image: context.createCGImage(ciimage, from: ciimage.extent)!,
                                              findAreaRect: self.rectViewFinder) else { return }
            let y    = image.extent.size.height / 3
            let rect = CGRect(x: image.extent.size.width / 12, y: y,
                              width: image.extent.size.width / 2,
                              height: image.extent.size.height / 2 - y)
            let cgImage  = context.createCGImage(image, from: image.extent)
            let cutImage = UIImage(cgImage: cgImage!.cropping(to: rect)!).g8_blackAndWhite()!
            self.tesseract.image = cutImage
            self.tesseract.recognize()
            let text = self.tesseract.recognizedText!.GetLines()
            
            if let id = text.first?.GetId(), let cgImage = cgImage {
                guard let vc = presentingViewController as? SignUpViewController else { return }
                let imageId = UIImage(cgImage: cgImage)
                DispatchQueue.main.async {
                    vc.textfieldId.text = id
                    vc.buttonIdCapture.setBackgroundImage(imageId, for: .normal)
                    self.dismiss(animated: false, completion: nil)
                }
            }
            
            G8Tesseract.clearCache()
        }
    }
    
    private func DrawDetectArea(rect: CIRectangleFeature, scale: CGFloat) {
        let selfCenterY = (rect.bottomLeft.y + rect.bottomRight.y + rect.topLeft.y + rect.topRight.y) / 4
        let superCenterY = self.viewDetector.frame.height / 2
        let tl = self.ReversePoint(rect.topLeft, selfCenterY, superCenterY, scale)
        let path = UIBezierPath()
        
        path.move(to: tl)
        path.addLine(to: self.ReversePoint(rect.topRight, selfCenterY, superCenterY, scale))
        path.addLine(to: self.ReversePoint(rect.bottomRight, selfCenterY, superCenterY, scale))
        path.addLine(to: self.ReversePoint(rect.bottomLeft, selfCenterY, superCenterY, scale))
        path.addLine(to: tl)
        path.close()
        
        self.lineDetectId.path = path.cgPath
        self.viewDetector.layer.addSublayer(self.lineDetectId)
    }
    
    private func ReversePoint(_ origin: CGPoint,
                              _ selfCenterY: CGFloat,
                              _ superCenterY: CGFloat,
                              _ scale: CGFloat) -> CGPoint {
        var ret: CGPoint = CGPoint(x: 0.0, y: 0.0)
        
        if origin.y > selfCenterY {
            ret.y = selfCenterY - (origin.y - selfCenterY)
        } else {
            ret.y = selfCenterY + (selfCenterY - origin.y)
        }
        
        ret.x = origin.x * scale
        ret.y *= scale
        ret.y -= (selfCenterY * scale - superCenterY) * 2
        return ret
    }
    
    private func DetectCard(image: CGImage, findAreaRect: CGRect) -> CIImage? {
        if let cropImage = image.cropping(to: findAreaRect) {
            let ciImage  = CIImage(cgImage: cropImage)
            let detectorRectangle = CIDetector(ofType: CIDetectorTypeRectangle, context: nil,
                                               options: [CIDetectorAccuracy: CIDetectorAccuracyHigh,
                                                         CIDetectorAspectRatio: 8560 / 5398])
            let featuresRectangle = detectorRectangle?.features(in: ciImage)
            
            for feature in featuresRectangle as! [CIRectangleFeature] {
                if fabs(feature.topRight.x - feature.topLeft.x) > fabs(feature.bottomLeft.y - feature.topLeft.y) * 1.4 {
                    let perspectiveCorrection = CIFilter(name: "CIPerspectiveCorrection")
                    
                    perspectiveCorrection?.setValue(ciImage, forKey: "inputImage")
                    perspectiveCorrection?.setValue(CIVector(cgPoint: feature.topLeft), forKey: "inputTopLeft")
                    perspectiveCorrection?.setValue(CIVector(cgPoint: feature.topRight), forKey: "inputTopRight")
                    perspectiveCorrection?.setValue(CIVector(cgPoint: feature.bottomLeft), forKey: "inputBottomLeft")
                    perspectiveCorrection?.setValue(CIVector(cgPoint: feature.bottomRight), forKey: "inputBottomRight")
                    
                    if let outputImage = perspectiveCorrection?.outputImage {
                        DispatchQueue.main.async {
                            let scale = self.viewDetector.frame.width / ciImage.extent.width
                            self.DrawDetectArea(rect: feature, scale: scale)
                        }
                        return outputImage
                    }
                }
            }
        }
        
        return nil
    }
}

