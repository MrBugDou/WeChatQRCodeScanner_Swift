//
// Bundle+.swift
//
// Copyright (c) 2024 DouDou
//
// Created by DouDou on 2022/6/8.
//

import UIKit

private class BundleClass {}

public extension Bundle {
    /// 框架 bundle
    static var codeScanner: Bundle {
        let mainBundle: Bundle = .init(for: BundleClass.self)
        if let resourcePath = mainBundle.path(forResource: "WeChatQRCodeScanner", ofType: "bundle") {
            return Bundle(path: resourcePath) ?? mainBundle
        }
        return mainBundle
    }
}
