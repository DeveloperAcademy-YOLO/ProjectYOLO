//
//  PaperStorageOpenedCell.swift
//  RollingPaper
//
//  Created by 김동락 on 2022/11/09.
//

import UIKit
import SnapKit

// 컬렉션 뷰에 들어가는 셀들을 보여주는 뷰 (진행중인거)
class PaperStorageOpenedCollectionCell: UICollectionViewCell {
    static let identifier = "OpenedCollectionCell"
    private let cell = UIView()
    private let preview = UIImageView()
    private let timer = UIStackView()
    private let clock = UIImageView()
    private let time = UILabel()
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
        timer.addArrangedSubview(clock)
        timer.addArrangedSubview(time)
        
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
        
        title.font = .preferredFont(for: .title1, weight: .semibold)
        title.textColor = UIColor.white
        title.textAlignment = .right
        title.snp.makeConstraints({ make in
            make.bottom.equalTo(preview.snp.bottom).offset(-PaperStorageLength.openedPaperTitleBottomMargin)
            make.trailing.equalTo(preview.snp.trailing).offset(-PaperStorageLength.openedPaperTitleRightMargin)
            make.leading.equalTo(preview.snp.leading).offset(PaperStorageLength.openedPaperTitleLeftMargin)
        })
        
        timer.layer.cornerRadius = PaperStorageLength.timerCornerRadius
        timer.distribution = .equalSpacing
        timer.layoutMargins = UIEdgeInsets(top: PaperStorageLength.timerTopPadding, left: PaperStorageLength.timerLeftPadding, bottom: PaperStorageLength.timerBottomPadding, right: PaperStorageLength.timerRightPadding)
        timer.isLayoutMarginsRelativeArrangement = true
        timer.layer.cornerRadius = PaperStorageLength.timerCornerRadius
        timer.spacing = PaperStorageLength.timerSpace
        timer.snp.makeConstraints({ make in
            make.top.equalTo(preview.snp.top).offset(PaperStorageLength.timerTopMargin)
            make.leading.equalTo(preview.snp.leading).offset(PaperStorageLength.timerLeftMargin)
        })
        
        clock.image = UIImage(systemName: "timer")
        clock.tintColor = UIColor.white
        clock.contentMode = .scaleAspectFit
        clock.snp.makeConstraints({ make in
            make.width.equalTo(PaperStorageLength.clockImageWidth)
            make.height.equalTo(PaperStorageLength.clockImageHeight)
        })
        
        time.font = .preferredFont(for: .subheadline, weight: .semibold)
        time.textAlignment = .right
        time.textColor = UIColor.white
    }
    
    // 초를 05:17(시간:분) 형식으로 바꾸기
    private func changeTimeFormat(second: Int) -> String {
        let hour = Int(second/3600)
        let minute = Int((second - (hour*3600))/60)
        var hourString = String(hour)
        var minuteString = String(minute)
        if hourString.count == 1 {
            hourString = "0" + hourString
        }
        if minuteString.count == 1 {
            minuteString = "0" + minuteString
        }
        
        return hourString + ":" + minuteString
    }
    
    // 날짜를 2022.10.13 같은 형식으로 바꾸기
    private func changeDateFormat(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "y.M.d"
        return dateFormatter.string(from: date)
    }
    
    func setCell(paper: PaperPreviewModel, thumbnail: UIImage?, now: Date) {
        let timeInterval = Int(paper.endTime.timeIntervalSince(now))
        // 10분 이상 남은 페이퍼라면
        if timeInterval > 600 {
            timer.backgroundColor = UIColor.black.withAlphaComponent(0.32)
        } else {
            timer.backgroundColor = UIColor.red
        }
        time.text = changeTimeFormat(second: timeInterval)
        title.text = paper.title
        preview.image = thumbnail
        preview.snp.updateConstraints({ make in
            make.width.equalTo(PaperStorageLength.openedPaperThumbnailWidth)
            make.height.equalTo(PaperStorageLength.openedPaperThumbnailHeight)
        })
    }
}
