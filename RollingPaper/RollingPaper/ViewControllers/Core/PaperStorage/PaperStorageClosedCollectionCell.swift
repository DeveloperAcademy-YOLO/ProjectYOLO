//
//  PaperStorageClosedCollectionCell.swift
//  RollingPaper
//
//  Created by 김동락 on 2022/11/09.
//

import UIKit
import SnapKit

// 컬렉션 뷰에 들어가는 셀들을 보여주는 뷰 (종료된거)
class PaperStorageClosedCollectionCell: UICollectionViewCell {
    static let identifier = "ClosedCollectionCell"
    private let cell = UIView()
    private let preview = UIImageView()
    private let previewOverlay = UIView()
    private let label = UIStackView()
    private let title = UILabel()
    private let date = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configure() {
        addSubview(cell)
        cell.addSubview(preview)
        cell.addSubview(label)
        preview.addSubview(previewOverlay)
        label.addArrangedSubview(title)
        label.addArrangedSubview(date)
        
        cell.snp.makeConstraints({ make in
            make.edges.equalToSuperview()
        })
        
        preview.layer.masksToBounds = true
        preview.layer.cornerRadius = PaperStorageLength.paperThumbnailCornerRadius
        preview.contentMode = .scaleAspectFill
        preview.snp.makeConstraints({ make in
            make.top.equalToSuperview()
            make.leading.equalToSuperview()
            make.width.equalTo(PaperStorageLength.closedPaperThumbnailWidth)
            make.height.equalTo(PaperStorageLength.closedPaperThumbnailHeight)
        })
        
        previewOverlay.backgroundColor = UIColor.black.withAlphaComponent(0.25)
        previewOverlay.snp.makeConstraints({ make in
            make.edges.equalToSuperview()
        })
        
        label.axis = .vertical
        label.spacing = PaperStorageLength.labelSpacing
        label.snp.makeConstraints({ make in
            make.centerX.equalTo(preview)
            make.centerY.equalTo(preview)
        })
        
        title.font = .preferredFont(for: .largeTitle, weight: .semibold)
        title.textColor = UIColor.white
        title.textAlignment = .center
        
        date.font = .preferredFont(for: .subheadline, weight: .bold)
        date.textColor = UIColor.white
        date.textAlignment = .center
        
    }
    
    // 날짜를 2022.10.13 같은 형식으로 바꾸기
    private func changeDateFormat(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "y.M.d"
        return dateFormatter.string(from: date)
    }
    
    func setCell(paper: PaperPreviewModel?, thumbnail: UIImage?) {
        if let paper = paper {
            date.text = changeDateFormat(date: paper.endTime)
            title.text = paper.title
            preview.image = thumbnail
            preview.snp.updateConstraints({ make in
                make.width.equalTo(PaperStorageLength.closedPaperThumbnailWidth)
                make.height.equalTo(PaperStorageLength.closedPaperThumbnailHeight)
            })
            isHidden = false
        } else {
            isHidden = true
        }
    }
}
