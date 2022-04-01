//
//  File.swift
//  
//
//  Created by won on 2022/03/21.
//

import Foundation

/// debug 모드에서만 print 함
func printWKWebViewJSBridge(_ object: Any...) {
#if DEBUG
    Swift.print("[WKWebViewJSBridge] \(object)")
#endif
}

/// Base64 인코딩 Json 데이터를 Dictionary로 디코딩
/// - Parameter input: Base64로 인코딩 된 Json
func jsonObjFromBase64(_ input: Any?) -> [String: Any] {
    guard let strBase64 = input as? String,
          let dataBase64 = Data(base64Encoded: strBase64),
          let jsonString = String(data: dataBase64, encoding: .utf8),
          let encodeString = jsonString.removingPercentEncoding,
          let dataString = encodeString.data(using: .utf8),
          let retObj = try? JSONSerialization.jsonObject(with: dataString, options: []) as? [String: Any]
    else { return [:]}
    return retObj
}
