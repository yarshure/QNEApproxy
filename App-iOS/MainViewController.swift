/*
    <samplecode>
        <abstract>
            Main view controller.
        </abstract>
    </samplecode>
 */

import UIKit

// +++ rename to ViewController

class MainViewController : UITableViewController {

    var manager: AppProxyManager! {
        didSet {
            assert(self.manager != nil)
            NotificationCenter.default.addObserver(self, selector: #selector(managerStateDidChange(note:)), name: AppProxyManager.stateDidChange, object: self.manager)
            NotificationCenter.default.addObserver(self, selector: #selector(managerStatusDidChange(note:)), name: AppProxyManager.statusDidChange, object: self.manager)
        }
    }
    
    deinit {
        fatalError()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        assert(self.manager != nil)
        self.updateStateUIFromManager()
        self.updateStatusUIFromManager()
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch (indexPath.section, indexPath.row) {
            case (0, 0), (0, 1), (0, 2):
                break       // not interactive
            case (1, 0):
                break       // not interactive
            case (1, 1):
                self.connectDisconnectAction()
            case (2, 0):
                self.sendAppMessageAction()
            default:
                fatalError()
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }

    // MARK: - state
    
    @IBOutlet var stateLabel: UILabel!

    @IBOutlet var enableLabel: UILabel!
    @IBOutlet var vendorConfigurationLabels: [UILabel]!
    
    @objc func managerStateDidChange(note: Notification) {
        self.updateStateUIFromManager()
    }
    
    func updateStateUIFromManager() {
        let stateText: String
        let snapshot: AppProxyManager.Snapshot?
        switch self.manager.state {
            case .loading:                                  stateText = "Loading…"
            case .reloading:                                stateText = "Reloading…"
            case .loaded:                                   stateText = "Loaded"
            case .failed(let error):                        stateText = "\(error)"
        }
        switch self.manager.state {
            case .loading, .reloading, .failed:             snapshot = nil
            case .loaded(let s, _):                         snapshot = s
        }
        self.stateLabel.text = stateText
        if let snapshot = snapshot {
            self.vendorConfigurationLabels[0].text = snapshot.customConfiguration.dummy ? "enabled" : "disabled"
            self.enableLabel.text = snapshot.isEnabled ? "enabled" : "disabled"
        } else {
            self.vendorConfigurationLabels.forEach { $0.text = "n/a" }
            self.enableLabel.text = "n/a"
        }
    }

    // MARK: - status

    @IBOutlet var statusLabel: UILabel!
    @IBOutlet var connectDisconnectCell: UITableViewCell!
    
    @objc func managerStatusDidChange(note: Notification) {
        self.updateStatusUIFromManager()
    }

    func updateStatusUIFromManager() {
        let statusText: String
        switch self.manager.status {
            case .invalid:          statusText = "Invalid"
            case .disconnected:     statusText = "Disconnected"
            case .connecting:       statusText = "Connecting"
            case .connected:        statusText = "Connected"
            case .reasserting:      statusText = "Reasserting"
            case .disconnecting:    statusText = "Disconnecting"
        }
        self.statusLabel.text = statusText
        
        let buttonEnabled: Bool
        let buttonTitle: String
        switch self.manager.status {
            case .invalid:          buttonEnabled = false; buttonTitle = "Connect…"
            case .disconnected:     buttonEnabled = true;  buttonTitle = "Connect…"
            case .connecting, 
                 .connected, 
                 .reasserting, 
                 .disconnecting:
                                    buttonEnabled = true;  buttonTitle = "Disconnect…"
        }
        self.connectDisconnectCell.textLabel!.text = buttonTitle
        self.connectDisconnectCell.selectionStyle = buttonEnabled ? .default : .none
    }
    
    func connectDisconnectAction() {
        switch self.manager.status {
            case .invalid:
                break
            case .disconnected:
                self.manager.connect()
            case .connecting, 
                 .connected, 
                 .reasserting, 
                 .disconnecting:
                self.manager.disconnect()
        }
    }
    
    func sendAppMessageAction() {
        self.manager.sendAppMessage()
    }
}
