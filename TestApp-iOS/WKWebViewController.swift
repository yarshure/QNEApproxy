/*
    <samplecode>
        <abstract>
            A testbed for WKWebView.
        </abstract>
    </samplecode>
 */

import WebKit

class WKWebViewController : UIViewController, WKNavigationDelegate {

    var webView: WKWebView { return self.view as! WKWebView }

    override func loadView() {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: CGRect.zero, configuration: config)
        webView.navigationDelegate = self
        self.view = webView
    }

    @IBAction func rootAction(_ sender: AnyObject) {
        // var request = URLRequest(url: URL(string: "http://www.apple.com/")!)
        self.webView.loadHTMLString(Sites.sitesHTML, baseURL: nil)
    }

    @IBAction func testAction(_ sender: AnyObject) {
        NSLog("test")
    }
    
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        NSLog("did receive authentication challenge %@", challenge.protectionSpace.authenticationMethod)
        completionHandler(.performDefaultHandling, nil)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        NSLog("did fail provisional navigation %@", error as NSError)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        NSLog("did fail navigation %@", error as NSError)
    }
}
