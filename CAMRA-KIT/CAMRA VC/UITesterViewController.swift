//
//  UITesterViewController.swift
//  CAMRA-KIT
//
//  Created by 梁斌 on 2021/5/10.
//

import UIKit

class UITesterViewController: UIViewController {
    
    var bigImageView : UIImageView!
    var bigBackView: UIView!
    
    @IBOutlet weak var smallImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        smallImageView.isUserInteractionEnabled = true
        smallImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapBig)))
        
    }
    
    @objc func tapBig() {
        
        
        
        guard let image = smallImageView.image else {
            return
        }
        
        smallImageView.image = nil
        
        
        
        bigBackView = UIView(frame: view.bounds)
        bigBackView.backgroundColor = .black
        bigBackView.translatesAutoresizingMaskIntoConstraints = false
        
        
        
        view.addSubview(bigBackView)
        
        UIView.animate(withDuration: 1, animations: {
            self.bigBackView.layer.contents = image.cgImage
            self.bigBackView.layer.contentsGravity = .resizeAspect
        })

    }
    
    
    @objc func tapSmall() {
        UIView.animate(withDuration: 1, animations: {
            self.bigImageView.bounds = self.smallImageView.bounds
        })
        bigImageView.removeFromSuperview()
        bigBackView.removeFromSuperview()
    }

}


