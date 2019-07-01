/*
    <samplecode>
        <abstract>
            Main view controller.
        </abstract>
    </samplecode>
 */

import UIKit

class MainViewController : UITableViewController {
    
    let networkTests = NetworkTests()

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch (indexPath.section, indexPath.row) {
            case (0, 0):
                self.networkTests.testTCPStream(host: "imap.mail.me.com", port: 993, useTLS: true, helloMessage: "a001 NOOP\r\n")
            case (0, 1):
                self.networkTests.testURLSession()
            case (0, 2):
                break   // handled by segue
            default:
                fatalError()
        }
        self.tableView.deselectRow(at: indexPath, animated: true)
    }
}
