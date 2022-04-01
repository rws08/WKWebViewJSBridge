import RxSwift
import WebKit
import RxWebKit

public typealias JSBReceiver = (Bool, [String: Any]?) -> Void

public class WKWebViewJSBridge {
    public private(set) var webView: WKWebView
    public private(set) var basePath = "app"
    public private(set) var toPath = "receiveNative"
    
    static private var receivePool: [String: JSBReceiver] = [:]
    
    private let bag = DisposeBag()
    
    private enum KEY: String, CaseIterable {
        case requestIDSwift
        case requestIDWeb
        case requestPath
    }

    public init(_ webview: WKWebView, basePath: String = "app", toPath: String = "receiveNative") {
        self.webView = webview
        self.basePath = basePath
        self.toPath = toPath
#if DEBUG
        /// webview inspector
        self.webView.configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")
#endif
        setReceiver()
    }
    
    private func setReceiver() {
        // receive JSBridge
        webView.configuration.userContentController.rx.scriptMessage(forName: toPath)
            .bind { scriptMessage in
                printWKWebViewJSBridge("Received <- Web: \(scriptMessage.body)")
                let receiveJson = jsonObjFromBase64(scriptMessage.body)
                printWKWebViewJSBridge("Received <- Web: \(receiveJson)")
                
                KEY.allCases.forEach { item in
                    if let requestKey = receiveJson[item.rawValue] as? String,
                       let regeistedReceiver = WKWebViewJSBridge.receivePool[requestKey] {
                        printWKWebViewJSBridge("regeistedReceiver")
                        regeistedReceiver(true, receiveJson)
                        if item == .requestIDSwift || item == .requestIDWeb {
                            WKWebViewJSBridge.receivePool[requestKey] = nil
                        }
                    }
                }
            }.disposed(by: self.bag)
    }
    
    public func requestWeb(path: String, param: [String: Any] = [:], receiver: JSBReceiver? = nil) {
        let requestID = UUID().uuidString
        var param = param
        param[KEY.requestIDSwift.rawValue] = requestID
        
        if let receiver = receiver {
            addReceiverHandler(name: requestID, receiver)
        }
        
        guard let json = try? JSONSerialization.data(withJSONObject: param, options: .prettyPrinted)
        else {
            receiver?(false, param)
            return
        }
        
        let jsonBase64 = json.base64EncodedString()
        let request = "\(self.basePath).\(path)('\(jsonBase64)');"
        printWKWebViewJSBridge("Request -> Web : \(request)")
        
        self.webView.rx.evaluateJavaScript(request)
            .debug("evaluateJavaScript")
            .subscribe(onNext: {
                let receiveJson = jsonObjFromBase64($0)
                printWKWebViewJSBridge("Completed <- Web : \(receiveJson)")
                
                if let receiver = receiver,
                   let requestIDWeb = receiveJson[KEY.requestIDWeb.rawValue] as? String,
                   requestID == requestIDWeb {
                    printWKWebViewJSBridge("Received <- Web: \(receiveJson)")
                    receiver(true, receiveJson)
                    WKWebViewJSBridge.receivePool[requestIDWeb] = nil
                }
            }, onError: { error in
                printWKWebViewJSBridge(error)
                WKWebViewJSBridge.receivePool[requestID] = nil
            }, onCompleted: {
                
            }, onDisposed: {
                
            }).dispose()
    }
        
    /// Web에서 호출한 JSBridge
    public func addReceiverHandler(name: String, _ receiver: @escaping JSBReceiver) {
        WKWebViewJSBridge.receivePool[name] = receiver
    }
}
