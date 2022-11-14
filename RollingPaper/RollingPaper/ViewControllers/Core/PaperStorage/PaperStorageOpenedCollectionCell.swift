//
//  PaperStorageOpenedCell.swift
//  RollingPaper
//
//  Created by 김동락 on 2022/11/09.
//

import UIKit
import SnapKit
import Combine

// 컬렉션 뷰에 들어가는 셀들을 보여주는 뷰 (진행중인거)
class PaperStorageOpenedCollectionCell: UICollectionViewCell {
    static let identifier = "OpenedCollectionCell"
    private var cancellables = Set<AnyCancellable>()
    private let cell = UIView()
    private let preview = UIImageView()
    private let previewOverlay = UIView()
    private let timer = TimerView()
    private let title = UILabel()
    
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
        cell.addSubview(timer)
        cell.addSubview(title)
        preview.addSubview(previewOverlay)
        
        cell.snp.makeConstraints({ make in
            make.edges.equalToSuperview()
        })
        
        preview.layer.masksToBounds = true
        preview.layer.cornerRadius = PaperStorageLength.paperThumbnailCornerRadius
        preview.contentMode = .scaleAspectFill
        preview.snp.makeConstraints({ make in
            make.top.equalToSuperview()
            make.leading.equalToSuperview()
            make.width.equalTo(PaperStorageLength.openedPaperThumbnailWidth)
            make.height.equalTo(PaperStorageLength.openedPaperThumbnailHeight)
        })
        
        previewOverlay.backgroundColor = UIColor.black.withAlphaComponent(0.25)
        previewOverlay.snp.makeConstraints({ make in
            make.edges.equalToSuperview()
        })
        
        title.font = .preferredFont(for: .title1, weight: .semibold)
        title.textColor = UIColor.white
        title.textAlignment = .right
        title.snp.makeConstraints({ make in
            make.bottom.equalTo(preview.snp.bottom).offset(-PaperStorageLength.openedPaperTitleBottomMargin)
            make.trailing.equalTo(preview.snp.trailing).offset(-PaperStorageLength.openedPaperTitleRightMargin)
            make.leading.equalTo(preview.snp.leading).offset(PaperStorageLength.openedPaperTitleLeftMargin)
        })
        
        timer.snp.makeConstraints({ make in
            make.top.equalTo(preview.snp.top).offset(PaperStorageLength.timerTopMargin)
            make.leading.equalTo(preview.snp.leading).offset(PaperStorageLength.timerLeftMargin)
        })
    }
    
    func setCell(paper: PaperPreviewModel, thumbnail: UIImage?, now: Date) {
        timer.setEndTime(time: paper.endTime)
        title.text = paper.title
        preview.image = thumbnail
        preview.snp.updateConstraints({ make in
            make.width.equalTo(PaperStorageLength.openedPaperThumbnailWidth)
            make.height.equalTo(PaperStorageLength.openedPaperThumbnailHeight)
        })
    }
}
