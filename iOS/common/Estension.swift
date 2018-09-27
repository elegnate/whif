
import CryptoSwift


extension String {
    /**
     정규표현식을 수행합니다.
     
     filter:Param -> 정규표현식
     return Value -> 탐지 개수 (1 이상일 경우 참)
     */
    func regExp(filter:String) -> Bool {
        let regex = try! NSRegularExpression(pattern: filter, options: [])
        let list = regex.matches(in:self, options: [], range:NSRange.init(location: 0, length:self.count))
        return (list.count >= 1)
    }
    
    func replace(of: String, with: String) -> String {
        return self.replacingOccurrences(of: of, with: with, options: NSString.CompareOptions.literal, range: nil)
    }
    
    /**
     올바른 식별번호인지 검사합니다.
     
     return Value -> 올바를 경우 true
     */
    func isIdNumber() -> Bool {
        if !regExp(filter: "^(?:[0-9]{2}(?:0[1-9]|1[0-2])(?:0[1-9]|[1,2][0-9]|3[0,1]))-?([1-4][0-9]{6})$") {
            return false
        }
        
        let arrCode:Array<Int> = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2] // 식별번호 중 마지막 숫자를 검출하기 위한 코드
        // 식별번호를 숫자로 변환
        var nId:Int = (Int)(replace(of: "-", with: ""))!
        
        let nLastCode = nId % 10
        var nSum = 0;
        
        for code in arrCode {
            nId /= 10
            nSum += code * (nId % 10)
        }
        
        return ((11 - (nSum % 11)) % 10 == nLastCode)
    }
    
    func isName() -> Bool {
        let ret = regExp(filter: "(^[가-힣]{2,})|(^[a-zA-Z][a-zA-Z0-9]{3,})$")
        return ret
    }
    
    func isPassword() -> Bool {
        let ret = regExp(filter: "(?!^[0-9]*$)(?!^[a-zA-Z`~|!@#$%^&*\\[\\]{}():;_+=<>?]*$)^([a-zA-Z`~|!@#$%^&*\\[\\]{}():;_+=<>?0-9]{8,16})$")
        return ret
    }
    
    func isPIN() -> Bool {
        let ret = regExp(filter: "^[0-9]{6}$")
        return ret
    }
    
    func isPhone() -> Bool {
        let ret = regExp(filter: "^(0|(\\+82[- ]?))10[- ]?([0-9]{4})[- ]?([0-9]{4})[- ]?$")
        return ret
    }
    
    func isIdentityVerifyOTP() -> Bool {
        return self.count == 10 && self.isNumber()
    }
    
    func isNumber() -> Bool {
        return Int(self) != nil
    }
    
    func GetLines () -> Array<String> {
        let stringRet = self.replacingOccurrences(of: " ", with: "", options: NSString.CompareOptions.literal, range: nil)
            .replacingOccurrences(of: "\n\n", with: "\n", options: NSString.CompareOptions.literal, range: nil)
            .replacingOccurrences(of: "(", with: "", options: NSString.CompareOptions.literal, range: nil)
            .replacingOccurrences(of: ")", with: "", options: NSString.CompareOptions.literal, range: nil)
        let arr = stringRet.split{$0 == "\n"}.map(String.init)
        
        return arr
    }
    
    func GetId () -> String? {
        var convertId = self
        
        if self.count == 14 {
            convertId = replace(of: String(self[self.index(self.startIndex, offsetBy: 6)]), with: "-")
        } else if self.count == 13 {
            convertId.insert("-", at: self.index(self.startIndex, offsetBy: 6))
        }
        // 올바른 식별번호인지 검사
        if convertId.isIdNumber() {
            return convertId
        }
        
        return nil
    }
    
    func CodeToDigits(digitsCount: Int = 8) -> String {
        if self != "" {
            var ret = self
            let len = digitsCount - ret.count
            for _ in 0 ..< len {
                ret = "0" + ret
            }
            return ret
        }
        return ""
    }
    
    func generateBarcode(size: CGFloat = 5.0, barcodeColor: CIColor = CIColor(red:0.32, green:0.39, blue:0.58)) -> UIImage? {
        let data = self.data(using: String.Encoding.ascii)
        
        if let filter = CIFilter(name: "CICode128BarcodeGenerator") {
            guard let colorFilter = CIFilter(name: "CIFalseColor") else { return nil }
            filter.setValue(data, forKey: "inputMessage")
            
            colorFilter.setValue(filter.outputImage, forKey: "inputImage")
            colorFilter.setValue(CIColor.white, forKey: "inputColor1")
            colorFilter.setValue(barcodeColor, forKey: "inputColor0")
            
            let transform = CGAffineTransform(scaleX: size, y: size)
            
            if let output = colorFilter.outputImage?.transformed(by: transform) {
                return UIImage(ciImage: output)
            }
        }
        
        return nil
    }
    
    func encryptAES(key: Array<UInt8>) -> String {
        do {
            let iv = Array<UInt8>(Data(bytes: key).sha256().bytes[0...15])
            return (try self.encryptToBase64(cipher: AES(key: key, blockMode: CBC(iv: iv), padding: .pkcs7)))!
        } catch {
            return ""
        }
    }
    
    func decryptAES(key: Array<UInt8>) -> String {
        do {
            let iv = Array<UInt8>(Data(bytes: key).sha256().bytes[0...15])
            return try self.decryptBase64ToString(cipher: AES(key: key, blockMode: CBC(iv: iv), padding: .pkcs7))
        } catch {
            return ""
        }
    }
    
    func decryptAESToBytes(key: Array<UInt8>) -> Array<UInt8> {
        do {
            let iv = Array<UInt8>(Data(bytes: key).sha256().bytes[0...15])
            return try self.decryptBase64(cipher: AES(key: key, blockMode: CBC(iv: iv), padding: .pkcs7))
        } catch {
            return []
        }
    }
}


