
import CryptoSwift
import LocalAuthentication


protocol NetworkDelegate {
    
    func networkResponse(data: Data, mode: Network.responseMode)
    func networkBegined()
    func networkEnded()
    func networkError(result: Network.Result)
}


extension Network {
    
    enum restMethod: String {
        case post   = "POST"
        case get    = "GET"
        case delete = "DELETE"
        case put    = "PUT"
    }
    
    enum responseMode: String {
        case login      = "login"
        case identity   = "identity"
        case challenge  = "challenge"
        case withdrawal = "withdrawal"
        case register   = "register"
    }
    
    enum Result {
        enum Error: String {
            case no              = ""
            case unknown         = "알 수 없는 오류입니다."
            case invalidURL      = "서버의 주소가 올바르지 않습니다."
            case invalidJson     = "송/수신 데이터가 올바르지 않습니다."
            case invalidParam    = "송신 데이터가 올바르지 않습니다."
            case decryptRSA      = "인증에 실패했습니다."
            case loadRSA         = "키를 불러오는 중 오류가 발생했습니다."
            case noPiece         = "기기에 저장된 신분증이 없습니다."
            case noBiometric     = "PIN으로 시도해주세요."
            case alreadyRegister = "이미 등록된 신분증이 있습니다."
            case generateRSAKey  = "키 생성에 실패했습니다."
            case verifySignature = "서명 검증에 실패했습니다."
        }
        case failure(Error)
        
        public var error: Error {
            switch self {
            case .failure(let error): return error
            }
        }
    }
}


class Network: NSObject {
    
    var delegate:       NetworkDelegate?
    var uuid:           String
    var address:        String

    
    init(address: String = "https://www.jwan.info") {
        self.uuid    = UIDevice.current.identifierForVendor?.uuidString.replace(of: "-", with: "") ?? ""
        self.address = address
    }
    
    func requestWithRestFormat(pattern: String, method: restMethod, jsonData: Data? = nil) -> URLRequest? {
        if let url = URL(string: address + pattern) {
            var request = URLRequest(url: url)
            request.httpMethod = method.rawValue
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            if let data = jsonData {
                request.httpBody = data
            }
            return request
        }
        return nil
    }
    
    func requestSession(rest: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        let configuration = URLSessionConfiguration.default
        let session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        let task = session.dataTask(with: rest, completionHandler: completionHandler)
        task.resume()
    }
    
    func authentificationBiometric(mode: responseMode) -> Bool {
        let context = LAContext()
        var error: NSError?
        
        if !context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            delegate?.networkError(result: .failure(.noBiometric))
            return false
        }
        if !FileIO("my", directory: "id").isExist() {
            delegate?.networkError(result: .failure(.noPiece))
            return false
        }
        if mode != .login && mode != .identity {
            return false
        }
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "생체정보를 입력해주세요.") {
            [] success, authenticationError in
            if success {
                DispatchQueue.main.async {
                    self.challenge(mode: mode, isBiometric: true)
                }
            }
        }
        return true
    }
    
    func challenge(mode: responseMode, isBiometric: Bool = false) {
        delegate?.networkBegined()
        let jsonData = challengeRequestData(mode: mode.rawValue, did: uuid, isBiometric: isBiometric)
        guard let requestData = try? JSONEncoder().encode(jsonData) else {
            delegate?.networkError(result: .failure(.invalidJson))
            return
        }
        guard let rest = requestWithRestFormat(pattern: "/challenge", method: .post, jsonData: requestData) else {
            delegate?.networkError(result: .failure(.invalidURL))
            return
        }
        requestSession(rest: rest) { (data, response, error) in
            if let data = data {
                self.delegate?.networkResponse(data: data, mode: .challenge)
            } else if error != nil {
                self.delegate?.networkError(result: .failure(.invalidURL))
            }
            self.delegate?.networkEnded()
        }
    }
    
    func login(challenge: Data) {
        delegate?.networkBegined()
        let jsonData = loginRequestData(did: uuid, challenge: String(data: challenge, encoding: .utf8)!)
        guard let requestData = try? JSONEncoder().encode(jsonData) else {
            delegate?.networkError(result: .failure(.invalidJson))
            return
        }
        guard let rest = requestWithRestFormat(pattern: "/login", method: .post, jsonData: requestData) else {
            delegate?.networkError(result: .failure(.invalidURL))
            return
        }
        requestSession(rest: rest) { (data, response, error) in
            if let data = data {
                self.delegate?.networkResponse(data: data, mode: .login)
            } else if error != nil {
                self.delegate?.networkError(result: .failure(.invalidURL))
            }
            self.delegate?.networkEnded()
        }
    }
    
    func identity(challenge: Data, requirer: String) {
        delegate?.networkBegined()
        guard let piece = FileIO("my", directory: "id").read() else {
            delegate?.networkError(result: .failure(.noPiece))
            return
        }
        let jsonData = identityRequestData(did: uuid, requirer: requirer, piece: piece, challenge: challenge.base64EncodedString())
        guard let requestData = try? JSONEncoder().encode(jsonData) else {
            delegate?.networkError(result: .failure(.invalidJson))
            return
        }
        guard let rest = requestWithRestFormat(pattern: "/identity", method: .post, jsonData: requestData) else {
            delegate?.networkError(result: .failure(.invalidURL))
            return
        }
        requestSession(rest: rest) { (data, response, error) in
            if let data = data {
                self.delegate?.networkResponse(data: data, mode: .identity)
            } else if error != nil {
                self.delegate?.networkError(result: .failure(.invalidURL))
            }
            self.delegate?.networkEnded()
        }
    }
    
    func register(phone: String, name: String, id: String, image: UIImage?, password: String) {
        delegate?.networkBegined()
        if FileIO("my", directory: "id").isExist() {
            delegate?.networkError(result: .failure(.alreadyRegister))
            return
        }
        guard let publicKey = generateRSAKeyPair(password: password) else {
            delegate?.networkError(result: .failure(.generateRSAKey))
            return
        }
        var jsonData = registerRequestData(did: uuid, phone: phone, hid: "", name: name, birth: "", image: "", pubkey: publicKey.bytes.toBase64()!)
        if let b64Image = image?.toString() {
            let i          = id.index(id.startIndex, offsetBy: 8)
            let gender     = Int(String(id[id.index(before: i)]))! - 1
            jsonData.birth = String(19 + Int(gender / 2)) + id[id.startIndex..<i]
            jsonData.hid   = Data(bytes: (name + id).bytes.sha256()).base64EncodedString()
            jsonData.image = b64Image
            print(jsonData.birth)
            print(jsonData.hid)
        }
        guard let requestData = try? JSONEncoder().encode(jsonData) else {
            delegate?.networkError(result: .failure(.invalidJson))
            return
        }
        guard let rest = requestWithRestFormat(pattern: "/users", method: .post, jsonData: requestData) else {
            delegate?.networkError(result: .failure(.invalidURL))
            return
        }
        requestSession(rest: rest) { (data, response, error) in
            if let data = data {
                self.delegate?.networkResponse(data: data, mode: .register)
            } else if error != nil {
                self.delegate?.networkError(result: .failure(.invalidURL))
            }
            self.delegate?.networkEnded()
        }
    }
    
    func withdrawal() {
        delegate?.networkBegined()
        guard let rest = requestWithRestFormat(pattern: "/users/\(uuid)", method: .delete) else {
            delegate?.networkError(result: .failure(.invalidURL))
            return
        }
        requestSession(rest: rest) { (data, response, error) in
            if let data = data {
                self.delegate?.networkResponse(data: data, mode: .withdrawal)
            } else if error != nil {
                self.delegate?.networkError(result: .failure(.invalidURL))
            }
            self.delegate?.networkEnded()
        }
    }
}

