/*
    <samplecode>
        <abstract>
            Model object that exposes the NETunnelProviderManager state.
        </abstract>
    </samplecode>
 */

import NetworkExtension

class AppProxyManager {

    init() {
        self.state = .loading
        self.status = .invalid
        NotificationCenter.default.addObserver(self, selector: #selector(statusDidChange(note:)), name: NSNotification.Name.NEVPNStatusDidChange, object: nil)
        self.startLoading()
    }
    
    struct Snapshot {
        var isEnabled: Bool
        var customConfiguration: CustomConfiguration

        init(from manager: NEAppProxyProviderManager) {
            self.isEnabled = manager.isEnabled
            self.customConfiguration = CustomConfiguration(providerConfiguration: (manager.protocolConfiguration as? NETunnelProviderProtocol)?.providerConfiguration)
        }
    }
    
    enum State {
        case loading
        case reloading(manager: NEAppProxyProviderManager)
        case loaded(snapshot: Snapshot, manager: NEAppProxyProviderManager)
        case failed(error: Error)
    }
    
    private(set) var state: State {
        didSet {
            NotificationCenter.default.post(name: AppProxyManager.stateDidChange, object: self)
            self.updateStatus()
        }
    }
    
    static let stateDidChange = NSNotification.Name("AppProxyManager.stateDidChange")
    
    // MARK: - load
    
    func reload() {
        switch self.state {
            case .loading:
                fatalError()
            case .reloading:
                fatalError()
            case .loaded(_, let manager):
                self.state = .reloading(manager: manager)
                self.startReloading()
            case .failed:
                self.state = .loading
                self.startLoading()
        }
    }
    
    private func startLoading() {
        guard case .loading = self.state else { fatalError() }
        NEAppProxyProviderManager.loadAllFromPreferences { (managers, error) in
            assert(Thread.isMainThread)
            if let error = error {
                self.state = .failed(error: error)
            } else {
                let manager = managers?.first ?? NEAppProxyProviderManager()
                self.state = .loaded(snapshot: Snapshot(from: manager), manager: manager)
            }
        }
    }

    private func startReloading() {
        guard case .reloading(let manager) = self.state else { fatalError() }
        manager.loadFromPreferences { (error) in
            assert(Thread.isMainThread)
            if let error = error {
                self.state = .failed(error: error)
            } else {
                self.state = .loaded(snapshot: Snapshot(from: manager), manager: manager)
            }
        }
    }

    // MARK: - connection status
    
    private(set) var status: NEVPNStatus {
        didSet {
            NotificationCenter.default.post(name: AppProxyManager.statusDidChange, object: self)
        }
    }
    
    @objc func statusDidChange(note: Notification) {
        self.updateStatus()
    }
    
    private var session: NETunnelProviderSession? {
        let manager: NEAppProxyProviderManager?
        switch self.state {
            case .loading:          manager = nil
            case .reloading(let m): manager = m
            case .loaded(_, let m): manager = m
            case .failed:           manager = nil
        }
        return manager?.connection as? NETunnelProviderSession
    }
    
    private func updateStatus() {
        let newStatus = self.session?.status ?? .invalid
        if newStatus != self.status {
            self.status = newStatus
        }
    }

    static let statusDidChange = NSNotification.Name("AppProxyManager.statusDidChange")
    
    func connect() {
        precondition(self.status.canConnect)
        do {
            try self.session!.startTunnel(options: nil)
        } catch {
            NSLog("+++ connect failed")
        }
    }

    func disconnect() {
        precondition(self.status.canDisconnect)
        self.session!.stopTunnel()
    }
    
    func sendAppMessage() {
        guard let session = self.session else {
            NSLog("+++ app message no session")
            return
        }
        let message = "Hello Cruel World! \(Date())".data(using: .utf8)!
        NSLog("+++ will send app message %@", message as NSData)
        do {
            try session.sendProviderMessage(message) { (response) in
                NSLog("+++ did receive app message response %@", (response ?? Data()) as NSData)
            }
            NSLog("+++ did send app message")
        } catch {
            NSLog("+++ send app message failed: %@", "\(error)")
        }
    }
}

fileprivate extension NEVPNStatus {
    var canConnect: Bool {
        switch self {
            case .invalid:          return false
            case .disconnected:     return true
            case .connecting:       return false
            case .connected:        return false
            case .reasserting:      return false
            case .disconnecting:    return false
        }
    }
    var canDisconnect: Bool {
        switch self {
            case .invalid:          return false
            case .disconnected:     return false
            case .connecting:       return true
            case .connected:        return true
            case .reasserting:      return true
            case .disconnecting:    return true
        }
    }
}
