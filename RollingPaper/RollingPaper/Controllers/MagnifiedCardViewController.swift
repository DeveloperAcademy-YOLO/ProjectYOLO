//
//  MagnifiedCardViewController.swift
//  RollingPaper
//
//  Created by SeungHwanKim on 2022/10/26.
//

import Foundation
import UIKit
import SnapKit
import FSPagerView

class MagnifiedCardViewController: UIViewController, FSPagerViewDataSource, FSPagerViewDelegate {
    var closeBtn: UIButton = UIButton()
    var pagerView = FSPagerView()
    var pageControl = FSPageControl()
    var images = [UIImage?]()
    var selectedIndex = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.isOpaque = false
        view.backgroundColor = .clear
        view.addSubview(closeBtn)
        view.addSubview(pagerView)
        view.addSubview(pageControl)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(closeAction))
        view.addGestureRecognizer(tapGesture)
        setImagesOrder()
        setPagerView()
    }
    
    @objc func closeAction() {
        dismiss(animated: true)
    }
    
    func setImagesOrder() {
        let front = Array(images[selectedIndex..<images.count])
        let back = Array(images[0..<selectedIndex])
        images = front + back
    }
    
    func setPagerView() {
        // Create a pager view
        pagerView.snp.makeConstraints({ make in
            make.width.equalTo(self.view.bounds.width * 0.75)
            make.height.equalTo(self.view.bounds.width * 0.75 * 0.75)
            make.leading.equalTo(self.view.snp.leading).offset(self.view.bounds.width * 0.1)
            make.trailing.equalTo(self.view.snp.trailing).offset(-(self.view.bounds.width * 0.1))
            make.centerX.equalTo(self.view)
            make.centerY.equalTo(self.view)
        })
        pageControl.snp.makeConstraints({ make in
            make.centerX.equalToSuperview()
            make.top.equalTo(pagerView.snp.bottom).offset(30)
        })
        pagerView.isInfinite = true
        pagerView.transformer = FSPagerViewTransformer(type: .overlap)
        pagerView.dataSource = self
        pagerView.delegate = self
        pagerView.register(FSPagerViewCell.self, forCellWithReuseIdentifier: "cell")
        
        pageControl.currentPage = selectedIndex
        pageControl.numberOfPages = images.count
        pageControl.itemSpacing = 16
        pageControl.interitemSpacing = 16
        pageControl.setFillColor(.systemGray, for: .selected)
        pageControl.setFillColor(.systemGray3, for: .normal)
    }
    
    func numberOfItems(in pagerView: FSPagerView) -> Int {
        return images.count
    }
    
    func pagerView(_ pagerView: FSPagerView, cellForItemAt index: Int) -> FSPagerViewCell {
        let cell = pagerView.dequeueReusableCell(withReuseIdentifier: "cell", at: index)
        cell.imageView?.image = images[index]
        cell.imageView?.backgroundColor = .clear
        cell.imageView?.layer.cornerRadius = 50
        cell.imageView?.clipsToBounds = true
        return cell
    }
    
    func pagerViewWillEndDragging(_ pagerView: FSPagerView, targetIndex: Int) {
        pageControl.currentPage = (selectedIndex+targetIndex)%images.count
    }
    
    func pagerViewDidEndScrollAnimation(_ pagerView: FSPagerView) {
        pageControl.currentPage = (selectedIndex+pagerView.currentIndex)%images.count
    }
    
    func pagerView(_ pagerView: FSPagerView, shouldHighlightItemAt index: Int) -> Bool {
        return false
    }
}
