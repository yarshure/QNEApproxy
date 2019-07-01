/*
    <samplecode>
        <abstract>
            Tests built in to the app to exercise the provider.
        </abstract>
    </samplecode>
 */

import Foundation
import NetworkExtension

class NetworkTests : NSObject {
    
    init(useOwnQueue: Bool = false) {
        if useOwnQueue {
            self.queue = DispatchQueue.main
        } else {
            self.queue = DispatchQueue(label: "QNEAppProxy.xxx.NetworkTests")
        }
    }

    func testTCPStream(host: String, port: Int, useTLS: Bool, helloMessage: String = "") {
        self.queue.async {
            self.streamTest(host: host, port: port, useTLS: useTLS, helloMessage: helloMessage)
        }
    }
    
    func testNWConnection(provider: NEProvider, host: String, port: Int, useTLS: Bool, helloMessage: String = "") {
        self.queue.async {
            self.nwConnectionTest(provider: provider, host: host, port: port, useTLS: useTLS, helloMessage: helloMessage)
        }
    }
    
    func testURLSession() {
        self.sessionTest()
    }

    fileprivate var streams: (inputStream: InputStream, outputStream: OutputStream)? = nil
    fileprivate var connection: NWTCPConnection? = nil
    fileprivate var readPending: Bool = false
    fileprivate var helloMessage = Data()
    fileprivate var queue: DispatchQueue
}

// MARK: - TCP Stream Test

extension NetworkTests : StreamDelegate {

    fileprivate func streamTest(host: String, port: Int, useTLS: Bool, helloMessage: String) {
        if let streams = self.streams {
            NSLog("stream stop")
            self.stop(streams: streams)
        } else {
            NSLog("stream start")
            // for HTTP/HTTPS: "GET / HTTP/1.1\r\nHost: httpbin.org\r\nConnection:close\r\n\r\n"
            // for IMAP: "a001 NOOP\r\n"
            self.start(name: host, port: port, useTLS: useTLS, helloMessage: helloMessage)
        }
    }
    
    private func start(name: String, port: Int, useTLS: Bool, helloMessage: String) {
        self.helloMessage = helloMessage.data(using: .utf8)!
        let streams = Stream.streamsToHost(name: name, port: port)
        self.streams = streams
        
        if useTLS {
            let success = streams.inputStream.setProperty(StreamSocketSecurityLevel.negotiatedSSL as AnyObject, forKey: Stream.PropertyKey.socketSecurityLevelKey)
            precondition(success)
        }
        
        CFReadStreamSetDispatchQueue( streams.inputStream  as CFReadStream,  self.queue)
        CFWriteStreamSetDispatchQueue(streams.outputStream as CFWriteStream, self.queue)
        for s in [streams.inputStream, streams.outputStream] {
            s.delegate = self
            s.open()
        }
    }

    private func stop(streams: (inputStream: InputStream, outputStream: OutputStream)) {
        CFReadStreamSetDispatchQueue( streams.inputStream  as CFReadStream,  nil)
        CFWriteStreamSetDispatchQueue(streams.outputStream as CFWriteStream, nil)
        for s in [streams.inputStream, streams.outputStream] {
            s.delegate  = nil
            s.close()
        }
        self.streams = nil
    }
    
    func stream(_ thisStream: Stream, handle eventCode: Stream.Event) {
        guard let streams = self.streams else { fatalError() }
        let streamName = thisStream == streams.inputStream ? " input" : "output"
        switch eventCode {
            case Stream.Event.openCompleted:
                NSLog("%@ stream did open", streamName)
                break
            case Stream.Event.hasBytesAvailable:
                NSLog("%@ stream has bytes", streamName)

                var buffer = [UInt8](repeating: 0, count: 2048)
                let bytesRead = streams.inputStream.read(&buffer, maxLength: buffer.count)
                if bytesRead > 0 {
                    NSLog("%@ stream read %@", streamName, NSData(bytes: &buffer, length: bytesRead))
                }
            case Stream.Event.hasSpaceAvailable:
                NSLog("%@ stream has space", streamName)
                if !self.helloMessage.isEmpty {
                    let writeCount = self.helloMessage.withUnsafeBytes { (p: UnsafePointer<UInt8>) -> Int in
                        return streams.outputStream.write(p, maxLength: self.helloMessage.count)
                    }
                    if writeCount < 0 {
                        NSLog("%@ stream write error", streamName)
                    } else {
                        NSLog("%@ stream write %@", streamName, Data(self.helloMessage.prefix(upTo: writeCount)) as NSData)
                        self.helloMessage.removeFirst(writeCount)
                    }
                }
            case Stream.Event.endEncountered:
                NSLog("%@ stream end", streamName)
                self.stop(streams: streams)
            case Stream.Event.errorOccurred:
                let error = thisStream.streamError! as NSError
                NSLog("%@ stream error %@ / %d", streamName, error.domain, error.code)
                self.stop(streams: streams)
            default:
                fatalError()
        }
    }
}

