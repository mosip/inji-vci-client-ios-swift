//
//  File.swift
//  
//
//  Created by Kiruthika Jeyashankar on 09/09/24.
//

import Foundation

extension Data {
    init?(base64EncodedURLSafe string: String, options: Base64DecodingOptions = []) {
        let string =
        string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        self.init(base64Encoded: string, options: options)
    }
}
