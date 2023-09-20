/*
    <samplecode>
        <abstract>
            A minimal app proxy provider.
        </abstract>
    </samplecode>
 */

import NetworkExtension
#if os(iOS)
import UserNotifications
#endif

import NIO
import NIOHTTP1

class Provider : NEAppProxyProvider {

    let networkTests = NetworkTests(useOwnQueue: true)

    private static var protocolConfigurationKVO: Int = 0
    
    override init() {
        NSLog("QNEAppProxy.Provider: init")
        super.init()
        // Can't access the configuration here; it's not set up yet (worse yet, it's actually nil!).
        // Instead we set up a KVO observer to watch for changes, which we need to be doing anyway.
        self.addObserver(self, forKeyPath: #keyPath(protocolConfiguration), options: [], context: &Provider.protocolConfigurationKVO)
    }
    
    deinit {
        self.removeObserver(self, forKeyPath: #keyPath(protocolConfiguration), context: &Provider.protocolConfigurationKVO)
    }

    var customConfiguration = CustomConfiguration()

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &Provider.protocolConfigurationKVO {
            self.customConfiguration = CustomConfiguration(providerConfiguration: (self.protocolConfiguration as? NETunnelProviderProtocol)?.providerConfiguration)
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        } 
    }

    override func startProxy(options: [String : Any]? = nil, completionHandler: @escaping (Error?) -> Void) {
        NSLog("QNEAppProxy.Provider: start")

        let settings = NETunnelNetworkSettings(tunnelRemoteAddress: "93.184.216.34")
        
        self.setTunnelNetworkSettings(settings) { error in
            NSLog("QNEAppProxy.Provider: start complete")
            completionHandler(error)
        }
    }

    override func stopProxy(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        NSLog("QNEAppProxy.Provider: stop")
        completionHandler()
    }

    override func handleNewFlow(_ flow: NEAppProxyFlow) -> Bool {
        NSLog("QNEAppProxy.Provider: new flow")
        
        guard let tcpFlow = flow as? NEAppProxyTCPFlow else { return false }
        
        let channel = EmbeddedChannel()
        
        channel.pipeline.configureHTTPServerPipeline().flatMap {
            channel.pipeline.addHandler(MyHTTPHandler())
        }.flatMap {
            channel.pipeline.addHandler(TCPFlowHandler(tcpFlow: tcpFlow), position: .first)
        }.whenComplete { result in
            switch result {
            case .success:
                print("Successfully added handlers.")
            case .failure(let error):
                print("Failed to add handlers: \(error)")
            }
        }

        tcpFlow.readData(completionHandler: { data, error in
            if let data = data {
                let buffer = channel.allocator.buffer(bytes: data)
                do {
                    try channel.writeInbound(buffer)
                } catch {
                    NSLog("Failed to write inbound data: \(error)")
                }
            }
        })
        
        tcpFlow.open(withLocalEndpoint: nil) { error in
            if let error = error {
                NSLog("\(error)")
            }
        }
        
        return true
    }
    
    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)? = nil) {
        NSLog("QNEAppProxy.Provider: app message %@", messageData as NSData)

        #if os(iOS)
            let content = UNMutableNotificationContent()
            content.title = "MyTitle"
            content.body = "\(Date())"
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5.0, repeats: false)
            
            // Create the request object.
            let request = UNNotificationRequest(identifier: "Hello Cruel World!", content: content, trigger: trigger)
            let center = UNUserNotificationCenter.current()
            center.add(request) { (error) in
                if let _ = error {
                    NSLog("QNEAppProxy.Provider: did not schedule")
                } else {
                    NSLog("QNEAppProxy.Provider: did schedule")
                }
            }
        #endif
        
        completionHandler?(messageData)
    }
    
    private func read(from tcpFlow: NEAppProxyTCPFlow, into channel: EmbeddedChannel) {
        tcpFlow.readData(completionHandler: { data, error in
            
        })
    }
    
}
