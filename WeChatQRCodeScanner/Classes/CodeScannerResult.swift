//
//  CodeScannerResult.swift
//  WeChatQRCodeScanner
//
//  Created by DouDou on 2022/6/11.
//

import Foundation

public struct CodeScannerResult {
    public let content: String
    public let rectOfView: CGRect
    public let rectOfImage: CGRect
    public init(content: String, rectOfImage: CGRect, rectOfView: CGRect = .zero) {
        self.content = content
        self.rectOfView = rectOfView
        self.rectOfImage = rectOfImage
    }
}
