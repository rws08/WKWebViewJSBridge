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
    public var jsbridge: WKWebViewJSBridge
    
    private var webView = WKWebView()
    
    init() {
        webView.loadHTMLString(WebView.jsSample, baseURL: nil)
        jsbridge = WKWebViewJSBridge(webView)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        print(WebView.jsSample)
    }
    
    func addReceiverHandler(name: String, _ receiver: @escaping JSBReceiver) -> WebView {
        jsbridge.addReceiverHandler(name: name, receiver)
        return self
    }
    
    internal static let jsSample: String = {
        let jsPath = Bundle.main.url(forResource: "JSBridge", withExtension: "js")!
        let js = try! String(contentsOf: jsPath)
        
        return js
    }()
}
