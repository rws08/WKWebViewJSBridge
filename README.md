# WKWebViewJSBridge

## Description
WKWebView를 상속해서 JSBridge를 사용할 수 있도록 구현되어 있습니다.

<img width=60% alt="flow" src="https://user-images.githubusercontent.com/7792240/230246807-4f5b4cc2-89e9-43f4-8a6e-3137a4262f70.png">

## Installation

### Swift Package Manager

Use Xcode to add to the project (**File -> Swift Packages**) or add this to your `Package.swift` file:
```swift
.package(url: "https://github.com/rws08/WKWebViewJSBridge", from: "1.0.0")
```

## Usage

### Getting Started

Create an WKWebViewJSBridge

```swift
import WKWebViewJSBridge

let webviewJSB = WKWebViewJSBridge()
```

Request & Receive to JS from Swift (Swift -> JS)

```swift
webviewJSB.requestWeb(name: "RoundRequest", param: ["title":"Round Requests from Swift"]) { _, json in
}
```

Receive to Swift from JS (JS -> Swift)

```swift
webviewJSB.addReceiverHandler(name: "OnlyRequest") { _, json in
}
.addReceiverHandler(name: "RoundRequest") { _, json in
}
```

For details of JS, refer to the [`JSBridge.js`](https://github.com/rws08/WKWebViewJSBridge/blob/main/WKWebViewJSBridge/Tests/WKWebViewJSBridgeTests/JSBridge.js) file.

## License

Released under the [MIT license](https://github.com/rws08/WKWebViewJSBridge/blob/main/LICENSE).
