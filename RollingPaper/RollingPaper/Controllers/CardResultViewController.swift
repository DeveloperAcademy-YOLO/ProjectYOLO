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
    let image: UIImage
    
    init(resultImage: UIImage) {
        self.image = resultImage
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .lightGray
        
        view.addSubview(someImageView)
        someImageView.backgroundColor = .white
        someImageView.layer.masksToBounds = true
        someImageView.layer.cornerRadius = 50
        someImageView.contentMode = .scaleAspectFill
        someImageView.image = image
        someImageViewConstraints()
        
        self.navigationItem.leftBarButtonItem = self.leftButton
        self.navigationItem.rightBarButtonItem = self.rightButton

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    lazy var someImageView: UIImageView = {
        let theImageView = UIImageView()
        theImageView.backgroundColor = .white
        theImageView.translatesAutoresizingMaskIntoConstraints = false
        theImageView.isUserInteractionEnabled = true
        return theImageView
    }()
    
    lazy var leftButton: UIBarButtonItem = {
        let button = UIBarButtonItem(title: "leftBtn", style: .plain, target: self, action: #selector(cancelBtnPressed(_:)))
           button.tag = 1
           
           return button
       }()
    
    lazy var rightButton: UIBarButtonItem = {
            let button = UIBarButtonItem(title: "RightBtn", style: .plain, target: self, action: #selector(createBtnPressed(_:)))
            button.tag = 2
            
            return button
        }()
    
    func someImageViewConstraints() {
        someImageView.snp.makeConstraints({ make in
            make.width.equalTo(813)
            make.height.equalTo(515)
            make.centerX.equalTo(self.view)
            make.centerY.equalTo(self.view)
        })
    }

    @objc func createBtnPressed(_ sender: UISegmentedControl) {
     print("게시하기 pressed")
    }

    @objc func cancelBtnPressed(_ sender: UISegmentedControl) {
        self.navigationController?.popViewController(animated: false)
    }
    
}
