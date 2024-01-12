//
// CodeScannerResult.swift
//
// Copyright (c) 2024 DouDou
//
// Created by DouDou on 2022/6/11.
//

import UIKit
import Vision

enum Log {
    public static func verbose(_ message: Any..., file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        let dformatter = DateFormatter()
        dformatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let dateStr = dformatter.string(from: Date())
        #if DEBUG
        print("CodeScanner 🟪 [VERBOSE] \(dateStr) \(fileName):\(line) \(function) ||", message, "🟪")
        #endif
    }

    public static func debug(_ message: Any..., file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        let dformatter = DateFormatter()
        dformatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let dateStr = dformatter.string(from: Date())
        #if DEBUG
        print("CodeScanner 🟩 [DEBUG] \(dateStr) \(fileName):\(line) \(function) ||", message, "🟩")
        #endif
    }

    public static func info(_ message: Any..., file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        let dformatter = DateFormatter()
        dformatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let dateStr = dformatter.string(from: Date())
        #if DEBUG
        print("CodeScanner 🟦 [INFO] \(dateStr) \(fileName):\(line) \(function) ||", message, "🟦")
        #endif
    }

    public static func warning(_ message: Any..., file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        let dformatter = DateFormatter()
        dformatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let dateStr = dformatter.string(from: Date())
        #if DEBUG
        print("CodeScanner 🟨 [WARNING] \(dateStr) \(fileName):\(line) \(function) ||", message, "🟨")
        #endif
    }

    public static func error(_ message: Any..., file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        let dformatter = DateFormatter()
        dformatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let dateStr = dformatter.string(from: Date())
        #if DEBUG
        print("CodeScanner 🟥 [ERROR] \(dateStr) \(fileName):\(line) \(function) ||", message, "🟥")
        #endif
    }
}

public struct CodeScannerResult {
    public let content: String
    public let rectOfImage: CGRect
    public let type: VNBarcodeSymbology
    public init(content: String, rectOfImage: CGRect, type: VNBarcodeSymbology) {
        self.type = type
        self.content = content
        self.rectOfImage = rectOfImage
    }
}
