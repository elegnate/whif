
import LocalAuthentication


class SignUpViewController: UIViewController,
                             //UIPickerViewDelegate, UIPickerViewDataSource,
                             UITextFieldDelegate {
    
    enum typeOfRequiredFieldCheck: Int {
        case name = 1
        case password = 2
        case id = 4
        case noIdCard = 3
        case all = 7
    }
    
    //@IBOutlet weak var textfieldAgency: DesignableTextField!
    @IBOutlet weak var viewPasswordCheck: UIView!
    @IBOutlet weak var imageviewNameCheck: DesignableImageView!
    @IBOutlet weak var textfieldPassword: UITextField!
    @IBOutlet weak var textfieldName: UITextField!
    @IBOutlet weak var textfieldId: UITextField!
    @IBOutlet weak var buttonIdCapture: DesignableButton!
    @IBOutlet weak var labelAlert: UILabel!
    
    @IBOutlet weak var constraintIdCaptureTop: NSLayoutConstraint!
    //let pickOptions = ["-", "SKT", "LG U+", "KT"]
    
    var requiredFieldCheck: Int = 0
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.hideKeyboardWhenTappedAround()
        NotificationCenter.default.addObserver(self, selector: #selector(KeyboardWillShow(_:)), name: Notification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(KeyboardWillHide(_:)), name: Notification.Name.UIKeyboardWillHide, object: nil)
        
        //let pickerview = UIPickerView()
        //pickerview.delegate = self
        //self.textfieldAgency.inputView = pickerview
        textfieldPassword.delegate = self
        textfieldId.delegate = self
        textfieldName.delegate = self
    }
    
    
    @objc func KeyboardWillShow(_ notification:NSNotification) {
        self.MoveToolBar(isUp: true, with: notification)
    }
    
    
    @objc func KeyboardWillHide(_ notification:NSNotification) {
        self.MoveToolBar(isUp: false, with: notification)
    }
    
    
    fileprivate func MoveToolBar(isUp up:Bool, with notification:NSNotification) {
        if let userInfo = notification.userInfo {
            let endFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
            let duration = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
            let animationOptions = UIViewAnimationOptions(rawValue: (userInfo[UIKeyboardAnimationCurveUserInfoKey] as! NSNumber).uintValue)
            
            let distanace = self.view.frame.height > 800 ? 50 : -endFrame.height / 3
            let move = up ? distanace : 50
            
            self.constraintIdCaptureTop.constant = move
            UIView.animate(withDuration: duration,
                           delay: 0.0,
                           options: animationOptions,
                           animations: { () -> Void in
                            self.view.layoutIfNeeded()
            }, completion: nil)
        }
    }
    
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        get { return .portrait }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.dismissKeyboard()
        return true
    }
    
    /*
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.pickOptions.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return self.pickOptions[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if row != 0 {
            self.textfieldAgency.text = self.pickOptions[row]
            self.view.endEditing(true)
        }
    }
    */
    
    
    func editRequiredFiledCheck(_ type: typeOfRequiredFieldCheck, isAdd: Bool) {
        if isAdd && !isEnteredRequiredField(type) {
            requiredFieldCheck += type.rawValue
        } else if !isAdd && isEnteredRequiredField(type) {
            requiredFieldCheck -= type.rawValue
        }
    }
    
    func isEnteredRequiredField(_ type: typeOfRequiredFieldCheck) -> Bool {
        let value = type.rawValue
        return requiredFieldCheck & value == value
    }
    
    
    func authenticationFido() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "생체정보를 입력해주세요.") {
                [unowned self] success, authenticationError in
                DispatchQueue.main.async {
                    if !success {
                        self.labelAlert.autoFadeOut("생체 인증에 실패했습니다.")
                    } else {
                        self.performSegue(withIdentifier: "CaptureSeg", sender: self)
                    }
                }
            }
        } else {
            labelAlert.autoFadeOut("생체 인증이 가능한 장치만 사용할 수 있습니다.")
        }
    }
    
    @IBAction func pressCapture(_ sender: Any) {
        authenticationFido()
    }
    
    @IBAction func pressPasswordReset(_ sender: Any) {
        textfieldPassword.text = ""
        viewPasswordCheck.isHidden = true
    }
    
    @IBAction func editingPin(_ sender: Any) {
        let value = textfieldPassword.text!.isPIN()
        viewPasswordCheck.isHidden = !value
        editRequiredFiledCheck(.password, isAdd: value)
        if value {
            dismissKeyboard()
        }
    }
    
    @IBAction func beginPin(_ sender: Any) {
        //performSegue(withIdentifier: "SignUpPinSeg", sender: self)
    }
    
    @IBAction func editingName(_ sender: Any) {
        let value = textfieldName.text!.isName()
        imageviewNameCheck.isHidden = !value
        editRequiredFiledCheck(.name, isAdd: value)
    }
    
    @IBAction func pressNext(_ sender: Any) {
        if isEnteredRequiredField(.all) || isEnteredRequiredField(.noIdCard) {
            performSegue(withIdentifier: "SignUpSeg", sender: self)
            labelAlert.text = ""
        } else {
            if !isEnteredRequiredField(.name) {
                labelAlert.autoFadeOut("올바른 이름을 입력하세요.")
            } else if !isEnteredRequiredField(.password) {
                labelAlert.autoFadeOut("올바른 비밀번호를 입력하세요.")
            }
        }
    }
    
    @IBAction func pressExit(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "SignUpSeg" {
            let vc = segue.destination as! SignUp2ViewController
            vc.signUpData = SignUp2ViewController.SignUpData(name: textfieldName.text!,
                                       pin: textfieldPassword.text!,
                                       id: textfieldId.text!,
                                       image: buttonIdCapture.currentBackgroundImage)
        }
    }
}
