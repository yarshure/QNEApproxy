/*
    <samplecode>
        <abstract>
            Main app controller.
        </abstract>
    </samplecode>
 */

import Cocoa

@NSApplicationMain
class MacAppDelegate: NSObject, NSApplicationDelegate {

    var mainWindowController: NSWindowController!
    var mainWindow: NSWindow!

    var manager: AppProxyManager?

    func applicationDidFinishLaunching(_ note: Notification) {
        NSLog("applicationDidFinishLaunching(_:)")
        let manager = AppProxyManager()
        self.manager = manager

        let s = NSStoryboard(name: .init(rawValue: "Main"), bundle: nil)
        self.mainWindowController = s.instantiateController(withIdentifier: .init(rawValue: "main")) as! NSWindowController
        self.mainWindow = self.mainWindowController.window!

        let main = self.mainWindow.contentViewController as! MacViewController
        main.manager = manager

        self.mainWindow.makeKeyAndOrderFront(self)
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
