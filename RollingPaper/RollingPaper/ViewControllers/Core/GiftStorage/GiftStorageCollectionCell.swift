//
//  GiftStorageCollectionCell.swift
//  RollingPaper
//
//  Created by 김동락 on 2022/11/15.
//

import SnapKit
import UIKit

// 컬렉션 뷰에 들어가는 셀들을 보여주는 뷰 (종료된거)
final class GiftStorageCollectionCell: UICollectionViewCell {
    static let identifier = "CollectionCell"
    
    // 셀 전체를 나타내는 뷰
    private let cell = UIView()
    // 페이퍼 썸네일 이미지가 들어가는 프리뷰
    private lazy var preview: UIImageView = {
        let preview = UIImageView()
        preview.layer.masksToBounds = true
        preview.layer.cornerRadius = GiftStorageLength.paperThumbnailCornerRadius
        preview.contentMode = .scaleAspectFill
        return preview
    }()
    // 프리뷰에 덮어씌우는 투명한 검은 배경
    private let previewOverlay: UIView = {
        let previewOverlay = UIView()
        previewOverlay.backgroundColor = UIColor.black.withAlphaComponent(0.25)
        return previewOverlay
    }()
    // 페이퍼에 들어가는 글자들 포함하는 스택
    private let label: UIStackView = {
        let label = UIStackView()
        label.axis = .vertical
        label.spacing = GiftStorageLength.labelSpacing
        return label
    }()
    // 페이퍼 제목
    private let title: UILabel = {
        let title = UILabel()
        title.font = .preferredFont(for: .largeTitle, weight: .semibold)
        title.textColor = UIColor.white
        title.textAlignment = .center
        return title
    }()
    // 페이퍼 종료 날짜
    private let date: UILabel = {
        let date = UILabel()
        date.font = .preferredFont(for: .subheadline, weight: .bold)
        date.textColor = UIColor.white
        date.textAlignment = .center
        return date
    }()
    // 보낸 사람
    private let sender: BasePaddingLabel = {
        let sender = BasePaddingLabel(padding: UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4))
        sender.layer.cornerRadius = 8
        sender.layer.masksToBounds = true
        sender.backgroundColor = .black.withAlphaComponent(0.64)
        sender.textColor = .white
        
        return sender
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
        setConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // 날짜를 2022.10.13 같은 형식으로 바꾸기
    private func changeDateFormat(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "y.M.d"
        return dateFormatter.string(from: date)
    }
    
    // 해당되는 셀 설정하기
    func setCell(paper: PaperPreviewModel?, thumbnail: UIImage?) {
        if let paper = paper {
            date.text = changeDateFormat(date: paper.endTime)
            title.text = paper.title
            sender.text = (paper.creator?.name ?? "?") + "님이 보낸 선물"
            preview.image = thumbnail
            preview.snp.updateConstraints({ make in
                make.width.equalTo(GiftStorageLength.paperThumbnailWidth)
                make.height.equalTo(GiftStorageLength.paperThumbnailHeight)
            })
            isHidden = false
        } else {
            isHidden = true
        }
    }
}

// 스냅킷 설정
extension GiftStorageCollectionCell {
    private func configure() {
        addSubview(cell)
        cell.addSubview(preview)
        cell.addSubview(label)
        cell.addSubview(sender)
        preview.addSubview(previewOverlay)
        label.addArrangedSubview(title)
        label.addArrangedSubview(date)
    }
    
    private func setConstraints() {
        cell.snp.makeConstraints({ make in
            make.edges.equalToSuperview()
        })
        preview.snp.makeConstraints({ make in
            make.top.equalToSuperview()
            make.leading.equalToSuperview()
            make.width.equalTo(GiftStorageLength.paperThumbnailWidth)
            make.height.equalTo(GiftStorageLength.paperThumbnailHeight)
        })
        previewOverlay.snp.makeConstraints({ make in
            make.edges.equalToSuperview()
        })
        label.snp.makeConstraints({ make in
            make.centerX.equalTo(preview)
            make.centerY.equalTo(preview)
        })
        sender.snp.makeConstraints({ make in
            make.top.equalToSuperview().offset(9)
            make.leading.equalToSuperview().offset(11)
        })
    }
}
