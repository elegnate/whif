
class BarcodeViewController: UIViewController {
    
    @IBOutlet weak var imageviewBarcode: UIImageView!
    @IBOutlet weak var labelBarcode: UILabel!
    
    var txtBarcode: String?
    var imageBarcode: UIImage?
    
    var brightness: CGFloat = 1.0
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let txt = self.txtBarcode {
            self.labelBarcode.text = txt
        }
        if let image = self.imageBarcode {
            self.imageviewBarcode.image = image
        }
        self.labelBarcode.transform = CGAffineTransform(rotationAngle: .pi / 2)
        self.imageviewBarcode.transform = CGAffineTransform(rotationAngle: .pi / 2)
        self.brightness = UIScreen.main.brightness
        UIScreen.main.brightness = 1.0
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        UIScreen.main.brightness = brightness
    }
    
    
    @IBAction func pressExit(_ sender: Any) {
        self.dismiss(animated: false, completion: nil)
    }
    
}
