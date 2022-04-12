//
//  Utils.swift
//  
//
//  Created by won on 2022/04/07.
//
// Source : https://digitalbunker.dev/how-to-test-private-methods-variables-in-swift/
//

import Foundation

class MirrorObject {
    let mirror: Mirror
    
    init(reflecting: Any) {
        mirror = Mirror(reflecting: reflecting)
    }
    
    func extract<T>(variableName: StaticString = #function) -> T? {
        extract(variableName: variableName, mirror: mirror)
    }
    
    private func extract<T>(variableName: StaticString, mirror: Mirror?) -> T? {
        guard let mirror = mirror else {
            return nil
        }
        
        guard let descendant = mirror.descendant("\(variableName)") as? T else {
            return extract(variableName: variableName, mirror: mirror.superclassMirror)
        }
        
        return descendant
    }
}
