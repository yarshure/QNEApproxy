/*
    <samplecode>
        <abstract>
            Model object that represents our configuration.
        </abstract>
    </samplecode>
 */

import Foundation

struct CustomConfiguration {
    var dummy: Bool
    
    init() {
        self.init(dummy: false)
    }
    
    init(dummy: Bool) {
        self.dummy = dummy
    }
    
    init(providerConfiguration: [String : Any]?) {
        func value(for key: String) -> Bool {
            guard let customConfiguration = providerConfiguration, 
                  let value = customConfiguration[key], 
                  let number = value as? NSNumber else {
                return false
            }
            return number.boolValue
        }
        self.dummy = value(for: "dummy")
    }
}
