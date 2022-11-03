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
//    var pageControl = FSPageControl()
    var images = [UIImage?]()
    var selectedIndex = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setView()
        setImagesOrder()
        setPagerView()
    }
    // 현재 창 닫기
    @objc func closeAction() {
        dismiss(animated: true)
    }
    // 뷰 설정하기
    func setView() {
        view.isOpaque = false
        view.backgroundColor = .clear
        view.addSubview(closeBtn)
        view.addSubview(pagerView)
//        view.addSubview(pageControl)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(closeAction))
        view.addGestureRecognizer(tapGesture)
    }
    // 현재 선택한 이미지에 맞춰서 이미지 순서 바꾸기
    func setImagesOrder() {
        let front = Array(images[selectedIndex..<images.count])
        let back = Array(images[0..<selectedIndex])
        images = front + back
    }
    // 페이저 설정하기
    func setPagerView() {
        pagerView.snp.makeConstraints({ make in
            make.width.equalTo(self.view.bounds.width * 0.75)
            make.height.equalTo(self.view.bounds.width * 0.75 * 0.75)
            make.leading.equalTo(self.view.snp.leading).offset(self.view.bounds.width * 0.1)
            make.trailing.equalTo(self.view.snp.trailing).offset(-(self.view.bounds.width * 0.1))
            make.centerX.equalTo(self.view)
            make.centerY.equalTo(self.view)
        })
//        pageControl.snp.makeConstraints({ make in
//            make.centerX.equalToSuperview()
//            make.top.equalTo(pagerView.snp.bottom).offset(30)
//        })
        if images.count != 1 {
            pagerView.isInfinite = true
        }
        pagerView.transformer = FSPagerViewTransformer(type: .overlap)
        pagerView.dataSource = self
        pagerView.delegate = self
        pagerView.register(FSPagerViewCell.self, forCellWithReuseIdentifier: "cell")
        
//        pageControl.currentPage = selectedIndex
//        pageControl.numberOfPages = images.count
//        pageControl.itemSpacing = 16
//        pageControl.interitemSpacing = 16
//        pageControl.setFillColor(.systemGray, for: .selected)
//        pageControl.setFillColor(.systemGray3, for: .normal)
    }
    // 페이지 개수
    func numberOfItems(in pagerView: FSPagerView) -> Int {
        return images.count
    }
    // 페이지마다 보여지는 셀
    func pagerView(_ pagerView: FSPagerView, cellForItemAt index: Int) -> FSPagerViewCell {
        let cell = pagerView.dequeueReusableCell(withReuseIdentifier: "cell", at: index)
        cell.imageView?.image = images[index]
        cell.imageView?.backgroundColor = .clear
        cell.imageView?.layer.cornerRadius = 50
        cell.imageView?.clipsToBounds = true
        return cell
    }
//    // 페이지 이동에 따라 컨트롤러도 바뀌기 (아래 점점점 나오는거)
//    func pagerViewWillEndDragging(_ pagerView: FSPagerView, targetIndex: Int) {
//        pageControl.currentPage = (selectedIndex+targetIndex)%images.count
//    }
//    func pagerViewDidEndScrollAnimation(_ pagerView: FSPagerView) {
//        pageControl.currentPage = (selectedIndex+pagerView.currentIndex)%images.count
//    }
    // 사진 클릭 안되도록 하기
    func pagerView(_ pagerView: FSPagerView, shouldHighlightItemAt index: Int) -> Bool {
        return false
    }
}
