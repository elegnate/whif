
import LocalAuthentication


class ViewController: UIViewController {

    @IBOutlet weak var viewShowEID: DesignableView!
    @IBOutlet weak var imageviewGender: UIImageView!
    @IBOutlet weak var imageviewFingerprint: UIImageView!
    @IBOutlet weak var imageviewTitleIcon: UIImageView!
    @IBOutlet weak var viewInput: UIView!
    @IBOutlet weak var imageviewBarcode: UIImageView!
    
    @IBOutlet weak var labelMyName: UILabel!
    @IBOutlet weak var labelMyBirth: UILabel!
    @IBOutlet weak var labelMyReg: UILabel!
    @IBOutlet weak var buttonUseFingerprint: UIButton!
    @IBOutlet weak var buttonExpansionBarcode: UIButton!
    @IBOutlet weak var textfieldProof: UITextField!
    @IBOutlet weak var labelAlert: UILabel!
    @IBOutlet weak var viewKeyboardToolbar: UIView!
    @IBOutlet weak var progressLoading: UIProgressView!
    
    @IBOutlet weak var constraintBottomKeyboardToolbar: NSLayoutConstraint!
    
    var originYShowEID: CGFloat = 0.0
    var moveYShowEID: CGFloat = 0.0
    var originShowEID: CGPoint!
    
    var isUseBiometric: Bool = false
    
    var network: Network?
    var loginData: Network.loginResponseData?
    var challengeData: Network.challengeResponseData?
    var identityData: Network.identityResponseData?
    
    var barcodeValue: String?
    
    var sessionTimestamp: Int64?
    var timer: Timer?
    var isRunningBiometricAuthentication: Bool = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: Notification.Name.UIKeyboardWillShow, object: nil)
        notificationCenter.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: Notification.Name.UIKeyboardWillHide, object: nil)
        notificationCenter.addObserver(self, selector: #selector(appMovedToBackground), name: Notification.Name.UIApplicationWillResignActive, object: nil)
        notificationCenter.addObserver(self, selector: #selector(appMovedToForeground), name: Notification.Name.UIApplicationDidBecomeActive, object: nil)
        
        let panGestureRecognizer = UIPanGestureRecognizer(target: self,
                                                          action: #selector(panGestureRecognizerAction(_:)))
        self.viewShowEID.addGestureRecognizer(panGestureRecognizer)
        
        // 메인 화면 애니메이션
        self.originYShowEID = self.viewShowEID.frame.origin.y
        self.moveYShowEID = self.viewInput.frame.origin.y + self.viewInput.frame.height + 10.0
        
        if let loginData = loginData {
            if loginData.birth != "" {
                let arr = loginData.birth.split(separator: "-")
                let birth = Int(arr[0])!
                let yy = String(Int(birth / 10000))
                let mm = String(Int((birth % 10000) / 100))
                let dd = String(birth % 100)
                
                if Int(arr[1])! % 2 == 0 {
                    imageviewGender.image = UIImage(named: "woman")
                }
                labelMyBirth.text = yy + "년 " + mm + "월 " + dd + "일"
                labelMyReg.text = "등록일\n" + loginData.regDate
            } else {
                labelMyBirth.text = "등록된 신분증이 없어요."
            }
            labelMyName.text = loginData.name
            imageviewBarcode.image = loginData.phone.generateBarcode()
        }
        
        if FileIO("my", directory: "id").isExist() {
            self.buttonUseFingerprint.alpha = 1.0
            self.imageviewFingerprint.alpha = 1.0
            isUseBiometric = true
        }
        
        network = Network()
        network?.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if let network = network, let barcodeValue = barcodeValue {
            textfieldProof.text = barcodeValue
            if barcodeValue.isPhone() {
                network.challenge(mode: .identity)
            } else if barcodeValue.isIdentityVerifyOTP() {
                performSegue(withIdentifier: "Verify", sender: self)
            }
        } else {
            textfieldProof.text = ""
        }
        barcodeValue = nil
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        get {
            return .portrait
        }
    }
    
    @objc func appMovedToBackground() {
        if !isRunningBiometricAuthentication {
            let imageview = UIImageView(frame: CGRect(x: view.frame.width / 2 - 50, y: view.frame.height / 2 - 60,
                                                      width: 100, height: 100))
            imageview.image = #imageLiteral(resourceName: "whif")
            view.addWaitingView(imageview, backgroundColor: UIColor.white)
            presentedViewController?.dismiss(animated: false, completion: nil)
            sessionTimestamp = Date().timestamp + 60 * 5
            timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timerCallback), userInfo: nil, repeats: true)
        }
    }
    
    @objc func appMovedToForeground() {
        if !isRunningBiometricAuthentication {
            view.removeWaitingView()
            if let timer = timer {
                if timer.isValid {
                    timer.invalidate()
                }
            }
        }
    }
    
    @objc func timerCallback(){
        guard let timestamp = sessionTimestamp else { return }
        if timestamp - Date().timestamp > 0       { return }
        if let timer = timer {
            if timer.isValid {
                timer.invalidate()
                presentingViewController?.dismiss(animated: false, completion: nil)
            }
        }
    }
    
    @objc func keyboardWillShow(_ notification:NSNotification) {
        self.moveToolBar(isUp: true, with: notification)
    }
    
    @objc func keyboardWillHide(_ notification:NSNotification) {
        self.moveToolBar(isUp: false, with: notification)
    }
    
    fileprivate func moveToolBar(isUp up:Bool, with notification:NSNotification) {
        if let userInfo = notification.userInfo {
            let endFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
            let duration = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
            let animationOptions = UIViewAnimationOptions(rawValue: (userInfo[UIKeyboardAnimationCurveUserInfoKey] as! NSNumber).uintValue)
            
            var toolbarMoveY = endFrame.height
            var alpha: CGFloat = 1.0
            
            if !up {
                toolbarMoveY = -self.viewKeyboardToolbar.frame.height
                alpha = 0.0
            }
            self.constraintBottomKeyboardToolbar.constant = toolbarMoveY
            UIView.animate(withDuration: duration,
                           delay: 0.0,
                           options: animationOptions,
                           animations: { () -> Void in
                            self.view.layoutIfNeeded()
                            self.viewKeyboardToolbar.alpha = alpha
            }, completion: nil)
        }
    }
    
    @objc func panGestureRecognizerAction(_ gesture: UIPanGestureRecognizer) {
        if gesture.state == .began {
            self.originShowEID = viewShowEID.frame.origin
        }
        
        let translation = gesture.translation(in: viewShowEID)
        let originYMoveShow = self.originShowEID.y + translation.y
        
        if self.moveYShowEID < originYMoveShow && originYMoveShow < self.originYShowEID {
            self.viewShowEID.frame.origin.y = originYMoveShow
        }
        
        if gesture.state == .ended {
            let velocity = gesture.velocity(in: viewShowEID)
            
            if velocity.y < 10 {
                animateViewEID(isUp: true)
            } else if velocity.y > 10 {
                animateViewEID(isUp: false)
            }
        }
    }
    
    func animateViewEID(isUp: Bool) {
        var moveY: CGFloat = -20.0 + self.moveYShowEID
        var bounceY: CGFloat = 10.0
        var titleIcon: String = "downw"
        
        if !isUp {
            moveY = self.originYShowEID + 10.0
            bounceY = -10.0
            titleIcon = "upw"
        }
        
        UIView.animate(withDuration: 0.3, animations: {
            self.viewShowEID.frame.origin.y = moveY
        })
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            UIView.animate(withDuration: 0.2, animations: {
                self.viewShowEID.frame.origin.y = moveY + bounceY
            })
        }
        self.imageviewTitleIcon.image = UIImage(named: titleIcon)
    }
    
    
    @IBAction func pressKeyboardHide(_ sender: Any) {
        self.view.endEditing(true)
    }
    
    @IBAction func pressRecog(_ sender: Any) {
        self.performSegue(withIdentifier: "Recog", sender: self)
    }
    
    @IBAction func pressProof(_ sender: Any) {
        let value = textfieldProof.text!
        if value.count == 11 && value.isPhone() {
            isRunningBiometricAuthentication = (network?.authentificationBiometric(mode: .identity))!
        } else if value.isIdentityVerifyOTP() {
            performSegue(withIdentifier: "Verify", sender: self)
        }
        self.view.endEditing(true)
    }
    
    @IBAction func pressExpansionBarcode(_ sender: Any) {
        self.performSegue(withIdentifier: "Barcode", sender: self)
    }
    
    @IBAction func touchdownProof(_ sender: Any) {
        viewShowEID.frame.origin.y = self.originYShowEID
        imageviewTitleIcon.image = UIImage(named: "upw")
    }
    
    @IBAction func pressWithdrawal(_ sender: Any) {
        network?.withdrawal()
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Recog" {
            let vc = segue.destination as! RecogViewController
            vc.loginData = loginData
        } else if segue.identifier == "ProofSeg" {
            let vc = segue.destination as! ProofViewController
            vc.identityData = identityData
            vc.loginData    = loginData
        } else if segue.identifier == "Verify" {
            let vc = segue.destination as! OTPViewController
            vc.loginData = loginData
            vc.otpCode   = textfieldProof.text
        } else if segue.identifier == "Barcode" {
            let vc = segue.destination as! BarcodeViewController
            vc.txtBarcode   = loginData?.phone
            vc.imageBarcode = imageviewBarcode.image
        }
    }
}


