//
//  MagnifiedCardViewController.swift
//  RollingPaper
//
//  Created by SeungHwanKim on 2022/10/26.
//

import Foundation
import UIKit
import SnapKit

class MagnifiedCardViewController: UIViewController {
    private var closeBtn: UIButton = UIButton()
    private var scrollView = UIScrollView()
    private var images = [UIImage?]()
    private var selectedIndex = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setView()
        setPagerView()
    }
    // 현재 창 닫기
    @objc func closeAction() {
        dismiss(animated: true)
    }
    // 뷰 설정하기
    private func setView() {
        view.isOpaque = false
        view.backgroundColor = .clear
        view.addSubview(closeBtn)
        view.addSubview(scrollView)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(closeAction))
        view.addGestureRecognizer(tapGesture)
    }
    // 페이저 설정하기
    private func setPagerView() {
        let contentWidth = view.bounds.width * 0.75
        let contentHeight = view.bounds.width * 0.75 * 0.75
        
        scrollView.snp.makeConstraints({ make in
            make.width.equalTo(contentWidth)
            make.height.equalTo(contentHeight)
            make.centerX.equalTo(view)
            make.centerY.equalTo(view)
        })
        scrollView.contentSize = CGSize(width: contentWidth * CGFloat(images.count), height: contentHeight)
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.isScrollEnabled = true
        scrollView.isPagingEnabled = true
        scrollView.bounces = false
        scrollView.contentOffset = CGPoint(x: contentWidth*CGFloat(selectedIndex), y: 0)
        
        for (index, image) in images.enumerated() {
            let imageView = UIImageView(image: image)
            scrollView.addSubview(imageView)
            imageView.snp.makeConstraints({ make in
                make.centerY.equalToSuperview()
                make.centerX.equalToSuperview().offset(contentWidth*CGFloat(index))
                make.width.equalTo(contentWidth)
                make.height.equalTo(contentHeight)
            })
        }
    }
}
