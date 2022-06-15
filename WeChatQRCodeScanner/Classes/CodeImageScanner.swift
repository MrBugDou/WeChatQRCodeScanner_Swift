//
//  CodeImageScanner.swift
//  WeChatQRCodeScanner
//
//  Created by DouDou on 2022/6/11.
//

import Foundation
import opencv2

public struct CodeImageScanner {
    
    public static let shared = CodeImageScanner()
    
    let scanner: WeChatQRCode
    
    init() {
        guard let detectPrototxt = R.file.detectPrototxt.path(),
              let detectCaffemodel = R.file.detectCaffemodel.path(),
              let srPrototxt = R.file.srPrototxt.path(),
              let srCaffemodel = R.file.srCaffemodel.path() else {
                  scanner = .init()
                  return
              }
        scanner = .init(detector_prototxt_path: detectPrototxt,
                        detector_caffe_model_path: detectCaffemodel,
                        super_resolution_prototxt_path: srPrototxt,
                        super_resolution_caffe_model_path: srCaffemodel)
    }
    
    public func scan(with image: UIImage) -> [CodeScannerResult] {
        return scan(with: image.mat())
    }
    
    public func scan(with image: Mat) -> [CodeScannerResult] {
        var points: [Mat] = []
        let ret = scanner.detectAndDecode(img: image, points: &points)
        var result: [CodeScannerResult] = []
        for idx in 0 ..< ret.count  {
            let point = points[idx]
            let left = (point.get(row: 0, col: 0).first ?? 0)
            let top = (point.get(row: 0, col: 1).first ?? 0)
            let right = (point.get(row: 1, col: 0).first ?? 0)
            let bottom = (point.get(row: 2, col: 1).first ?? 0)
            let rectOfImage = CGRect(x: left, y: top, width: right - left, height: bottom - top)
            result.append(.init(content: ret[idx], rectOfImage: rectOfImage))
        }
        return result
    }
    
}
