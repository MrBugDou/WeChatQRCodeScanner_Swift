//
// UIImage+Mat.swift
//
// Copyright (c) 2024 DouDou
//
// Created by DouDou on 2022/6/13.
//

import opencv2
import UIKit

let CV_CN_SHIFT: Int32 = 3
let CV_DEPTH_MAX: Int32 = (1 << CV_CN_SHIFT)

let CV_8U: Int32 = 0

let CV_MAT_DEPTH_MASK = (CV_DEPTH_MAX - 1)
func CV_MAT_DEPTH(flags: Int32) -> Int32 {
    flags & CV_MAT_DEPTH_MASK
}

func CV_MAKETYPE(depth: Int32, cn: Int32) -> Int32 {
    CV_MAT_DEPTH(flags: depth) + ((cn - 1) << CV_CN_SHIFT)
}

let CV_8UC1 = CV_MAKETYPE(depth: CV_8U, cn: 1)
let CV_8UC2 = CV_MAKETYPE(depth: CV_8U, cn: 2)
let CV_8UC3 = CV_MAKETYPE(depth: CV_8U, cn: 3)
let CV_8UC4 = CV_MAKETYPE(depth: CV_8U, cn: 4)

extension UIImage {
    func mat() -> Mat {
        guard let cgImage = cgImage, var colorSpace = cgImage.colorSpace else { fatalError() }

        let cols = cgImage.width
        let rows = cgImage.height

        var bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue

        var mat: Mat

        let context: CGContext?

        if colorSpace.model == .monochrome {
            mat = Mat(rows: Int32(rows), cols: Int32(cols), type: CV_8UC1)
            bitmapInfo = CGImageAlphaInfo.none.rawValue
            if hasAlphaChannel {
                mat = mat.setTo(scalar: Scalar(0))
            }
            context = CGContext(
                data: mat.dataPointer(),
                width: cols,
                height: rows,
                bitsPerComponent: 8,
                bytesPerRow: mat.step1(),
                space: colorSpace,
                bitmapInfo: bitmapInfo)
        } else if colorSpace.model == .indexed {
            colorSpace = CGColorSpaceCreateDeviceRGB()
            mat = Mat(rows: Int32(rows), cols: Int32(cols), type: CV_8UC4)
            if !hasAlphaChannel {
                bitmapInfo = CGImageAlphaInfo.noneSkipLast.rawValue | CGImageByteOrderInfo.orderDefault.rawValue
            } else {
                mat = mat.setTo(scalar: Scalar(0))
            }
            context = CGContext(
                data: mat.dataPointer(),
                width: cols,
                height: rows,
                bitsPerComponent: 8,
                bytesPerRow: mat.step1(),
                space: colorSpace,
                bitmapInfo: bitmapInfo)
        } else {
            mat = Mat(rows: Int32(rows), cols: Int32(cols), type: CV_8UC4)
            if !hasAlphaChannel {
                bitmapInfo = CGImageAlphaInfo.noneSkipLast.rawValue | CGImageByteOrderInfo.orderDefault.rawValue
            } else {
                mat = mat.setTo(scalar: Scalar(0))
            }
            context = CGContext(
                data: mat.dataPointer(),
                width: cols,
                height: rows,
                bitsPerComponent: 8,
                bytesPerRow: mat.step1(),
                space: colorSpace,
                bitmapInfo: bitmapInfo)
        }

        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: cols, height: rows))
        return mat
    }

    func mat3() -> Mat {
        let src = mat()
        Imgproc.cvtColor(src: src, dst: src, code: .COLOR_RGBA2RGB)
        return src
    }

    func grayscaleMat() -> Mat {
        let src = mat()
        Imgproc.cvtColor(src: src, dst: src, code: .COLOR_BGRA2GRAY)
        return src
        // return mat(with: CvType.CV_8UC1)
    }

    private func mat(with type: Int32) -> Mat {
        guard let cgImage = cgImage, let colorSpace = cgImage.colorSpace else { fatalError() }

        let cols = cgImage.width
        let rows = cgImage.height
        var mat = Mat(rows: Int32(rows), cols: Int32(cols), type: type)

        let bitMapInfo = CGImageAlphaInfo.noneSkipLast.rawValue | CGImageByteOrderInfo.orderDefault.rawValue

        let contextRef = CGContext(data: mat.dataPointer(), // Pointer to data
                                   width: cols, height: rows, // Width 、Height of bitmap
                                   bitsPerComponent: 8, // Bits per component
                                   bytesPerRow: mat.step1(), // Bytes per row
                                   space: colorSpace, // Colorspace
                                   bitmapInfo: bitMapInfo) // Bitmap info flags

        contextRef?.draw(cgImage, in: CGRect(x: 0, y: 0, width: cols, height: rows))
        return mat
    }

    convenience init?(mat: Mat) {
        guard let data = Data(bytes: mat.dataPointer(), count: mat.elemSize() * mat.total()) as? CFData,
              let provider = CGDataProvider(data: data) else {
            return nil
        }

        let colorSpace: CGColorSpace
        if mat.elemSize() == 1 {
            colorSpace = CGColorSpaceCreateDeviceGray()
        } else {
            colorSpace = CGColorSpaceCreateDeviceRGB()
        }

        let alpha = mat.channels() == 4

        let bitMapInfo: CGBitmapInfo

        if alpha {
            bitMapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue | CGImageByteOrderInfo.orderDefault.rawValue)
        } else {
            bitMapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue | CGImageByteOrderInfo.orderDefault.rawValue)
        }

        guard let cgImage = CGImage(width: Int(mat.cols()),
                                    height: Int(mat.rows()),
                                    bitsPerComponent: 8 * mat.elemSize1(),
                                    bitsPerPixel: 8 * mat.elemSize(),
                                    bytesPerRow: mat.step1(),
                                    space: colorSpace,
                                    bitmapInfo: bitMapInfo,
                                    provider: provider,
                                    decode: nil,
                                    shouldInterpolate: false,
                                    intent: .defaultIntent) else {
            return nil
        }

        self.init(cgImage: cgImage)
    }

    var hasAlphaChannel: Bool {
        guard let alpha = cgImage?.alphaInfo else { return false }
        return alpha == .first || alpha == .last || alpha == .premultipliedFirst || alpha == .premultipliedLast
    }
}
