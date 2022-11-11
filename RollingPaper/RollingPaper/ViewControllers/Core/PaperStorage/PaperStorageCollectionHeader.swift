//
//  PaperStorageCollectionHeader.swift
//  RollingPaper
//
//  Created by 김동락 on 2022/11/09.
//

import UIKit
import SnapKit

// 컬렉션 뷰에서 섹션의 제목을 보여주는 뷰
class PaperStorageCollectionHeader: UICollectionReusableView {
    static let identifier = "CollectionHeader"
    private let title = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configure() {
        addSubview(title)
        
        title.font = .preferredFont(forTextStyle: .title2)
        title.snp.makeConstraints({ make in
            make.top.equalToSuperview()
            make.leading.equalToSuperview().offset(PaperStorageLength.headerLeftMargin)
        })
    }
    
    func setHeader(text: String) {
        title.text = text
    }
}
