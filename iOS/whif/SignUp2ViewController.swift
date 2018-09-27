
import UIKit


class SignUp2ViewController: UIViewController {
    
    struct SignUpData {
        var name:  String
        var pin:   String
        var id:    String
        var image: UIImage?
    }

    @IBOutlet weak var viewPhoneCheck: UIView!
    @IBOutlet weak var textfieldPhone: UITextField!
    @IBOutlet weak var textfieldAuthNumber: UITextField!
    @IBOutlet weak var labelAlert: UILabel!
    
    @IBOutlet weak var constraintImageviewTop: NSLayoutConstraint!
    
    var network: Network?
    var signUpData: SignUpData?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        hideKeyboardWhenTappedAround()
        NotificationCenter.default.addObserver(self, selector: #selector(KeyboardWillShow(_:)), name: Notification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(KeyboardWillHide(_:)), name: Notification.Name.UIKeyboardWillHide, object: nil)
        // Do any additional setup after loading the view.
        network = Network()
        network?.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        get { return .portrait }
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
            
            self.constraintImageviewTop.constant = move
            UIView.animate(withDuration: duration,
                           delay: 0.0,
                           options: animationOptions,
                           animations: { () -> Void in
                            self.view.layoutIfNeeded()
            }, completion: nil)
        }
    }
    
    
    @IBAction func editingPhone(_ sender: Any) {
        let value = textfieldPhone.text!.isPhone()
        viewPhoneCheck.isHidden = !value
        if value {
            dismissKeyboard()
        }
    }
    
    @IBAction func editingAuthNumber(_ sender: Any) {
    }
    
    @IBAction func pressSignUp(_ sender: Any) {
        if !textfieldPhone.text!.isPhone() {
            labelAlert.autoFadeOut("올바른 핸드폰 번호를 입력하세요.")
            return
        }
        if let signUpData = signUpData {
            let phonenumber = textfieldPhone.text!.replace(of: "+82", with: "0").replace(of: " ", with: "")
            network?.register(phone: phonenumber, name: signUpData.name, id: signUpData.id, image: signUpData.image, password: signUpData.pin)
        }
    }
    
    @IBAction func pressExit(_ sender: Any) {
        presentingViewController?
        .presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func pressPrev(_ sender: Any) {
        dismiss(animated: false, completion: nil)
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

extension SignUp2ViewController: NetworkDelegate {
    
    func networkBegined() {
        DispatchQueue.main.async {
            self.startLoading()
        }
    }
    
    func networkEnded() {
        DispatchQueue.main.async {
            self.endLoading()
        }
    }
    
    func networkError(result: Network.Result) {
        labelAlert.autoFadeOut(result.error.rawValue)
        networkEnded()
    }
    
    func networkResponse(data: Data, mode: Network.responseMode) {
        do {
            let registerData = try JSONDecoder().decode(Network.registerResponseData.self, from: data)
            if !registerData.error {
                let vc = self.presentingViewController?.presentingViewController as! MyLoginViewController
                DispatchQueue.main.async {
                    vc.dismiss(animated: true, completion: nil)
                }
                if registerData.piece != "" {
                    if FileIO("my", directory: "id").write(registerData.piece) {
                        vc.labelAlert.autoFadeOut("신분증 등록을 완료했습니다.")
                    }
                } else {
                    vc.labelAlert.autoFadeOut("계정 등록을 완료했습니다.")
                }
            }
        } catch {
            labelAlert.autoFadeOut(Network.Result.Error.invalidJson.rawValue)
        }
    }
}
