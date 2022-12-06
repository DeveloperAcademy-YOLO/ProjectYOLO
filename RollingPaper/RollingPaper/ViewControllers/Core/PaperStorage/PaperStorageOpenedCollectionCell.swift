//
//  PaperStorageOpenedCell.swift
//  RollingPaper
//
//  Created by 김동락 on 2022/11/09.
//

import Combine
import SnapKit
import UIKit

// 컬렉션 뷰에 들어가는 셀들을 보여주는 뷰 (진행중인거)
final class PaperStorageOpenedCollectionCell: UICollectionViewCell {
    static let identifier = "OpenedCollectionCell"
    private var cancellables = Set<AnyCancellable>()
    
    // 셀 전체를 나타내는 뷰
    private let cell = UIView()
    // 페이퍼의 남은 시간을 보여주는 타이머
    private let timer = TimerView()
    // 페이퍼 썸네일 이미지가 들어가는 프리뷰
    private lazy var preview: UIImageView = {
        let preview = UIImageView()
        preview.layer.masksToBounds = true
        preview.layer.cornerRadius = PaperStorageLength.paperThumbnailCornerRadius
        preview.contentMode = .scaleAspectFill
        return preview
    }()
    // 프리뷰에 덮어씌우는 투명한 검은 배경
    private lazy var previewOverlay: UIView = {
        let previewOverlay = UIView()
        previewOverlay.backgroundColor = UIColor.black.withAlphaComponent(0.25)
        return previewOverlay
    }()
    // 페이퍼 제목
    private lazy var title: UILabel = {
        let title = UILabel()
        title.font = .preferredFont(for: .title1, weight: .semibold)
        title.textColor = UIColor.white
        title.textAlignment = .right
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
    
    override func prepareForReuse() {
        super.prepareForReuse()
        preview.image = nil
        title.text = nil
    }
    
    // 해당되는 셀 설정하기
    func setCell(paper: PaperPreviewModel, now: Date, cellWidth: CGFloat, isLocal: Bool) {
        timer.setEndTime(time: paper.endTime)
        title.text = paper.title
        preview.image = paper.template.thumbnail
        if let url = paper.thumbnailURLString {
            isLocal ? downloadImageFromLocal(thumbnailUrl: url) : downloadImageFromServer(thumbnailUrl: url)
        }
        preview.snp.updateConstraints({ make in
            make.width.equalTo(cellWidth)
            make.height.equalTo(PaperStorageLength.openedPaperThumbnailHeight)
        })
    }
    
    private func downloadImageFromLocal(thumbnailUrl: String) {
        if let cachedImage = NSCacheManager.shared.getImage(name: thumbnailUrl) {
            // 진입 경로1 - 캐시 데이터를 통한 다운로드
            preview.image = cachedImage
        } else {
            // 진입 경로2 - 파이어베이스에 접근해서 다운로드
            LocalStorageManager.downloadData(urlString: thumbnailUrl)
                .receive(on: DispatchQueue.global(qos: .background))
                .sink(receiveCompletion: { completion in
                    switch completion {
                    case .failure(let error):
                        print(error)
                    case .finished: break
                    }
                }, receiveValue: { [weak self] data in
                    guard let self = self else {return}
                    if let data = data, let image = UIImage(data: data) {
                        DispatchQueue.main.async {
                            self.preview.image = image
                        }
                        NSCacheManager.shared.setImage(image: image, name: thumbnailUrl)
                    }
                })
                .store(in: &cancellables)
        }
    }
    
    private func downloadImageFromServer(thumbnailUrl: String) {
        if let cachedImage = NSCacheManager.shared.getImage(name: thumbnailUrl) {
            // 진입 경로1 - 캐시 데이터를 통한 다운로드
            preview.image = cachedImage
        } else {
            // 진입 경로2 - 파이어베이스에 접근해서 다운로드
            FirebaseStorageManager.downloadData(urlString: thumbnailUrl)
                .receive(on: DispatchQueue.global(qos: .background))
                .sink(receiveCompletion: { completion in
                    switch completion {
                    case .failure(let error):
                        print(error)
                    case .finished: break
                    }
                }, receiveValue: { [weak self] data in
                    guard let self = self else {return}
                    if let data = data, let image = UIImage(data: data) {
                        DispatchQueue.main.async {
                            self.preview.image = image
                        }
                        NSCacheManager.shared.setImage(image: image, name: thumbnailUrl)
                    }
                })
                .store(in: &cancellables)
        }
    }
}

// 스냅킷 설정
extension PaperStorageOpenedCollectionCell {
    private func configure() {
        addSubview(cell)
        cell.addSubview(preview)
        cell.addSubview(timer)
        cell.addSubview(title)
        preview.addSubview(previewOverlay)
    }
    
    private func setConstraints() {
        cell.snp.makeConstraints({ make in
            make.edges.equalToSuperview()
        })
        preview.snp.makeConstraints({ make in
            make.top.equalToSuperview()
            make.leading.equalToSuperview()
            make.width.equalTo(PaperStorageLength.openedPaperThumbnailWidth1)
            make.height.equalTo(PaperStorageLength.openedPaperThumbnailHeight)
        })
        previewOverlay.snp.makeConstraints({ make in
            make.edges.equalToSuperview()
        })
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
}
