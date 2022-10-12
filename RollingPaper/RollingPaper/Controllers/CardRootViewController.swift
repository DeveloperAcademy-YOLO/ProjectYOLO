//
//  CardRootViewController.swift
//  RollingPaper
//
//  Created by Yosep on 2022/10/12.
//

import UIKit
import SnapKit

class CardRootViewController: UIViewController {
    
    let items = ["배경 고르기", "꾸미기"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
    }
    fileprivate func setupViews() {
        view.backgroundColor = .customLightGray
        view.addSubview(segmentedControl)
        segmentedControlConstraints()
    }
    
    lazy var segmentedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = 0
        control.layer.cornerRadius = 9
        control.layer.masksToBounds = true
        control.selectedSegmentTintColor = .darkGray
        control.setTitleTextAttributes([.foregroundColor: UIColor.darkGray], for: .normal)
        control.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        return control
    }()
    
    func segmentedControlConstraints() {
        segmentedControl.snp.makeConstraints({ make in
            make.width.equalTo(200)
            make.height.equalTo(30)
            make.centerX.equalTo(self.view)
            make.top.equalTo(self.view).offset(50)
        })
    }
}
