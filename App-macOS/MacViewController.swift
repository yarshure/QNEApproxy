/*
    <samplecode>
        <abstract>
            Main view controller.
        </abstract>
    </samplecode>
 */

import Cocoa

class MacViewController : NSViewController {

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
    
    // On iOS we can do our initial setup in `viewDidLoad()` but on macOS that's
    // not possible due to the way in which view controllers are loaded by the window
    // controller.  Rather, we defer our initial setup work to `viewWillAppear()`.
    // The problem with that is that `viewWillAppear()` can be called more than once,
    // so we need a bool to keep track of whether we've done our setup yet.
    
    var needsInitialSetup: Bool = true
    
    override func viewWillAppear() {
        super.viewWillAppear()
        assert(self.manager != nil)
        if self.needsInitialSetup {
            self.needsInitialSetup = false
            self.updateStateUIFromManager()
            self.updateStatusUIFromManager()
        }
    }

    // MARK: - state
    
    @IBOutlet var stateLabel: NSTextField!

    @IBOutlet var enableSwitch: NSButton!
    @IBOutlet var dummySwitch: NSButton!
    var vendorConfigurationSwitches: [NSButton] { return [dummySwitch] }
    
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
        self.stateLabel.stringValue = stateText
        if let snapshot = snapshot {
            self.vendorConfigurationSwitches[0].isOn = snapshot.customConfiguration.dummy
            self.enableSwitch.isOn = snapshot.isEnabled
        } else {
            self.vendorConfigurationSwitches.forEach { $0.isOn = false }
            self.enableSwitch.isOn = false
        }
    }

    // MARK: - status

    @IBOutlet var statusLabel: NSTextField!
    @IBOutlet var connectDisconnectButton: NSButton!
    
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
        self.statusLabel.stringValue = statusText
        
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
        self.connectDisconnectButton.title = buttonTitle
        self.connectDisconnectButton.isEnabled = buttonEnabled
    }
    
    @IBAction func connectDisconnectAction(_ sender: Any) {
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

    @IBAction func sendAppMessageAction(_ sender: Any) {
        self.manager.sendAppMessage()
    }
}

extension NSButton {
    var isOn: Bool {
        get {
            return self.intValue != 0
        }
        set {
            self.intValue = newValue ? 1 : 0
        }
    }
}

