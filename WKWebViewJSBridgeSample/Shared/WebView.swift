//
//  WebView.swift
//  WKWebViewJSBridgeSample
//
//  Created by won on 2022/03/18.
//

import SwiftUI
import WebKit
import WKWebViewJSBridge

struct WebView: UIViewRepresentable {
    var webviewJSB = WKWebViewJSBridge()
    
    init() {
        webviewJSB.initJSBridge()
        webviewJSB.loadHTMLString(WebView.jsSample, baseURL: nil)
    }
    
    func makeUIView(context: Context) -> WKWebViewJSBridge {
        return webviewJSB
    }
    
    func updateUIView(_ webView: WKWebViewJSBridge, context: Context) {
        print(WebView.jsSample)
    }
    
    func addReceiverHandler(name: String, _ receiver: @escaping JSBReceiver) -> WebView {
        _ = webviewJSB.addReceiverHandler(name: name, receiver)
        return self
    }
    
    internal static let jsSample: String = {
        let jsPath = Bundle.main.url(forResource: "JSBridge", withExtension: "js")!
        let js = try! String(contentsOf: jsPath)
        
        return js
    }()
}
