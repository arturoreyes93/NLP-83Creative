//
//  GradientView.swift
//  NLP
//
//  Created by Arturo Reyes on 8/25/18.
//  Copyright © 2018 Arturo Reyes. All rights reserved.
//

import UIKit

// Allow to change that class in storyboard - interface builder
@IBDesignable

class GradientView: UIView {
    
    override class var layerClass : AnyClass {
        get {
            return CAGradientLayer.self
        }
    }
    
    @IBInspectable var FirstColor: UIColor = UIColor.clear {
        didSet {
            updateView()
        }
        
    }
    
    @IBInspectable var SecondColor: UIColor = UIColor.clear {
        didSet {
            updateView()
        }
    }
    
    func updateView() {
        
        let layer = self.layer as! CAGradientLayer
        layer.colors = [FirstColor.cgColor, SecondColor.cgColor]
        
    }
    
}

import UIKit

class TransparentNavController: UINavigationController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationBar.shadowImage = UIImage()
        self.navigationBar.isTranslucent = true
        self.view.backgroundColor = .clear
        
    }
    
    
}
