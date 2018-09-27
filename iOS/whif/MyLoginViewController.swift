
import SwiftyGif


class MyLoginViewController: UIViewController {
    
    @IBOutlet weak var labelAlert: UILabel!
    @IBOutlet weak var stackviewPasscode: UIStackView!
    @IBOutlet weak var stackviewNumber: UIStackView!
    
    var pin: String = ""
    
    var network: Network?
    var challengeData: Network.challengeResponseData?
    var loginData: Network.loginResponseData?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setNumberKeypad()
        network = Network()
        network?.delegate = self
        network?.authentificationBiometric(mode: .login)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        stackviewPasscode.subviews.forEach({ $0.backgroundColor = UIColor.clear })
        pin = ""
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        get {
            return .portrait
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    
    func setNumberKeypad() {
        var arr = [ "1", "2", "3", "4", "5", "6", "7", "8", "9", "0" ]
        
        for i in (0 ..< arr.count).reversed() {
            let ix1 = i
            let ix2 = Int(arc4random_uniform(UInt32(i + 1)))
            (arr[ix1], arr[ix2]) = (arr[ix2], arr[ix1])
        }
        
        for stack in stackviewNumber.subviews {
            for btn in stack.subviews as! [UIButton] {
                if let id = btn.restorationIdentifier {
                    if id == "back" {
                        btn.addTarget(self, action: #selector(pressErase(_:)), for: .touchUpInside)
                    }
                } else {
                    let num = arr.popLast()
                    btn.setTitle(num, for: .normal)
                    btn.addTarget(self, action: #selector(pressNumber(_:)), for: .touchUpInside)
                }
            }
        }
    }
    
    @objc func pressNumber(_ sender: UIButton) {
        let count = pin.count
        if count < 6 {
            guard let num = sender.currentTitle else { return }
            pin += num
            stackviewPasscode.subviews[count].backgroundColor = UIColor.white
            if count == 5 {
                network?.challenge(mode: .login)
            }
        }
    }
    
    @objc func pressErase(_ sender: UIButton) {
        let count = pin.count
        if count > 0 {
            pin.removeLast()
            stackviewPasscode.subviews[count - 1].backgroundColor = UIColor.clear
        }
    }
    
    @IBAction func pressAuthFingerprint(_ sender: Any) {
        let _ = network?.authentificationBiometric(mode: .login)
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "LoginSeg" {
            let vc = segue.destination as! ViewController
            vc.loginData = loginData
        }
    }
}

extension MyLoginViewController: NetworkDelegate {
    
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
            if mode == .challenge {
                challengeData = try JSONDecoder().decode(Network.challengeResponseData.self, from: data)
                if challengeData?.challenge == "" {
                    labelAlert.autoFadeOut("등록된 계정/신분증이 없습니다.")
                    return
                }
                if (challengeData?.isBiometric)! {
                    loginProcess()
                } else {
                    loginProcess(pin: self.pin)
                }
            } else if mode == .login {
                loginData = try JSONDecoder().decode(Network.loginResponseData.self, from: data)
                if !(loginData?.error)! {
                    DispatchQueue.main.async {
                        self.performSegue(withIdentifier: "LoginSeg", sender: self)
                    }
                } else {
                    labelAlert.autoFadeOut("로그인에 실패했습니다. \(loginData?.message ?? "")")
                }
            }
        } catch {
            labelAlert.autoFadeOut(Network.Result.Error.invalidJson.rawValue)
        }
    }
    
    func loginProcess(pin: String? = nil) {
        if let challengeData = challengeData, let network = network {
            let content = Data(base64Encoded: challengeData.challenge)!
            guard let challenge = network.decryptForPrivate(content: content, password: pin) else {
                return
            }
            network.login(challenge: challenge)
        }
    }
}
