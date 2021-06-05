//
//  CaptureImageDetailViewController.swift
//  CAMRA-KIT
//
//  Created by fihade on 2021/5/19.
//

import UIKit

class CaptureImageDetailViewController: UIViewController {
    
    
    var sourceImage: UIImage?
    
    private var imageView: UIImageView!
    private var hisogram: HistogramView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        view.backgroundColor = .black
        
        imageView = UIImageView(frame: .zero)
        imageView.image = sourceImage
    
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalTo: view.widthAnchor),
            imageView.heightAnchor.constraint(equalToConstant: 300),
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.topAnchor.constraint(equalTo: view.topAnchor,constant: 10)
        ])
        
        if let levels = VImageWrapper.getHistogram(sourceImage?.cgImage) {
            displayHistogram(with: levels)
        }

    }
    

    private func displayHistogram(with histogramLevels: HistogramLevels) {
        hisogram = HistogramView(histogram: histogramLevels)
        hisogram.translatesAutoresizingMaskIntoConstraints = false
        hisogram.backgroundColor = UIColor(white: 0, alpha: 0.8)
        hisogram.layer.cornerRadius = 10
        hisogram.clipsToBounds = true
        
        view.addSubview(hisogram)
        
        NSLayoutConstraint.activate([
            hisogram.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            hisogram.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
//            hisogram.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 40),
            hisogram.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
            hisogram.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
            hisogram.heightAnchor.constraint(equalToConstant: 140)
        ])
        
    }
}
