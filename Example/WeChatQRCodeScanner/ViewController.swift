//
//  ViewController.swift
//  WeChatQRCodeScanner
//
//  Created by DouDou on 2022/6/10.
//

import UIKit
import Photos
import WeChatQRCodeScanner_Swift

class ViewController: UIViewController {

    weak var containerLayer: CALayer!

    weak var scannerView: CodeScannerView!
        
    var reuseMarkLayers: [CAShapeLayer] = []
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        do {
            scannerView.delegate = self
            containerLayer.frame = scannerView.layer.bounds
            try scannerView.startScanner()
        } catch {
            print("startScanner error: \(error)")
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        scannerView.delegate = nil
        scannerView.stopScanner()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
//        guard let image = R.image.img_6673PNG() else { return }
//        let ret = CodeImageScanner.shared.scan(with: image)
//        print("ret = \(ret)")
//        let ret1 = DDBarCodeImageScanner().scanner(for: image)
//        print("ret1 = \(ret1)")
//
//        guard let image1 = R.image.qrcodes() else { return }
//        let ret2 = CodeImageScanner.shared.scan(with: image1)
//        print("ret1 = \(ret2)")
        
        let scannerView = CodeScannerView(frame: view.bounds)
        scannerView.delegate = self
        view.addSubview(scannerView)
        self.scannerView = scannerView
        
        drawBottomItems()
        
        let containerLayer = CALayer()
        containerLayer.frame = scannerView.layer.bounds
        containerLayer.backgroundColor = UIColor.clear.cgColor
        scannerView.layer.addSublayer(containerLayer)
        self.containerLayer = containerLayer
        
    }

    func drawBottomItems() {

        let bottomItemsView = UIView(frame: CGRect(x: 0.0, y: self.view.frame.maxY - 100, width: self.view.frame.size.width, height: 100))
        bottomItemsView.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.6)
        scannerView.addSubview(bottomItemsView)

        let  btnFlash = UIButton(type: .custom)
        btnFlash.setImage(R.image.qrCodeLightOpen(), for: .normal)
        btnFlash.addTarget(self, action: #selector(openOrCloseFlash(_:)), for: .touchUpInside)
        btnFlash.frame = .init(x: (bottomItemsView.center.x*0.5 - 50), y: 10, width: 100, height: 80)
        bottomItemsView.addSubview(btnFlash)

        let btnPhoto = UIButton(type: .custom)
        btnPhoto.addTarget(self, action: #selector(openPhotoAlbum), for: .touchUpInside)
        btnPhoto.frame = .init(x: (bottomItemsView.center.x*1.5 - 50), y: 10, width: 100, height: 80)
        btnPhoto.setImage(R.image.qrCodeAlbum(), for: .normal)
        bottomItemsView.addSubview(btnPhoto)
    }
    
    // 开关闪光灯
    @objc func openOrCloseFlash(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        scannerView.changeTorchMode(on: sender.isSelected)
        if sender.isSelected {
            sender.setImage(R.image.qrCodeLightClose(), for: .normal)
        } else {
            sender.setImage(R.image.qrCodeLightOpen(), for: .normal)
        }
    }
    
    @objc open func openPhotoAlbum() {
        Permissions.authorizePhotoWith { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = UIImagePickerController.SourceType.photoLibrary
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true, completion: nil)
        }
    }
    
}

// MARK: - 图片选择代理方法
extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // MARK: 相册选择图片识别二维码 （条形码没有找到系统方法）
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true, completion: nil)
        let editedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage
        let originalImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
        guard let image = editedImage ?? originalImage else {
            return
        }
//        let arrayResult = CodeImageScanner.shared.scan(with: image)
//        let arrayResult = DDBarCodeImageScanner().scanner(for: image)
//        let format = UIGraphicsImageRendererFormat()
//        format.scale = 1
//        let renderer = UIGraphicsImageRenderer(size: image.size, format: format)
//        let newImg = renderer.image { rendererContext in
//            image.draw(at: .zero)
//            for item in arrayResult {
//                let path = UIBezierPath(rect: item.rectOfImage)
//                path.lineWidth = 5
//                if item.content.isEmpty {
//                    UIColor.yellow.setStroke()
//                } else {
//                    UIColor.red.setStroke()
//                }
//                path.stroke()
//            }
//        }
//        print("arrayResult = \(arrayResult)")
    }
    
}

extension ViewController: CodeScannerViewDelegate {
    
    private func clearMarkLayers() {
        guard let sublayers = containerLayer.sublayers as? [CAShapeLayer], !sublayers.isEmpty else { return }
        reuseMarkLayers.append(contentsOf: sublayers)
        sublayers.forEach { layer in
            layer.removeFromSuperlayer()
        }
    }

    
    func scannerView(_ view: CodeScannerView, scanComplete result: [CodeScannerResult], elapsedTime: TimeInterval) -> Bool {
        
        clearMarkLayers()
        
        if result.isEmpty {
            return false
        }
        
        drawCorner(result: result)
        
        return false
    }
    
    func drawCorner(result: [CodeScannerResult]) {
        for element in result {
            var markLayer: CAShapeLayer
            if !reuseMarkLayers.isEmpty {
                markLayer = reuseMarkLayers.last!
                reuseMarkLayers.removeLast()
            } else {
                markLayer = .init()
                markLayer.fillColor   = UIColor.clear.cgColor
                markLayer.strokeColor = UIColor.green.cgColor
                markLayer.fillRule    = .evenOdd
                markLayer.lineWidth   = 2
            }
            
            let path = UIBezierPath(rect: element.rectOfView)
            markLayer.path = path.cgPath
            containerLayer.addSublayer(markLayer)
        }
    }
    
}
