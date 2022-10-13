//
//  WrittenPaperViewController.swift
//  RollingPaper
//
//  Created by SeungHwanKim on 2022/10/12.
//

import Foundation
import UIKit
import SnapKit

class WrittenPaperViewController: UIViewController {
    private var titleLabel: BasePaddingLabel = {
        let titleLabel = BasePaddingLabel()
        titleLabel.frame = CGRect(x: 0, y: 80, width: 600, height: 60)
        titleLabel.textAlignment = .center
        titleLabel.text = "재현이의 졸업을 축하하며"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 20)
        titleLabel.numberOfLines = 1
        titleLabel.layer.borderColor = UIColor.black.cgColor
        titleLabel.layer.borderWidth = 1
        titleLabel.layer.cornerRadius = 30
        titleLabel.layer.maskedCorners = CACornerMask(arrayLiteral: .layerMinXMaxYCorner, .layerMinXMinYCorner)
        return titleLabel
    }()
    
    private var timeLabel: BasePaddingLabel = {
        let timeLabel = BasePaddingLabel()
        timeLabel.frame = CGRect(x: 600, y: 80, width: 130, height: 60)
        timeLabel.textAlignment = .center
        
        let imageAttachment = NSTextAttachment()
        imageAttachment.image = UIImage(systemName: "timer")?.withTintColor(.white)
        imageAttachment.bounds = CGRect(x: 500, y: -3.0, width: 20, height: 20)
        let attachmentString = NSAttributedString(attachment: imageAttachment)
        let completeText = NSMutableAttributedString(string: "")
        completeText.append(attachmentString)
        let textAfterIcon = NSAttributedString(string: " " + "99:99")
        completeText.append(textAfterIcon)
        timeLabel.attributedText = completeText
        
        timeLabel.font = UIFont.boldSystemFont(ofSize: 20)
        timeLabel.textColor = .white
        timeLabel.layer.borderColor = UIColor.black.cgColor
        timeLabel.layer.borderWidth = 1
        timeLabel.layer.cornerRadius = 30
        timeLabel.layer.maskedCorners = CACornerMask(arrayLiteral: .layerMaxXMaxYCorner, .layerMaxXMinYCorner)
        timeLabel.layer.backgroundColor = UIColor.black.cgColor
        return timeLabel
    }()
    
    private var asd = UIView(frame: CGRect(x: 0, y: 0, width: 730, height: 50))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        self.splitViewController?.hide(.primary)
        setCustomNavBarButtons()
        asd.addSubview(titleLabel)
        asd.addSubview(timeLabel)
        asd.center.x = self.view.center.x
        view.addSubview(asd)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        hideSideBar()
    }
    
    func setCustomNavBarButtons() {
        let img = UIImage(named: "square.and.arrow.up")?.withRenderingMode(.alwaysOriginal)
        
        let customBackBtnImage = UIImage(systemName: "chevron.backward")
        let customBackBtn = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 23))
        customBackBtn.setTitle("보관함", for: .normal)
        customBackBtn.setTitleColor(.systemBlue, for: .normal)
        customBackBtn.setImage(customBackBtnImage, for: .normal)
        customBackBtn.addAction(UIAction(handler: {_ in self.move()}), for: .touchUpInside)
        customBackBtn.addLeftPadding(5)
        
        let paperLinkBtnImage = UIImage(systemName: "square.and.arrow.up")
        let paperLinkBtn = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 40))
        paperLinkBtn.tintColor = .black
        paperLinkBtn.setImage(paperLinkBtnImage, for: .normal)
        
        let createCardBtnImage = UIImage(systemName: "plus.rectangle.fill")!
        let createCardBtn = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 40))
        createCardBtn.tintColor = .black
        createCardBtn.setImage(createCardBtnImage, for: .normal)
        
        let firstBarButton = UIBarButtonItem(customView: customBackBtn)
        let secondBarButton = UIBarButtonItem(customView: paperLinkBtn)
        let thirdBarButton = UIBarButtonItem(customView: createCardBtn)
        
        navigationItem.rightBarButtonItems = [thirdBarButton, secondBarButton]
        navigationItem.leftBarButtonItem = firstBarButton
    }
    
    func move() {
        if let templateSelectVC = self.navigationController?.viewControllers.filter({ $0 is TemplateSelectViewController }).first {
            self.navigationController?.popToViewController(templateSelectVC, animated: true)
        }
        
    }
    
}

extension UIButton {
    func addLeftPadding(_ padding: CGFloat) {
        titleEdgeInsets = UIEdgeInsets(top: 0.0, left: padding, bottom: 0.0, right: -padding)
        contentEdgeInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: padding)
    }
}
