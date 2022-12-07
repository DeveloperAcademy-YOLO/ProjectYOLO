//
//  PaperStorageClosedCollectionCell.swift
//  RollingPaper
//
//  Created by 김동락 on 2022/11/09.
//

import SnapKit
import UIKit
import Combine

// 컬렉션 뷰에 들어가는 셀들을 보여주는 뷰 (종료된거)
final class PaperStorageClosedCollectionCell: UICollectionViewCell {
    static let identifier = "ClosedCollectionCell"
    private var cancellables = Set<AnyCancellable>()
    
    // 셀 전체를 나타내는 뷰
    private let cell = UIView()
    // 페이퍼 썸네일 이미지가 들어가는 프리뷰
    private lazy var preview: UIImageView = {
        let preview = UIImageView()
        preview.layer.masksToBounds = true
        preview.layer.cornerRadius = PaperStorageLength.paperThumbnailCornerRadius
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
        label.spacing = PaperStorageLength.labelSpacing
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
    
    // 날짜를 2022.10.13 같은 형식으로 바꾸기
    private func changeDateFormat(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "y.M.d"
        return dateFormatter.string(from: date)
    }
    
    // 해당되는 셀 설정하기
    func setCell(paper: PaperPreviewModel?, cellWidth: CGFloat, isLocal: Bool) {
        if let paper = paper {
            date.text = changeDateFormat(date: paper.endTime)
            title.text = paper.title
            preview.image = paper.template.thumbnail
            if let url = paper.thumbnailURLString {
                isLocal ? downloadImageFromLocal(thumbnailUrl: url) : downloadImageFromServer(thumbnailUrl: url)
            }
            preview.snp.updateConstraints({ make in
                make.width.equalTo(cellWidth)
                make.height.equalTo(PaperStorageLength.closedPaperThumbnailHeight)
            })
            isHidden = false
        } else {
            isHidden = true
        }
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
extension PaperStorageClosedCollectionCell {
    private func configure() {
        addSubview(cell)
        cell.addSubview(preview)
        cell.addSubview(label)
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
            make.width.equalTo(PaperStorageLength.closedPaperThumbnailWidth1)
            make.height.equalTo(PaperStorageLength.closedPaperThumbnailHeight)
        })
        previewOverlay.snp.makeConstraints({ make in
            make.edges.equalToSuperview()
        })
        label.snp.makeConstraints({ make in
            make.centerX.equalTo(preview)
            make.centerY.equalTo(preview)
        })
    }
}
