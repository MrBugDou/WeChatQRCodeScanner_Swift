//
// ResultViewController.swift
//
// Copyright (c) 2024 DouDou
//
// Created by DouDou on 2022/6/15.
//

import SnapKit
import UIKit

class ResultViewController: UIViewController {
    var image: UIImage?

    convenience init(with image: UIImage?) {
        self.init()
        self.image = image
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let resultImageView: UIImageView = {
            let imageView = UIImageView(frame: view.bounds)
            imageView.contentMode = .scaleAspectFit
            imageView.contentScaleFactor = UIScreen.main.scale
            imageView.image = image
            return imageView
        }()
        view.addSubview(resultImageView)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        dismiss(animated: true, completion: nil)
    }
}
