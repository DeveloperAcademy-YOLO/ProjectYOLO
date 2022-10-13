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
    
    private let indexes: UIPageControl = UIPageControl(frame: CGRect(x: 0, y: 500, width: 100, height: 20))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        self.splitViewController?.hide(.primary)
        setCustomNavBarButtons()
        setPaperTitle()
        setCollectionView()
        
        indexes.numberOfPages = 30
        indexes.currentPage = 0
        
        indexes.pageIndicatorTintColor = UIColor.systemGray
        indexes.currentPageIndicatorTintColor = UIColor.black
        
        indexes.center = self.view.center
        
        self.view.addSubview(indexes)
        
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.splitViewController?.hide(.primary)
    }
    
    func setCustomNavBarButtons() {
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
    
    func setPaperTitle() {
        let asd = UIView(frame: CGRect(x: 0, y: 0, width: 730, height: 50))
        asd.addSubview(titleLabel)
        asd.addSubview(timeLabel)
        asd.center.x = self.view.center.x
        view.addSubview(asd)
    }
    
    func move() {
        if let templateSelectVC = self.navigationController?.viewControllers.filter({ $0 is TemplateSelectViewController }).first {
            self.navigationController?.popToViewController(templateSelectVC, animated: true)
        }
    }
    
    func setCollectionView() {
        var cardsCollection: UICollectionView?
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 20, left: 20, bottom: 0, right: 0)
        layout.itemSize = CGSize(width: 300, height: 230)
        
        cardsCollection = UICollectionView(frame: CGRect(x: 0, y: 150, width: self.view.frame.width*0.87, height: self.view.frame.height-230), collectionViewLayout: layout)
//        let indexPath = IndexPath(item: indexes.currentPage, section: 0)
//        cardsCollection?.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        cardsCollection?.center.x = view.center.x
        
        cardsCollection?.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "MyCell")
        cardsCollection?.backgroundColor = .green
        
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
        return myCell
    }
}
extension WrittenPaperViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("User tapped on item \(indexPath.row)")
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
    }
}

extension WrittenPaperViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let width = scrollView.bounds.size.width
        // 좌표보정을 위해 절반의 너비를 더해줌
        let xxxx = scrollView.contentOffset.x + (width/2)
        
        let newPage = Int(xxxx / width)
        if indexes.currentPage != newPage {
            indexes.currentPage = newPage
        }
    }
}
