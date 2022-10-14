//
//  CardResultViewController.swift
//  RollingPaper
//
//  Created by Yosep on 2022/10/14.
//

import UIKit
import SnapKit
import Combine

final class CardResultViewController: UIViewController {
 
    var backgroundImg = UIImage(named: "Rectangle")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .blue
        
        view.addSubview(someImageView)
        someImageView.backgroundColor = .white
        someImageView.layer.masksToBounds = true
        someImageView.layer.cornerRadius = 50
        someImageView.contentMode = .scaleAspectFill
        someImageView.image = backgroundImg
        someImageViewConstraints()
    }
    
    lazy var someImageView: UIImageView = {
        let theImageView = UIImageView()
        theImageView.backgroundColor = .white
        theImageView.translatesAutoresizingMaskIntoConstraints = false
        theImageView.isUserInteractionEnabled = true
        return theImageView
    }()
    
    func someImageViewConstraints() {
        someImageView.snp.makeConstraints({ make in
            make.width.equalTo(813)
            make.height.equalTo(515)
            make.centerX.equalTo(self.view)
            make.centerY.equalTo(self.view)
        })
    }
}
