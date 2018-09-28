
import LocalAuthentication


class ProofViewController: UIViewController, UIScrollViewDelegate {
    
    @IBOutlet weak var labelOTP: UILabel!
    @IBOutlet weak var labelRequirer: UILabel!
    @IBOutlet weak var labelRemainTime: UILabel!
    @IBOutlet weak var labelTtitle: UILabel!
    @IBOutlet weak var buttonMosaicRestore: UIButton!
    
    @IBOutlet weak var scrollviewID: DesignableScrollView!
    @IBOutlet weak var imageviewID: DesignableImageView!
    @IBOutlet weak var imageviewBarcode: UIImageView!
    
    var loginData: Network.loginResponseData?
    var identityData: Network.identityResponseData?
    
    var validTimestamp: Int64?
    var timer: Timer?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let identityData = identityData, let loginData = loginData else {
            dismiss(animated: false, completion: nil)
            return
        }
        imageviewID.image = UIImage(data: Data(base64Encoded: identityData.image)!)
        labelTtitle.text = "\(loginData.name)님의 신분증"
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy'-'MM'-'dd  HH':'mm':'ss"
        validTimestamp = formatter.date(from: identityData.validDate)?.timestamp
        
        var code = identityData.verifyNumber
        code.insert(" ", at: code.index(code.startIndex, offsetBy: 4))
        code.insert(" ", at: code.index(code.startIndex, offsetBy: 8))
        
        buttonMosaicRestore.setTitle(identityData.validDate, for: .normal)
        labelRequirer.text = identityData.requirerName
        labelOTP.text = code
        labelRemainTime.text = String(validTimestamp! - Date().timestamp)
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timerCallback), userInfo: nil, repeats: true)
        imageviewBarcode.image = identityData.verifyNumber.generateBarcode()
        scrollviewID.delegate = self
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        get {
            return .portrait
        }
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imageviewID
    }
    
    //타이머가 호출하는 콜백함수
    @objc func timerCallback(){
        let remain = self.validTimestamp! - Date().timestamp
        self.labelRemainTime.text = String(remain)
        
        if remain > 0 {
            return
        }
        if let timer = self.timer {
            if timer.isValid {
                timer.invalidate()
                self.presentingViewController?.dismiss(animated: false, completion: nil)
            }
        }
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Barcode" {
            let vc = segue.destination as? BarcodeViewController
            vc?.imageBarcode = self.imageviewBarcode.image
            vc?.txtBarcode = self.labelOTP.text
        }
    }
    
    @IBAction func pressExit(_ sender: Any) {
        if let timer = self.timer {
            if timer.isValid {
                timer.invalidate()
            }
        }
        self.dismiss(animated: false, completion: nil)
    }
    
    @IBAction func pressExpansionBarcode(_ sender: Any) {
        self.performSegue(withIdentifier: "Barcode", sender: self)
    }
}
