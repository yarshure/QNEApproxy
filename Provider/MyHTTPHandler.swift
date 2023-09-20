import NIO
import Foundation
import NIOHTTP1
import NetworkExtension

final class MyHTTPHandler: ChannelInboundHandler {
    typealias InboundIn = HTTPServerRequestPart
    typealias OutboundOut = HTTPServerResponsePart
    
    let encoder = HTTPResponseEncoder()

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let reqPart = self.unwrapInboundIn(data)

        NSLog("in channelRead")
        
        switch reqPart {
        case .head(let header):
            if (header.method != .GET) {
                return
            }
            NSLog(header.method.rawValue)
            // Handle HTTP header
            break
        case .body(let byteBuffer):
            // Handle HTTP body
            NSLog(byteBuffer.description)
            break
        case .end:
            // Handle end of request, send response
            var headers = HTTPHeaders()
            headers.add(name: "Content-Type", value: "text/plain")
            let head = HTTPResponseHead(version: .init(major: 1, minor: 1), status: .ok, headers: headers)
            context.write(self.wrapOutboundOut(HTTPServerResponsePart.head(head)), promise: nil)

            let buffer = context.channel.allocator.buffer(string: "Hello, world!")
            context.write(self.wrapOutboundOut(HTTPServerResponsePart.body(.byteBuffer(buffer))), promise: nil)

            context.writeAndFlush(self.wrapOutboundOut(HTTPServerResponsePart.end(nil))).whenComplete { result in
                switch result {
                    case .success:
                        NSLog("HTTP response write succeeded")
                        break
                    case .failure(let error):
                        NSLog("Write failed: \(error)")
                }
            }
            
        }
    }
}