extension Network: URLSessionDelegate {
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        // We've got a URLAuthenticationChallenge - we simply trust the HTTPS server and we proceed
        completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
    }
}

extension Network {
    
    func generateRSAKeyPair(password: String) -> String? {
        var ret: String? = nil
        do {
            let keyPair = try SwiftyRSA.generateRSAKeyPair(sizeInBits: 2048)
            let privateKey = try keyPair.privateKey.pemString()
            let publicKey = try keyPair.publicKey.pemString()
            let privateKeyWithPin = privateKey.encryptAES(key: password.bytes.sha256())
            let privateKetWithUuid = privateKey.encryptAES(key: uuid.bytes.sha256())
            if FileIO("pin_priv.pem").write(privateKeyWithPin) &&
                FileIO("fp_priv.pem").write(privateKetWithUuid) &&
                FileIO("pub.pem").write(publicKey) {
                ret = publicKey
            }
        } catch {
        }
        return ret
    }
    
    func decryptForPrivate(content: Data, password: String? = nil) -> Data? {
        do {
            let privFileName = password == nil ? "fp_priv.pem" : "pin_priv.pem"
            guard var privpem = FileIO(privFileName).read() else {
                delegate?.networkError(result: .failure(.loadRSA))
                return nil
            }
            if let password = password {
                privpem = privpem.decryptAES(key: password.bytes.sha256())
            } else {
                privpem = privpem.decryptAES(key: uuid.bytes.sha256())
            }
            let privKey = try PrivateKey(pemEncoded: privpem)
            let message = EncryptedMessage(data: content)
            let plain = try message.decrypted(with: privKey, padding: .PKCS1)
            return plain.data
        } catch {
            delegate?.networkError(result: .failure(.decryptRSA))
        }
        return nil
    }
    
    func verifySignature(signData: identityResponseData) -> Bool {
        let imageHash = signData.image.bytes.sha256().toBase64()!
        let plain     = imageHash + signData.requirerName + signData.validDate + signData.verifyNumber
        let clear     = ClearMessage(data: Data(bytes: plain.bytes))
        do {
            let publicKey = try PublicKey(pemNamed: "public")
            let sign      = try Signature(base64Encoded: signData.sign)
            if try clear.verify(with: publicKey, signature: sign) {
                return true
            }
        } catch {
        }
        delegate?.networkError(result: .failure(.verifySignature))
        return false
    }
}

extension Network {
    
    struct challengeRequestData: Codable {
        var mode: String
        var did: String
        var isBiometric: Bool
    }
    
    struct challengeResponseData: Codable {
        var error: Bool
        var message: String
        var isBiometric: Bool
        var challenge: String
    }
    
    struct loginRequestData: Codable {
        var did: String
        var challenge: String
    }
    
    struct loginResponseData: Codable {
        var error: Bool
        var message: String
        var phone: String
        var name: String
        var birth: String
        var regDate: String
    }
    
    struct identityRequestData: Codable {
        var did: String
        var requirer: String
        var piece: String
        var challenge: String
    }
    
    struct identityResponseData: Codable {
        var error: Bool
        var message: String
        var image: String
        var requirerName: String
        var validDate: String
        var verifyNumber: String
        var sign: String
    }
    
    struct registerRequestData: Codable {
        var did: String
        var phone: String
        var hid: String
        var name: String
        var birth: String
        var image: String
        var pubkey: String
    }
    
    struct registerResponseData: Codable {
        var error: Bool
        var message: String
        var piece: String
    }
    
    struct withdrawalResponseData: Codable {
        var error: Bool
        var message: String
    }
}