@IBDesignable
class DesignableView: UIView {}
class GradientView: DesignableView {
    var startColor = UIColor(red:0.38, green:0.26, blue:0.52, alpha:1.0)
    var endColor   = UIColor(red:0.32, green:0.39, blue:0.58, alpha:1.0)
    var horizontalMode =  false
    var diagonalMode   =  true
    
    var gradientLayer: CAGradientLayer { return layer as! CAGradientLayer }
    override class var layerClass: AnyClass { return CAGradientLayer.self }
    
    
    func updatePoints() {
        if horizontalMode {
            gradientLayer.startPoint = diagonalMode ? CGPoint(x: 1, y: 0) : CGPoint(x: 0, y: 0.5)
            gradientLayer.endPoint   = diagonalMode ? CGPoint(x: 0, y: 1) : CGPoint(x: 1, y: 0.5)
        } else {
            gradientLayer.startPoint = diagonalMode ? CGPoint(x: 0, y: 0) : CGPoint(x: 0.5, y: 0)
            gradientLayer.endPoint   = diagonalMode ? CGPoint(x: 1, y: 1) : CGPoint(x: 0.5, y: 1)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updatePoints()
        gradientLayer.locations = [0, 1]
        gradientLayer.colors = [startColor.cgColor, endColor.cgColor]
    }
}

@IBDesignable
class DesignableButton: UIButton {}

@IBDesignable
class DesignableImageView: UIImageView {}

@IBDesignable
class DesignableScrollView: UIScrollView {}

@IBDesignable
class DesignableLabel: UILabel {}

@IBDesignable
class DesignableTextField: UITextField {}

@IBDesignable
class DesignableSegmentedControl: UISegmentedControl {}

@IBDesignable
class DesignableTextView: UITextView {}

extension UIView {
    
    @IBInspectable
    var cornerRadius: CGFloat {
        get { return layer.cornerRadius }
        set { layer.cornerRadius = newValue }
    }
    
    @IBInspectable
    var borderWidth: CGFloat {
        get { return layer.borderWidth }
        set { layer.borderWidth = newValue }
    }
    
    @IBInspectable
    var borderColor: UIColor? {
        get {
            if let color = layer.borderColor {
                return UIColor(cgColor: color)
            }
            return nil
        }
        set {
            if let color = newValue {
                layer.borderColor = color.cgColor
            } else {
                layer.borderColor = nil
            }
        }
    }
    
    @IBInspectable
    var shadowRadius: CGFloat {
        get { return layer.shadowRadius }
        set { layer.shadowRadius = newValue }
    }
    
    @IBInspectable
    var shadowOpacity: Float {
        get { return layer.shadowOpacity }
        set { layer.shadowOpacity = newValue }
    }
    
    @IBInspectable
    var shadowOffset: CGSize {
        get { return layer.shadowOffset }
        set { layer.shadowOffset = newValue }
    }
    
    @IBInspectable
    var shadowColor: UIColor? {
        get {
            if let color = layer.shadowColor {
                return UIColor(cgColor: color)
            }
            return nil
        }
        set {
            if let color = newValue {
                layer.shadowColor = color.cgColor
            } else {
                layer.shadowColor = nil
            }
        }
    }
    
