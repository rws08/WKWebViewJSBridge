import RxSwift
import WebKit
import RxWebKit

public typealias JSBReceiver = (Bool, [String: Any]) -> Void

public class WKWebViewJSBridge: WKWebView {
    public private(set) var basePath = "app"
    public private(set) var toPath = "receiveNative"
    
    private var receiverPool: [String: JSBReceiver] = [:]
    
    private let bag = DisposeBag()
    private var disposeBagScript: [String: Disposable] = [:]
    
    private enum KEY: String, CaseIterable {
        case requestIDSwift
        case requestIDWeb
        case requestAll
    }
    
    public func initJSBridge(_ basePath: String = "app", toPath: String = "receiveNative") {
        self.basePath = basePath
        self.toPath = toPath
#if DEBUG
        /// webview inspector
        self.configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")
#endif
        setReceiver()
    }
    
    private func setReceiver() {
        // receive JSBridge
        self.configuration.userContentController.rx.scriptMessage(forName: toPath)
            .bind { [weak self] scriptMessage in
                printWKWebViewJSBridge("Received <- Web: \(scriptMessage.body)")
                let receiveJson = jsonObjFromBase64(scriptMessage.body)
                printWKWebViewJSBridge("Received <- Web: \(receiveJson)")
                
                KEY.allCases.forEach { item in
                    if let requestKey = receiveJson[item.rawValue] as? String,
                       let regeistedReceiver = self?.receiverPool[requestKey] {
                        printWKWebViewJSBridge("regeistedReceiver")
                        regeistedReceiver(true, receiveJson)
                        if item == .requestIDSwift || item == .requestIDWeb {
                            self?.receiverPool[requestKey] = nil
                        }
                    }
                }
            }.disposed(by: self.bag)
    }
    
    public func requestWeb(name: String, param: [String: Any] = [:], receiver: JSBReceiver? = nil) {
        let requestID = UUID().uuidString
        var param = param
        param[KEY.requestIDSwift.rawValue] = requestID
        
        if let receiver = receiver {
            _ = addReceiverHandler(name: requestID, receiver)
        }
        
        guard let json = try? JSONSerialization.data(withJSONObject: param, options: .prettyPrinted)
        else {
            receiver?(false, param)
            return
        }
        
        let jsonBase64 = json.base64EncodedString()
        let request = "\(self.basePath).\(name)('\(jsonBase64)');"
        printWKWebViewJSBridge("Request -> Web : \(request)")
        
        self.rx.evaluateJavaScript(request)
            .debug("evaluateJavaScript")
            .subscribe(onNext: {
                let receiveJson = jsonObjFromBase64($0)
                printWKWebViewJSBridge("Completed <- Web : \(receiveJson)")
                
                if let receiver = receiver,
                   let requestIDWeb = receiveJson[KEY.requestIDWeb.rawValue] as? String,
                   requestID == requestIDWeb {
                    printWKWebViewJSBridge("Received <- Web: \(receiveJson)")
                    receiver(true, receiveJson)
                    self.receiverPool[requestIDWeb] = nil
                }
            }, onError: { error in
                printWKWebViewJSBridge(error)
                self.receiverPool[requestID] = nil
            }, onCompleted: {
                
            }, onDisposed: {
                
            }).dispose()
    }
        
    /// Web에서 호출한 JSBridge
    public func addReceiverHandler(name: String, _ receiver: @escaping JSBReceiver) -> WKWebViewJSBridge {
        self.receiverPool[name] = receiver
        // dispose old script
        if let oldScript = disposeBagScript[name] {
            oldScript.dispose()
            self.configuration.userContentController.removeScriptMessageHandler(forName: name)
        }
        // receive JSBridge
        let scriptDispose = self.configuration.userContentController.rx.scriptMessage(forName: name)
            .bind { [weak self] scriptMessage in
                printWKWebViewJSBridge("Received <- Web: \(scriptMessage.body)")
                let receiveJson = jsonObjFromBase64(scriptMessage.body)
                printWKWebViewJSBridge("Received <- Web: \(receiveJson)")
                
                if let regeistedReceiver = self?.receiverPool[name] {
                    regeistedReceiver(true, receiveJson)
                }
            }
        disposeBagScript[name] = scriptDispose
        
        return self
    }
}
