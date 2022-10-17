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
        view.backgroundColor = .lightGray
        
        view.addSubview(someImageView)
        someImageView.backgroundColor = .white
        someImageView.layer.masksToBounds = true
        someImageView.layer.cornerRadius = 50
        someImageView.contentMode = .scaleAspectFill
        someImageView.image = backgroundImg
        someImageViewConstraints()
        
        view.addSubview(cancelButton)
        cancelButtonConstraints()
       // setNavigationBar()
        self.navigationController?.isNavigationBarHidden = true
    }
    
    lazy var someImageView: UIImageView = {
        let theImageView = UIImageView()
        theImageView.backgroundColor = .white
        theImageView.translatesAutoresizingMaskIntoConstraints = false
        theImageView.isUserInteractionEnabled = true
        return theImageView
    }()
    
    lazy var cancelButton: UIButton = {
        let button = UIButton()
        button.setTitle("취소", for: UIControl.State.normal)
        button.setTitleColor(UIColor.black, for: UIControl.State.normal)
        button.addTarget(self, action: #selector(cancelBtnPressed(_:)), for: .touchUpInside)
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
    
    private func cancelButtonConstraints() {
        cancelButton.snp.makeConstraints({ make in
            make.width.equalTo(40)
            make.height.equalTo(40)
            make.leading.equalTo(30)
            make.top.equalTo(self.view).offset(30)
        })
    }
    
    @objc func createBtnPressed() {
     print("게시하기 pressed")
    }

    @objc func cancelBtnPressed(_ sender: UISegmentedControl) {
        self.navigationController?.popViewController(animated: true)
        //self.dismiss(animated: true)
    }
}
