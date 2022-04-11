import XCTest
@testable import WKWebViewJSBridge

final class WKWebViewJSBridgeTests: XCTestCase {
    func test_requestWeb() {
        let bridge = WKWebViewJSBridge()
        let bridgeMirror = WKWebViewJSBridgeMirror(bridge)
        bridge.requestWeb()
        XCTAssertEqual(bridgeMirror.receiverPool?.count, 0)
        bridge.requestWeb(receiver: { _, _ in })
        XCTAssertEqual(bridgeMirror.receiverPool?.count, 1)
    }
    
    func test_addReceiverHandler() {
        let bridge = WKWebViewJSBridge()
        let bridgeMirror = WKWebViewJSBridgeMirror(bridge)
        var actual = bridge
            .addReceiverHandler(name: "test0", {_,_ in })
        XCTAssertEqual(actual, bridge)
        XCTAssertEqual(bridgeMirror.receiverPool?.count, 1)
        actual = bridge
            .addReceiverHandler(name: "test0", {_,_ in })
            .addReceiverHandler(name: "test1", {_,_ in })
        XCTAssertEqual(actual, bridge)
        XCTAssertEqual(bridgeMirror.receiverPool?.count, 2)
        actual = bridge
            .addReceiverHandler(name: "test2", {_,_ in })
        XCTAssertEqual(actual, bridge)
        XCTAssertEqual(bridgeMirror.receiverPool?.count, 3)
    }
    
    func test_isNeedReceive() {
        var actual = WKWebViewJSBridge.isNeedReceive(["requestIDWeb":"test"])
        XCTAssertTrue(actual)
        actual = WKWebViewJSBridge.isNeedReceive(["requestIDWeb":""])
        XCTAssertFalse(actual)
        actual = WKWebViewJSBridge.isNeedReceive(["":""])
        XCTAssertFalse(actual)
    }
}

class WKWebViewJSBridgeMirror: MirrorObject {
    init(_ instance: WKWebViewJSBridge) {
        super.init(reflecting: instance)
    }
    // List all private properties you wish to test using SAME NAME.
    var receiverPool: [String: JSBReceiver]? {
        extract()
    }
}
