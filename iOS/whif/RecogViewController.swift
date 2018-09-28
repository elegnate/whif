
import AVFoundation


class RecogViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    @IBOutlet weak var viewRender: UIView!
    @IBOutlet weak var buttonFlash: UIButton!
    
    var video: AVCaptureVideoPreviewLayer!
    var session: AVCaptureSession!
    
    var loginData: Network.loginResponseData?
    
    
    /** */
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.session = AVCaptureSession()
        guard let captureDevice = AVCaptureDevice.default(for: AVMediaType.video) else { return }
        
        do {
            let input = try AVCaptureDeviceInput(device: captureDevice)
            self.session.addInput(input)
        } catch {
            print("AVCaptureDeviceInput Error!")
            return
        }
        
        let output = AVCaptureMetadataOutput()
        self.session.addOutput(output)
        
        output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        output.metadataObjectTypes = [AVMetadataObject.ObjectType.code128]
        
        self.video = AVCaptureVideoPreviewLayer(session: self.session)
        self.video.frame = self.viewRender.layer.bounds
        self.viewRender.layer.addSublayer(self.video)
    
        self.session.startRunning()
    }
    
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    
    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let text = readableObject.stringValue else { return }
            
            if text.count == 11 || text.count == 10 {
                var isValidCode: Bool = false
                
                if let loginData = loginData, text.isPhone(), loginData.birth != "" {
                    isValidCode = true
                } else if text.isIdentityVerifyOTP() {
                    isValidCode = true
                }
                if isValidCode {
                    self.session.stopRunning()
                    let vc = self.presentingViewController as! ViewController
                    vc.barcodeValue = text
                    self.dismiss(animated: false, completion: nil)
                }
            }
        }
    }
    
    
    @IBAction func pressFlash(_ sender: Any) {
        guard let device = AVCaptureDevice.default(for: .video) else { return }
        
        if device.hasTorch {
            do {
                try device.lockForConfiguration()
                
                if device.torchMode == .on {
                    device.torchMode = .off
                    self.buttonFlash.setImage(UIImage(named: "flashoff"), for: .normal)
                } else {
                    device.torchMode = .on
                    self.buttonFlash.setImage(UIImage(named: "flashon"), for: .normal)
                }
                device.unlockForConfiguration()
            } catch {
                print("Torch could not be used")
            }
        } else {
            print("Torch is not available")
        }
    }
    
    @IBAction func pressExit(_ sender: Any) {
        self.session.stopRunning()
        self.dismiss(animated: true, completion: nil)
    }
}
