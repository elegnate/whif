
class OTPViewController : UIViewController {
    
    @IBOutlet weak var imageviewIcon: UIImageView!
    
    @IBOutlet weak var labelResTitle: UILabel!
    @IBOutlet weak var labelBirth: UILabel!
    @IBOutlet weak var labelResContent: UILabel!
    @IBOutlet weak var labelId: UILabel!
    
    var loginData: Network.loginResponseData?
    var otpCode:   String?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let loginData = loginData, let otpCode = otpCode, otpCode.isIdentityVerifyOTP() {
            let requirer = String(otpCode[otpCode.startIndex...otpCode.index(otpCode.startIndex, offsetBy: 3)])
            let code     = String(otpCode[otpCode.index(otpCode.startIndex, offsetBy: 4)..<otpCode.endIndex])
            let otp      = OTP(phone: loginData.phone, verifier: requirer)
            
            if code.isNumber(), otp.Verify(otpCode: code) {
                self.imageviewIcon.image  = #imageLiteral(resourceName: "success")
                self.labelResTitle.text   = "신분번호 검증에 성공했어요!"
                self.labelResContent.text = "신분증을 신뢰할 수 있습니다. 신분증 이미지를 확인하세요."
                self.labelId.text         = requirer
                self.labelBirth.text      = code
            } else {
                self.labelResTitle.text   = "신분번호 검증에 실패했어요."
                self.labelResContent.text = "유효기간이 만료되었거나 위·변조된 신분증으로 신뢰할 수 없습니다."
            }
        } else {
            dismiss(animated: false, completion: nil)
        }
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        get {
            return .portrait
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    
    @IBAction func pressRetryScan(_ sender: Any) {
        let vc = self.presentingViewController as! ViewController
        self.dismiss(animated: false, completion: nil)
        vc.performSegue(withIdentifier: "Recog", sender: vc)
    }
    
    
    @IBAction func pressExit(_ sender: Any) {
        self.dismiss(animated: false, completion: nil)
    }
}
