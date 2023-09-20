import NIO
import Foundation
import NetworkExtension

final class TCPFlowHandler: ChannelOutboundHandler {
    typealias OutboundIn = IOData
    var tcpFlow: NEAppProxyTCPFlow
    
    init(tcpFlow: NEAppProxyTCPFlow) {
        self.tcpFlow = tcpFlow
    }

    func write(context: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
        if case let .byteBuffer(buffer) = self.unwrapOutboundIn(data) {
            let outboundData = Data(buffer.readableBytesView)
            tcpFlow.write(outboundData) { error in
                if let error = error {
                    promise?.fail(error)
                } else {
                    promise?.succeed(())
                }
            }
        }
    }
}
