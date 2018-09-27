
import CryptoSwift


class OTP {
    
    var period: Int?
    
    fileprivate var algo: Int = Int(kCCHmacAlgSHA256)
    fileprivate var size: Int = Int(CC_SHA256_DIGEST_LENGTH)
    fileprivate var secret: Data?
    
    init(phone: String, verifier: String, period: Int = 60) {
        let uuid    = (UIDevice.current.identifierForVendor?.uuidString.replace(of: "-", with: ""))!
        let msg     = uuid + phone + verifier
        self.secret = Data(bytes: msg.bytes.sha256())
        self.period = period
    }
    
    
    func Generate(_ counter: Int64 = Date().timestamp) -> Int {
        var cnt = counter.bigEndian
        var buf = [UInt8](repeating: 0, count: size)
        CCHmac(UInt32(algo),
               secret?.bytes, secret!.count, &cnt, MemoryLayout.size(ofValue: cnt), &buf)
        let off = Int(buf[19]) & 0x0f;
        let msk = UnsafePointer<UInt8>(buf).advanced(by: off).withMemoryRebound(to: UInt32.self,
                                                                                capacity: self.size / 4) {
            $0[0].bigEndian & 0x7fffffff
        }
        return Int(msk % 1000000)
    }
    
    
    func Verify(otpCode: String) -> Bool {
        let code  = Int(otpCode)!
        let ts    = Date().timestamp
        
        for i in stride(from: 0, to: self.period!, by: 1) {
            let verifyCode = Generate(ts - Int64(i))
            if verifyCode == code {
                return true
            }
        }
        return false
    }
}
