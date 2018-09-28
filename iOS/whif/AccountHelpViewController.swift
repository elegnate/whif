
import UIKit

class AccountHelpViewController: UIViewController {

    @IBOutlet weak var progressLoading: UIProgressView!
    
    var network: Network?
    
    override func viewDidLoad() {
        super.viewDidLoad()
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

    @IBAction func pressExit(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func pressWithdrawal(_ sender: Any) {
        network?.withdrawal()
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

extension AccountHelpViewController: NetworkDelegate {
    
    func networkBegined() {
        progressLoading.startLoading()
    }
    
    func networkEnded() {
        progressLoading.setLoading(0.8)
    }
    
    func networkError(result: Network.Result) {
        let vc = self.presentingViewController as? LoginViewController
        vc?.labelAlert.text = result.error.rawValue
        networkEnded()
        progressLoading.endLoading()
    }
    
    func networkResponse(data: Data, mode: Network.responseMode) {
        do {
            let withdrawalData = try JSONDecoder().decode(Network.withdrawalResponseData.self, from: data)
            if !withdrawalData.error {
                FileIO("my", directory: "id").remove()
                DispatchQueue.main.async {
                    self.dismiss(animated: false, completion: nil)
                }
            } else {
                networkError(result: .failure(.withdrawal))
            }
        } catch {
            networkError(result: .failure(.invalidJson))
        }
    }
}
