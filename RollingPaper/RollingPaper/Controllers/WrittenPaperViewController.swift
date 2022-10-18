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
        titleLabel.frame = CGRect(x: 0, y: 0, width: 400, height: 36)
        titleLabel.textAlignment = .left
        titleLabel.text = "재현이의 졸업을 축하하며"
        titleLabel.font = UIFont.preferredFont(for: UIFont.TextStyle.title3, weight: UIFont.Weight.bold)
        titleLabel.numberOfLines = 1
        return titleLabel
    }()
    
    private var timeLabel: BasePaddingLabel = {
        let timeLabel = BasePaddingLabel()
        timeLabel.frame = CGRect(x: -100, y: 0, width: 120, height: 36)
        timeLabel.textAlignment = .center
        
        let imageAttachment = NSTextAttachment()
        imageAttachment.image = UIImage(systemName: "timer")?.withTintColor(.white)
        imageAttachment.bounds = CGRect(x: 0, y: -5, width: 20, height: 20)
        let attachmentString = NSAttributedString(attachment: imageAttachment)
        let completeText = NSMutableAttributedString(string: "")
        completeText.append(attachmentString)
        let textAfterIcon = NSAttributedString(string: "  " + "99:99")
        completeText.append(textAfterIcon)
        timeLabel.attributedText = completeText
        
        
        timeLabel.font = UIFont.preferredFont(for: UIFont.TextStyle.body, weight: UIFont.Weight.bold)
        timeLabel.textColor = .white
        timeLabel.layer.borderColor = UIColor.systemGray3.cgColor
        timeLabel.layer.borderWidth = 1
        timeLabel.layer.cornerRadius = 18
        timeLabel.layer.backgroundColor = UIColor.gray.cgColor
        
        return timeLabel
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        self.splitViewController?.hide(.primary)
        self.navigationController?.navigationBar.tintColor = .systemGray
        
//        timeLabel.translatesAutoresizingMaskIntoConstraints = false
//        titleLabel.translatesAutoresizingMaskIntoConstraints = false
//
//        let asd = UIView()
//        asd.addSubview(timeLabel)
//        asd.addSubview(titleLabel)
//        asd.center.x = self.view.center.x
//        asd.frame = self.navigationController!.navigationBar.frame
//        print(self.navigationController!.navigationBar.frame)
//        print(asd.frame)
//
//        timeLabel.translatesAutoresizingMaskIntoConstraints = false
//        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        let stackView   = UIStackView()
        stackView.axis  = NSLayoutConstraint.Axis.horizontal
        stackView.distribution  = UIStackView.Distribution.equalSpacing
        stackView.alignment = UIStackView.Alignment.center
        stackView.spacing   = 30.0
////        stackView.frame =
////        stackView.frame.width = timeLabel.frame.width + titleLabel.frame.width
////
        stackView.addArrangedSubview(timeLabel)
//        stackView.addArrangedSubview(titleLabel)
//        stackView.translatesAutoresizingMaskIntoConstraints = false
//
//        stackView.center.x = self.view.center.x
//        print(stackView.frame)
//
//        print(self.navigationController!.navigationBar.center.x)
//        print(stackView.center.x)
////        navigationController?.navigationBar.addSubview(stackView)
//        navigationItem.titleView = stackView
//        print(stackView.frame.width)
////        navigationController?.navigationBar.prefersLargeTitles = false
//
//
//        let sss = UIL
        
//        self.navigationItem.titleView = timeLabel
//        setPaperTitle()
        navigationItem.titleView = stackView
        setCollectionView()
        setCustomNavBarButtons()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.splitViewController?.hide(.primary)
    }
    
    func setCustomNavBarButtons() {
        let customBackBtnImage = UIImage(systemName: "chevron.backward")
        let customBackBtn = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 23))
        customBackBtn.setTitle("보관함", for: .normal)
        customBackBtn.setTitleColor(.systemGray, for: .normal)
        customBackBtn.setImage(customBackBtnImage, for: .normal)
        customBackBtn.addAction(UIAction(handler: {_ in self.move()}), for: .touchUpInside)
        customBackBtn.addLeftPadding(5)
        
        let paperLinkBtnImage = UIImage(systemName: "square.and.arrow.up")!.resized(to: CGSize(width: 30, height: 30))
        paperLinkBtnImage.withTintColor(.systemBlue)
        let paperLinkBtn = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        paperLinkBtn.tintColor = .systemBlue
        paperLinkBtn.setImage(paperLinkBtnImage, for: .normal)
        
        let createCardBtnImage = UIImage(systemName: "plus.rectangle.fill")!.resized(to: CGSize(width: 40, height: 30))
        let createCardBtn = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        createCardBtn.tintColor = .systemGray3
        createCardBtn.setImage(createCardBtnImage, for: .normal)
        
        let managePaperBtnImage = UIImage(systemName: "ellipsis.circle")!.resized(to: CGSize(width: 30, height: 30))
        let managePaperBtn = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        managePaperBtn.tintColor = .systemGray3
        managePaperBtn.setImage(managePaperBtnImage, for: .normal)
        
        let firstBarButton = UIBarButtonItem(customView: customBackBtn)
        let secondBarButton = UIBarButtonItem(customView: paperLinkBtn)
        let thirdBarButton = UIBarButtonItem(customView: createCardBtn)
        let fourthBarButton = UIBarButtonItem(customView: managePaperBtn)
        
        
        navigationItem.rightBarButtonItems = [thirdBarButton, secondBarButton, fourthBarButton]
        navigationItem.leftBarButtonItem = firstBarButton
    }
    
    @objc private func sdd() {
        
    }
    
    func setPaperTitle() {
        let asd = UIView()
        asd.addSubview(timeLabel)
        asd.addSubview(titleLabel)
        asd.center.x = self.view.center.x
        self.navigationItem.titleView = asd
    }
    
    func move() {
        if let templateSelectVC = self.navigationController?.viewControllers.filter({ $0 is TemplateSelectViewController }).first {
            self.navigationController?.popToViewController(templateSelectVC, animated: true)
        }
    }
    
    func setCollectionView() {
        var cardsCollection: UICollectionView?
        
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 5, left: 20, bottom: 20, right: 20 )
        layout.itemSize = CGSize(width: (self.view.frame.width-80)/3, height: ((self.view.frame.width-120)/3)*0.75)
        layout.minimumInteritemSpacing = 20
        layout.minimumLineSpacing = 20
        
        cardsCollection = UICollectionView(frame: CGRect(x: 0, y: 30, width: self.view.frame.width, height: self.view.frame.height), collectionViewLayout: layout)
        cardsCollection?.center.x = view.center.x
        cardsCollection?.showsVerticalScrollIndicator = false
        cardsCollection?.layer.cornerRadius = 12
        cardsCollection?.layer.masksToBounds = true
        cardsCollection?.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "MyCell")
        cardsCollection?.dataSource = self
        cardsCollection?.delegate = self
        
        cardsCollection?.reloadData()
        
        view.addSubview(cardsCollection ?? UICollectionView())
    }
    
}

extension UIButton {
    func addLeftPadding(_ padding: CGFloat) {
        titleEdgeInsets = UIEdgeInsets(top: 0.0, left: padding, bottom: 0.0, right: -padding)
        contentEdgeInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: padding)
    }
}

extension WrittenPaperViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 200 // How many cells to display
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let myCell = collectionView.dequeueReusableCell(withReuseIdentifier: "MyCell", for: indexPath)
        myCell.backgroundColor = UIColor.blue
        myCell.layer.cornerRadius = 12
        myCell.layer.masksToBounds = true
        return myCell
    }
}
extension WrittenPaperViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("User tapped on item \(indexPath.row)")
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
//        collectionView.reloadData()
    }
}


extension UIImage {
    func resized(to size: CGSize) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image{ _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
