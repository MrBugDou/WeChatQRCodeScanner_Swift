//
// CodeImageScanner.swift
//
// Copyright (c) 2024 DouDou
//
// Created by DouDou on 2024/1/15.
//

import AVFoundation
import Foundation
import UIKit
import Vision

public struct CodeImageScanner {
    public static let shared = CodeImageScanner()
    let scanner = DDCodeImageScanner.shared()
    public func scan(with image: UIImage) -> [ScanResult] {
        let datas = scanner.scan(for: image)
        guard !datas.isEmpty else {
            return detect(with: image)
        }
        var results: [ScanResult] = []
        for data in datas {
            guard !data.content.isEmpty else {
                continue
            }
            results.append(.init(content: data.content, rectOfImage: data.rectOfImage, type: .qr))
        }
//        detect(with: image)
        return results
    }

    public func detect(with image: UIImage?) -> [ScanResult] {
        guard let features = detectQRCode(image), !features.isEmpty else {
            return detectBarCode(image)
        }
        return features
    }

    private func detectQRCode(_ image: UIImage?) -> [ScanResult]? {
        guard let image = image, let ciImage = CIImage(image: image) else {
            return nil
        }
        
        // 创建CIDetector用于二维码识别
        let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: .init(), options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
        
        let orientationKey = kCGImagePropertyOrientation as String
        let orientationValue = ciImage.properties[orientationKey] ?? 1
        let options = [CIDetectorImageOrientation: orientationValue]
        
        guard let features = detector?.features(in: ciImage, options: options), !features.isEmpty else {
            return nil
        }
    
        var detectedBarcodes: [ScanResult] = []
        for data in features {
            guard let feature = data as? CIQRCodeFeature, let value = feature.messageString, !value.isEmpty else {
                break
            }
            detectedBarcodes.append(.init(content: value, rectOfImage: feature.bounds, type: .qr))
        }
        
        return detectedBarcodes
    }

    private func detectBarCode(_ image: UIImage?) -> [ScanResult] {
        guard let cgimg = image?.cgImage, #available(iOS 11.0, *) else {
            return []
        }
        var detectedBarcodes: [ScanResult] = []
        let request = VNDetectBarcodesRequest { req, err in
            if let error = err {
                Log.error("parseBarCode error: \(error)")
                return
            }
            guard let results = req.results, !results.isEmpty else {
                return
            }
            for result in results {
                Log.debug("result: \(result)")
                if let barcode = result as? VNBarcodeObservation, let value = barcode.payloadStringValue {
                    let rectOfImage = convertRect(barcode.boundingBox, image)
                    if barcode.symbology == .qr { // 二维码
                        detectedBarcodes.append(.init(content: value, rectOfImage: rectOfImage, type: .qr))
                        Log.debug("qrcode: \(value) rectOfImage: \(rectOfImage)")
                    } else { // 条形码
                        guard let type = convert(from: barcode.symbology) else {
                            Log.debug("不支持的类型 qrcode: \(value) rectOfImage: \(rectOfImage)")
                            continue
                        }
                        detectedBarcodes.append(.init(content: value, rectOfImage: rectOfImage, type: type))
                        Log.debug("barcode: \(value), rectOfImage: \(rectOfImage), \(barcode.symbology.rawValue)")
                    }
                    break
                }
            }
        }
        let handler = VNImageRequestHandler(cgImage: cgimg)
        do {
            try handler.perform([request])
        } catch {
            Log.error("parseBarCode error: \(error)")
        }
        return detectedBarcodes
    }

    @available(iOS 11.0, *)
    func convert(from objectType: VNBarcodeSymbology) -> AVMetadataObject.ObjectType? {
        switch objectType {
        case .qr:
            return .qr
        case .ean8:
            return .ean8
        case .ean13:
            return .ean13
        case .code128:
            return .code128
        default:
            return nil
        }
    }

    /// image坐标转换
    private func convertRect(_ rectangleRect: CGRect, _ image: UIImage?) -> CGRect {
        guard let image = image else { return .zero }
        // 此处是将Image的实际尺寸转化成imageView的尺寸
        let imageSize = image.size
        let w = rectangleRect.width * imageSize.width
        let h = rectangleRect.height * imageSize.height
        let x = rectangleRect.minX * imageSize.width
        // 该Y坐标与UIView的Y坐标是相反的
        let y = (1 - rectangleRect.minY) * imageSize.height - h
        return CGRect(x: x, y: y, width: w, height: h)
    }
}