private extension Stream {

    static func streamsToHost(name hostname: String, port: Int) -> (inputStream: InputStream, outputStream: OutputStream) {
        var inStream: InputStream? = nil
        var outStream: OutputStream? = nil
        Stream.getStreamsToHost(withName: hostname, port: port, inputStream: &inStream, outputStream: &outStream)
        return (inStream!, outStream!)
    }
}

// MARK: - NWTCPConnection Test

private var sConnectionContext = false

extension NetworkTests {

    fileprivate func nwConnectionTest(provider: NEProvider, host: String, port: Int, useTLS: Bool, helloMessage: String) {
        if let connection = self.connection {
            NSLog("connection stop")
            self.stop(connection: connection)
        } else {
            NSLog("connection start")
            self.start(provider: provider, host: host, port: port, useTLS: useTLS, helloMessage: helloMessage)
        }
    }

    private func start(provider: NEProvider, host: String, port: Int, useTLS: Bool, helloMessage: String) {
        self.helloMessage = helloMessage.data(using: .utf8)!
        let endpoint = NWHostEndpoint(hostname: host, port: "\(port)")
        let connection = provider.createTCPConnection(to: endpoint, enableTLS: useTLS, tlsParameters: nil, delegate: nil)
        connection.addObserver(self, forKeyPath: #keyPath(NWTCPConnection.state), options: [], context: &sConnectionContext)
        self.connection = connection
    }
    
    private func stop(connection: NWTCPConnection) {
        self.connection?.removeObserver(self, forKeyPath: #keyPath(NWTCPConnection.state), context: &sConnectionContext)
        self.connection = nil
        self.readPending = false
    }
    
    internal override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &sConnectionContext {
            self.queue.async {
                if let connection = self.connection {
                    self.stateDidChange(connection: connection)
                }
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    private func stateDidChange(connection: NWTCPConnection) {
        switch connection.state {
            case .cancelled:
                NSLog("connection state cancelled")
            case .connected:
                NSLog("connection state connected")
                if !self.readPending {
                    self.startRead(connection: connection)
                }
                if !self.helloMessage.isEmpty {
                    self.writeHelloMessage(connection: connection)
                }
            case .connecting:
                NSLog("connection connecting")
            case .disconnected:
                NSLog("connection state disconnected")
                self.stop(connection: connection)
            case .invalid:
                NSLog("connection state invalid")
                self.stop(connection: connection)
            case .waiting:
                NSLog("connection state waiting")
        }
    }
    
    private func startRead(connection: NWTCPConnection) {
        self.readPending = true
        connection.readLength(2048) { (data, error) in
            self.queue.async {
                self.readPending = false
                if let data = data {
                    NSLog("connection read %@", data as NSData)
                }
                if let error = error {
                    _ = error
                    NSLog("connection read error")
                    self.stop(connection: connection)
                } else {
                    self.startRead(connection: connection)
                }
            }
        }
    }

    private func writeHelloMessage(connection: NWTCPConnection) {
        let data = self.helloMessage
        self.helloMessage.removeAll()
        connection.write(data) { error in
            if let error = error {
                _ = error
                NSLog("connection write error")
                self.stop(connection: connection)
            } else {
                NSLog("connection write %@", data as NSData)
            }
        }
    }
}

// MARK: - NSURLSession Test

extension NetworkTests {

    fileprivate func sessionTest() {
        let url = URL(string: "https://httpbin.org")!
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 60.0)
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error as NSError? {
                NSLog("session error %@ / %d", error.domain, error.code)
            } else {
                let response = response as! HTTPURLResponse
                let data = data!
                NSLog("session success, status %d, bytes %d", response.statusCode, data.count)
            }
        }.resume()
    }
}
