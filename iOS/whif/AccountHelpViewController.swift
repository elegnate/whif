
import UIKit

class AccountHelpViewController: UIViewController {

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
        let vc = self.presentingViewController as? MyLoginViewController
        vc?.labelAlert.text = result.error.rawValue
        networkEnded()
    }
    
    func networkResponse(data: Data, mode: Network.responseMode) {
        let vc = self.presentingViewController as? MyLoginViewController
        do {
            let withdrawalData = try JSONDecoder().decode(Network.withdrawalResponseData.self, from: data)
            if !withdrawalData.error {
                FileIO("my", directory: "id").remove()
                DispatchQueue.main.async {
                    vc?.performSegue(withIdentifier: "SignUpSeg", sender: vc)
                }
                return
            }
        } catch {
            vc?.labelAlert.autoFadeOut(Network.Result.Error.invalidJson.rawValue)
        }
    }
}
