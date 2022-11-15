//
//  AddCardViewController.swift
//  RollingPaper
//
//  Created by SeungHwanKim on 2022/11/13.
//

import Foundation
import SnapKit
import UIKit

class AddCardViewController: UIViewController {
    private let viewModel: WrittenPaperViewModel = WrittenPaperViewModel()
    private let deviceWidth = UIScreen.main.bounds.size.width
    private let deviceHeight = UIScreen.main.bounds.size.height
    private let plusImg: UIImageView = {
        let imageView = UIImageView()
        let image = UIImage(systemName: "plus")
        
        imageView.image = image
        imageView.tintColor = UIColor(red: 173, green: 173, blue: 173)
        return imageView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewConstraints()
        view.backgroundColor = UIColor(red: 240, green: 240, blue: 240)
        view.addSubview(plusImg)
        setPlusLocation()
    }
}

extension AddCardViewController {
    private func viewConstraints() {
        self.view.snp.makeConstraints { make in
            make.width.equalTo((deviceWidth-80)/3)
            make.height.equalTo(((deviceWidth-120)/3)*0.75)
        }
    }
    
    private func setPlusLocation() {
        plusImg.snp.makeConstraints { make in
            make.center.equalTo(self.view)
            make.width.equalTo(40)
            make.height.equalTo(40)
        }
    }
}