extension ViewController: NetworkDelegate {
    
    func networkBegined() {
        progressLoading.startLoading()
    }
    
    func networkEnded() {
        progressLoading.setLoading(0.5)
    }
    
    func networkError(result: Network.Result) {
        labelAlert.autoFadeOut(result.error.rawValue)
        networkEnded()
        progressLoading.endLoading()
    }
    
    func networkResponse(data: Data, mode: Network.responseMode) {
        do {
            if mode == .challenge {
                challengeData = try JSONDecoder().decode(Network.challengeResponseData.self, from: data)
                let content = Data(base64Encoded: challengeData!.challenge)!
                guard let challenge = network?.decryptForPrivate(content:content) else {
                    return
                }
                DispatchQueue.main.async {
                    self.network?.identity(challenge: challenge, requirer: self.textfieldProof.text!)
                }
                isRunningBiometricAuthentication = false
            } else if mode == .identity {
                identityData = try JSONDecoder().decode(Network.identityResponseData.self, from: data)
                if let network = network, let identityData = identityData, !identityData.error {
                    if network.verifySignature(signData: identityData) {
                        DispatchQueue.main.async {
                            self.performSegue(withIdentifier: "ProofSeg", sender: self)
                        }
                    }
                } else {
                    networkError(result: .failure(.identity))
                }
            } else if mode == .withdrawal {
                let withdrawalData = try JSONDecoder().decode(Network.withdrawalResponseData.self, from: data)
                if !withdrawalData.error {
                    DispatchQueue.main.async {
                        self.presentingViewController?.dismiss(animated: true, completion: nil)
                    }
                    FileIO("my", directory: "id").remove()
                } else {
                    networkError(result: .failure(.withdrawal))
                }
            }
        } catch {
            networkError(result: .failure(.invalidJson))
        }
    }
}
