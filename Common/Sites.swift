/*
    <samplecode>
        <abstract>
            A static list of sites to load into the web view.
        </abstract>
    </samplecode>
 */

import Foundation

struct Sites {

    static let urlInfo: [(title: String, url: String)] = [
        ("Apple (HTTPS)",           "https://www.apple.com"), 
        ("httpbin.org",             "https://httpbin.org")
    ]

    static var sitesHTML: String {
        let lines = self.header + self.urlInfo.map { String(format: self.template, $0.url, $0.title) } + self.trailer
        return lines.joined(separator: "\n")
    } 

    private static let header = [  
        "<!DOCTYPE html>", 
        "<html lang=\"en\">", 
        "<head>", 
        "    <meta charset=\"utf-8\" />", 
        "    <meta name=\"viewport\" content=\"width=device-width\" />", 
        "    <title>Sites</title>", 
        "</head>", 
        "<body>", 
        "<ul>" 
    ]
    private static let template = "    <li><a href=\"%@\">%@</a></li>"
    private static let trailer = [
        "</ul>", 
        "</body>", 
        "</html>" 
    ]
}
