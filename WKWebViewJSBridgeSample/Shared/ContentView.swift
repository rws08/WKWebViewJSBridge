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
    @State private var textLog: [String] = []
    @State private var showWebView = false
    @Namespace var textLogID
    
    private let webview = WebView()
    
    func addLog(text: String?) {
        guard let text = text else { return }
        textLog.append(text)
    }
    
    func processJSBridge(_ data: [String: Any]) -> [String: Any] {
        var data = data
        data["result"] = true
        if let title = data["title"] as? String {
            data["title"] = "\(title), processed on swift"
        }
        return data
    }
    
    func receiveSwift(_ data: [String: Any]) {
        let jsonObj = processJSBridge(data)
        
        if WKWebViewJSBridge.isNeedReceive(jsonObj) {
            if let delay = jsonObj["delay"] as? Int {
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(delay)) {
                    webview.webviewJSB.requestWeb(param: jsonObj)
                }
            } else {
                webview.webviewJSB.requestWeb(param: jsonObj)
            }
        }
    }
    
    var body: some View {
        VStack {
            webview
                .addReceiverHandler(name: "OnlyRequest") { _, json in
                    addLog(text: json["title"] as? String)
                    receiveSwift(json)
                }
                .addReceiverHandler(name: "RoundRequest") { _, json in
                    addLog(text: json["title"] as? String)
                    receiveSwift(json)
                }
                .addReceiverHandler(name: "MultiRequest") { _, json in
                    addLog(text: json["title"] as? String)
                    receiveSwift(json)
                }
            VStack {
                ScrollViewReader { scrollview in
                    ScrollView {
                        VStack(alignment: .leading) {
                            ForEach(0..<textLog.count, id: \.self) { idx in
                                Text(textLog[idx])
                                    .font(.system(size: 12))
                                    .id(idx)
                            }
                            .onChange(of: textLog) { newValue in
                                scrollview.scrollTo(textLog.count - 1)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: 150)
                    .border(Color.red)
                    .padding([.leading, .trailing], 10)
                    
                    Button("Only Request") {
                        webview.webviewJSB.requestWeb(name: "OnlyRequest", param: ["title":"Only Requests from Swift"])
                    }
                    Button("Round Request") {
                        webview.webviewJSB.requestWeb(name: "RoundRequest", param: ["title":"Round Requests from Swift"]) { _, json in
                            addLog(text: json["title"] as? String)
                        }
                    }
                    Button("Multi Request") {
                        webview.webviewJSB.requestWeb(name: "MultiRequest", param: ["title":"Multi Requests from Swift 1", "delay":3]) { _, json in
                            addLog(text: json["title"] as? String)
                        }
                        
                        webview.webviewJSB.requestWeb(name: "MultiRequest", param: ["title":"Multi Requests from Swift 2", "delay":1]) { _, json in
                            addLog(text: json["title"] as? String)
                        }
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
