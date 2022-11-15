//
//  PaperStorageCollectionHeader.swift
//  RollingPaper
//
//  Created by 김동락 on 2022/11/09.
//

import SnapKit
import UIKit

// 컬렉션 뷰에서 섹션의 제목을 보여주는 뷰
final class PaperStorageCollectionHeader: UICollectionReusableView {
    static let identifier = "CollectionHeader"
    
    private lazy var title: UILabel = {
        let title = UILabel()
        title.font = .preferredFont(forTextStyle: .title2)
        return title
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
        setConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // 헤더 제목 설정하기
    func setHeader(text: String) {
        title.text = text
    }
}

// 스냅킷 설정
extension PaperStorageCollectionHeader {
    private func configure() {
        addSubview(title)
    }
    
    private func setConstraints() {
        title.snp.makeConstraints({ make in
            make.top.equalToSuperview()
            make.leading.equalToSuperview().offset(PaperStorageLength.headerLeftMargin)
        })
    }
}
