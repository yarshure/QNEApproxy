/*
    <samplecode>
        <abstract>
            Main app controller.
        </abstract>
    </samplecode>
 */

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        self.window.makeKeyAndOrderFront(self)
    }

    let networkTests = NetworkTests()

    @IBAction func testTCPAction(_ sender: Any) {
        self.networkTests.testTCPStream(host: "imap.mail.me.com", port: 993, useTLS: true, helloMessage: "a001 NOOP\r\n")
    }

    @IBAction func testURLSessionAction(_ sender: Any) {
        self.networkTests.testURLSession()
    }
}