    func faidIn(time: TimeInterval, delay: TimeInterval, alpha: CGFloat) {
        UIView.animate(withDuration: time, delay: delay, options: UIViewAnimationOptions.curveEaseIn, animations: {
            self.alpha = alpha
        }, completion: nil)
    }
    
    func getAbsoluteRect(_ RelationTargetOriginY: CGFloat, scale: CGSize) -> CGRect {
        return self.getAbsoluteRect(CGPoint(x: 0.0, y: RelationTargetOriginY), scale: scale)
    }
    
    func getAbsoluteRect(_ RelationTargetOrigin: CGPoint, scale: CGSize) -> CGRect {
        let originViewIdRagne = self.frame.origin
        let sizeViewIdRange   = self.frame.size
        return CGRect(x: originViewIdRagne.x * scale.width + RelationTargetOrigin.x * scale.width,
                      y: originViewIdRagne.y * scale.height + RelationTargetOrigin.y * scale.height,
                      width: sizeViewIdRange.width * scale.width,
                      height: sizeViewIdRange.height * scale.height)
    }
}


extension UILabel {
    func autoFadeOut(_ title: String, deadline: DispatchTime = .now() + 3.0) {
        DispatchQueue.main.async {
            self.text = title
            self.alpha = 1.0
        }
        DispatchQueue.main.asyncAfter(deadline: deadline) {
            UIView.animate(withDuration: 0.5) {
                self.alpha = 0.0
            }
        }
    }
}


extension UIViewController {
    func hideKeyboardWhenTappedAround(cancelsTouchesInView: Bool = true) {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = cancelsTouchesInView
        self.view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        self.view.endEditing(true)
    }
    
    func presentDetail(_ viewControllerToPresent: UIViewController) {
        let transition = CATransition()
        transition.duration = 0.25
        transition.type = kCATransitionPush
        transition.subtype = kCATransitionFromRight
        self.view.window!.layer.add(transition, forKey: kCATransition)
        self.present(viewControllerToPresent, animated: false)
    }
    
    func startLoading() {
        let viewLoading = UIView(frame: view.frame)
        let imageview = UIImageView(frame: CGRect(x: view.frame.width / 2 - 35,
                                                  y: view.frame.height / 2 - 70,
                                                  width: 70, height: 70))
        let loadingImage = UIImage(gifName: "loading", levelOfIntegrity: 0.5)
        
        view.addSubview(viewLoading)
        viewLoading.addSubview(imageview)
        viewLoading.restorationIdentifier = "Loading"
        viewLoading.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        
        imageview.loopCount = -1
        imageview.setGifImage(loadingImage)
        imageview.startAnimating()
        imageview.contentMode = .scaleAspectFit
    }
    
    func endLoading() {
        for sub in view.subviews {
            if sub.restorationIdentifier == "Loading" {
                sub.removeFromSuperview()
                break
            }
        }
    }
}


extension NSLayoutConstraint {
    func SwayAnimation(move: CGFloat = -2, count: Int = 6) {
        if count > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                self.constant = move
                self.SwayAnimation(move: -move, count: count - 1)
            }
        } else {
            self.constant = 0.0
        }
    }
}


extension UIImage {
    func cutImage(rect: CGRect) -> UIImage {
        let cropImage = self.cgImage?.cropping(to: rect)
        let image = UIImage(cgImage: cropImage!)
        return image
    }
    
    func pixellated(scale: Int = 15) -> UIImage? {
        let image = CIImage(cgImage: self.cgImage!)
        let filter = CIFilter(name: "CIPixellate")!
        filter.setDefaults()
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(scale, forKey: kCIInputScaleKey)
        
        let context = CIContext(options: nil)
        let imageRef = context.createCGImage(filter.outputImage!, from: image.extent)
        return UIImage(cgImage: imageRef!)
    }
    
    func toString(bufSize: Int = 102400) -> String {
        var quality: CGFloat = 0.6
        var ret:     String  = ""
        repeat {
            guard let data = UIImageJPEGRepresentation(self, quality)?.base64EncodedString() else { break }
            ret = data
            quality -= 0.01
        } while ret.count > bufSize
        return ret
    }
}


extension Date {
    var timestamp: Int64 {
        return Int64(self.timeIntervalSince1970)
    }
    
    var today: Int {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        return Int(formatter.string(from: self))!
    }
}
