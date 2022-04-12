import XCTest
import WebKit
import RxSwift
@testable import WKWebViewJSBridge

final class WKWebViewJSBridgeTests: XCTestCase, WKNavigationDelegate {
    internal static let jsSample: String = {
        let jsPath = Bundle.module.url(forResource: "JSBridge", withExtension: "js")!
        let js = try! String(contentsOf: jsPath)
        
        return js
    }()
    
    var bridge: WKWebViewJSBridge!
    var bridgeMirror: WKWebViewJSBridgeMirror!
    var webViewExpectation: XCTestExpectation!
    
    override func setUp() {
        bridge = WKWebViewJSBridge()
        bridgeMirror = WKWebViewJSBridgeMirror(bridge)
        bridge.navigationDelegate = self
        
        webViewExpectation = expectation(description: "")
        bridge.loadHTMLString(WKWebViewJSBridgeTests.jsSample, baseURL: nil)
        wait(for: [webViewExpectation], timeout: 1)

        super.setUp()
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webViewExpectation.fulfill()
    }
    
    func test_setDefaultReceiver() {
        bridge.setDefaultReceiver("app", toPath: "receiveNative")
        XCTAssertNotNil(bridgeMirror.disposeBagDefault)
    }
    
    func test_requestWeb() {
        bridge.requestWeb()
        XCTAssertEqual(bridgeMirror.receiverPool?.count, 0)
        bridge.requestWeb(receiver: { _, _ in })
        XCTAssertEqual(bridgeMirror.receiverPool?.count, 1)
        
        let expectation = XCTestExpectation(description: "requestWeb")
        bridge.requestWeb(param: ["test": "test"]) { _, result in
            expectation.fulfill()
        }
        XCTAssertEqual(bridgeMirror.receiverPool?.count, 2)
        wait(for: [expectation], timeout: 1.0)
    }
    
    func test_addReceiverHandler() {
        var actual = bridge
            .addReceiverHandler(name: "test0", {_,_ in })
        XCTAssertEqual(actual, bridge)
        XCTAssertEqual(bridgeMirror.receiverPool?.count, 1)
        actual = bridge
            .addReceiverHandler(name: "test0", {_,_ in })
            .addReceiverHandler(name: "test1", {_,_ in })
        XCTAssertEqual(actual, bridge)
        XCTAssertEqual(bridgeMirror.receiverPool?.count, 2)
        
        let expectation = XCTestExpectation(description: "addReceiverHandler")
        actual = bridge
            .addReceiverHandler(name: "test2", {_,_ in
                expectation.fulfill()
            })
        XCTAssertEqual(actual, bridge)
        XCTAssertEqual(bridgeMirror.receiverPool?.count, 3)
        
        
        bridge.requestWeb(name: "test2")
        wait(for: [expectation], timeout: 1.0)
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
    
    var disposeBagDefault: Disposable? {
        extract()
    }
}
