//
//  ContentView.swift
//  Shared
//
//  Created by won on 2022/03/18.
//

import SwiftUI
import WebKit
import WKWebViewJSBridge

struct ContentView: View {
    @State private var textLog = ""
    @State private var showWebView = false
    
    private let webview = WebView()
    
    func addLog(text: String?) {
        guard let text = text else { return }
        textLog += "\(text)\n"
    }
    
    func processJSBridge(data: [String: Any]?) -> [String: Any]? {
        guard var data = data else { return data }
        data["result"] = true
        return data
    }
    
    var body: some View {
        VStack {
            webview
                .addReceiverHandler(name: "OnlyRequest") { _, json in
                    addLog(text: json?["title"] as? String)
                }
                .addReceiverHandler(name: "RoundRequest") { _, json in
                    addLog(text: json?["title"] as? String)
                }
                .addReceiverHandler(name: "MultiRequest") { _, json in
                    addLog(text: json?["title"] as? String)
                }
                .addReceiverHandler(name: "CustomRequest") { _, json in
                    addLog(text: json?["title"] as? String)
                }
            VStack {
                ScrollViewReader { scrollview in
                ScrollView {
                    VStack {
                        Text(textLog)
                            .font(.system(size: 12))
                            .lineLimit(nil)
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 100)
                .border(Color.red)
                Button("Request") {
                    webview.jsbridge.requestWeb(name: "receiveWeb", param: ["title":"Request"]) { _, json in
                        addLog(text: json?["result"] as? String)
                    }
                }
                Button("Only Request") {
                    webview.jsbridge.requestWeb(name: "OnlyRequest", param: ["title":"Only Requests from Swift"])
                }
                Button("Round Request") {
                    webview.jsbridge.requestWeb(name: "RoundRequest", param: ["title":"Round Requests from Swift"]) { _, json in
                        addLog(text: json?["title"] as? String)
                    }
                }
                Button("Multi Request") {
                    webview.jsbridge.requestWeb(name: "MultiRequest", param: ["title":"Multi Requests from Swift 1", "delay":3]) { _, json in
                        addLog(text: json?["title"] as? String)
                    }
                    
                    webview.jsbridge.requestWeb(name: "MultiRequest", param: ["title":"Multi Requests from Swift 2", "delay":1]) { _, json in
                        addLog(text: json?["title"] as? String)
                    }
                }
                Button("Custom Request") {
                    webview.jsbridge.requestWeb(name: "CustomRequest", param: ["title":"Custom Requests from Swift"])
                }
                Spacer()
                }
            }
            .frame(maxHeight: 400)
        }
        .background(Color.green.opacity(0.2))
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
