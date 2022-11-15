//
//  StickerCollectionViewCell.swift
//  RollingPaper
//
//  Created by Yosep on 2022/11/11.
//

import SnapKit
import UIKit

class StickerCollectionViewCell: UICollectionViewCell {
    
    static let identifier = "StickerCollectionViewCell"
    // 셀에 이미지 뷰 객체를 넣어주기 위해서 생성
    let myImage: UIImageView = {
        let img = UIImageView()
        // 자동으로 위치 정렬 금지
        img.translatesAutoresizingMaskIntoConstraints = false
        return img
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupView() {
        // 셀에 위에서 만든 이미지 뷰 객체를 넣어준다.
        contentView.addSubview(myImage)
        myImageConstraints()
    }
    
    func myImageConstraints() {
        myImage.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
}
