import RxSwift
import WebKit
import RxWebKit

public typealias JSBReceiver = (Bool, [String: Any]) -> Void

public class WKWebViewJSBridge: WKWebView {
    public private(set) var basePath = "app"
    public private(set) var toPath = "receiveNative"
    
    private var receiverPool: [String: JSBReceiver] = [:]
    
    private let bag = DisposeBag()
    private var disposeBagDefault: Disposable?
    private var disposeBagScript: [String: Disposable] = [:]
    
    private enum KEY: String, CaseIterable {
        case requestIDSwift // Swift에서 요청시 설정
        case requestIDWeb   // JS에서 요청시 설정
    }
    
    public override init(frame: CGRect, configuration: WKWebViewConfiguration) {
        super.init(frame: frame, configuration: configuration)
        setDefaultReceiver()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setDefaultReceiver()
    }
    
    public func setDefaultReceiver(_ basePath: String = "app", toPath: String = "receiveNative") {
        // dispose old script
        if let disposeBagDefault = disposeBagDefault {
            disposeBagDefault.dispose()
            self.configuration.userContentController.removeScriptMessageHandler(forName: self.toPath)
        }
        
        self.basePath = basePath
        self.toPath = toPath
#if DEBUG
        /// webview inspector
        self.configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")
#endif
        // receive JSBridge
        let scriptDispose = self.configuration.userContentController.rx.scriptMessage(forName: self.toPath)
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
            }
        disposeBagDefault = scriptDispose
    }
    
    public func requestWeb(name: String = "receiveWeb", param: [String: Any] = [:], receiver: JSBReceiver? = nil) {
        let requestID = UUID().uuidString
        var param = param
        param[KEY.requestIDSwift.rawValue] = requestID
        
        guard let json = try? JSONSerialization.data(withJSONObject: param, options: .prettyPrinted)
        else {
            receiver?(false, param)
            return
        }
                
        if let receiver = receiver {
            _ = addReceiverHandler(name: requestID, receiver)
        }
        
        let jsonBase64 = json.base64EncodedString()
        let request = "\(self.basePath).\(name)('\(jsonBase64)');"
        printWKWebViewJSBridge("Request -> Web : \(request)")
        
        self.rx.evaluateJavaScript(request)
            .debug("evaluateJavaScript")
            .subscribe(onError: { error in
                printWKWebViewJSBridge(error)
                self.receiverPool[requestID] = nil
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
    
    static public func isNeedReceive(_ data: [String: Any]) -> Bool {
        if let requestIDWeb = data[KEY.requestIDWeb.rawValue] as? String,
           !requestIDWeb.isEmpty {
            return true
        }
        return false
    }
}
