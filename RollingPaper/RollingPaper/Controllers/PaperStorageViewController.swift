//
//  PaperStorageViewController.swift
//  RollingPaper
//
//  Created by 김동락 on 2022/10/12.
//

import UIKit
import SnapKit
import Combine

private class Length {
    static let paperThumbnailWidth: CGFloat = (UIScreen.main.bounds.width*0.75-(24*5))/4
    static let paperThumbnailHeight: CGFloat = paperThumbnailWidth*0.75
    static let paperThumbnailCornerRadius: CGFloat = 12
    static let paperTitleHeight: CGFloat = 19
    static let paperTitleTopMargin: CGFloat = 16
    static let timerHeight: CGFloat = 28
    static let timerTopMargin: CGFloat = 12
    static let cellWidth: CGFloat = paperThumbnailWidth
    static let cellHeight: CGFloat = paperThumbnailHeight + paperTitleTopMargin + paperTitleHeight + timerTopMargin + timerHeight
    static let cellHorizontalSpace: CGFloat = 20
    static let cellVerticalSpace: CGFloat = 28
    static let sectionTopMargin: CGFloat = 28
    static let sectionBottomMargin: CGFloat = 48
    static let sectionRightMargin: CGFloat = 28
    static let sectionLeftMargin: CGFloat = 28
    static let headerWidth: CGFloat = 116
    static let headerHeight: CGFloat = 29
    static let headerLeftMargin: CGFloat = 34
    static let timerTopPadding: CGFloat = 7
    static let timerBottomPadding: CGFloat = 7
    static let timerRightPadding: CGFloat = 10
    static let timerLeftPadding: CGFloat = 10
    static let timerSpace: CGFloat = 5
    static let timerCornerRadius: CGFloat = 15
    static let clockImageWidth: CGFloat = 14
    static let clockImageHeight: CGFloat = 14
}

class PaperStorageViewController: UIViewController {
    private let viewModel = PaperStorageViewModel()
    private let input: PassthroughSubject<PaperStorageViewModel.Input, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    private var paperCollectionView: PaperStorageCollectionView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bind()
        setMainView()
        setCollectionView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.splitViewController?.show(.primary)
    }
    
    // view가 나타나면 알려주기
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        input.send(.viewDidAppear)
    }
    
    // view가 사라지면 알려주기
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        input.send(.viewDidDisappear)
    }
    
    // Input이 설정될때마다 자동으로 transform 함수가 실행되고 그 결과값으로 Output이 오면 어떤 행동을 할지 정하기
    private func bind() {
        let output = viewModel.transform(input: input.eraseToAnyPublisher())
        output
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] event in
                guard let self = self else {return}
                switch event {
                // 페이퍼에 변화가 있으면 UI 업데이트 하기
                case .initPapers, .papersAreUpdatedInDatabase, .papersAreUpdatedByTimer:
                    self.paperCollectionView?.reloadData()
                }
            })
            .store(in: &cancellables)
    }
    
    // 메인 뷰 초기화
    private func setMainView() {
        view.backgroundColor = .systemBackground
    }
    
    // 컬렉션 뷰 초기화
    private func setCollectionView() {
        let collectionViewLayer = UICollectionViewFlowLayout()
        collectionViewLayer.sectionInset = UIEdgeInsets(top: Length.sectionTopMargin, left: Length.sectionLeftMargin, bottom: Length.sectionBottomMargin, right: Length.sectionRightMargin)
        collectionViewLayer.minimumInteritemSpacing = Length.cellHorizontalSpace
        collectionViewLayer.minimumLineSpacing = Length.cellVerticalSpace
        collectionViewLayer.headerReferenceSize = .init(width: Length.headerWidth, height: Length.headerHeight)
        
        paperCollectionView = PaperStorageCollectionView(frame: .zero, collectionViewLayout: collectionViewLayer)
        guard let collectionView = paperCollectionView else {return}
        
        collectionView.backgroundColor = .white
        collectionView.alwaysBounceVertical = true
        collectionView.register(PaperStorageCollectionCell.self, forCellWithReuseIdentifier: PaperStorageCollectionCell.identifier)
        collectionView.register(PaperStorageCollectionHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: PaperStorageCollectionHeader.identifier)
        collectionView.dataSource = self
        collectionView.delegate = self
        
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints({ make in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide)
        })
    }
    
    // 특정 페이퍼를 선택하면 알려주기
    func setSelectedPaper(paperId: String) {
        input.send(.paperSelected(paperId: paperId))
    }
}

// 컬렉션 뷰에 대한 여러 설정들을 해줌
extension PaperStorageViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    // 셀의 사이즈
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: Length.cellWidth, height: Length.cellHeight)
    }
    // 섹션별 셀 개수
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return section == 0 ? viewModel.openedPapers.count : viewModel.closedPapers.count
    }
    // 섹션의 개수
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    // 특정 위치의 셀
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PaperStorageCollectionCell.identifier, for: indexPath) as? PaperStorageCollectionCell else {return UICollectionViewCell()}
        let paper = indexPath.section == 0 ? viewModel.openedPapers[indexPath.item] : viewModel.closedPapers[indexPath.item]
        let thumbnail = viewModel.thumbnails[paper.paperId, default: paper.template.thumbnail]
        cell.setCell(paper: paper, thumbnail: thumbnail, now: viewModel.currentTime)
        return cell
    }
    // 특정 위치의 헤더
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            guard let supplementaryView = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: PaperStorageCollectionHeader.identifier,
                for: indexPath
            ) as? PaperStorageCollectionHeader else {return UICollectionReusableView()}
            supplementaryView.setHeader(text: indexPath.section == 0 ? "진행중인 페이퍼" : "종료된 페이퍼")
            return supplementaryView
        } else {
            return UICollectionReusableView()
        }
    }
    
    // 특정 셀 눌렀을 떄의 동작
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        let papers = indexPath.section == 0 ? self.viewModel.openedPapers: self.viewModel.closedPapers
        self.setSelectedPaper(paperId: papers[indexPath.item].paperId )
        navigationController?.pushViewController(WrittenPaperViewController(), animated: true)
        return true
    }
}

// 진행중인 페이퍼와 종료된 페이퍼들을 모두 보여주는 컬렉션 뷰
private class PaperStorageCollectionView: UICollectionView {}

// 컬렉션 뷰에서 섹션의 제목을 보여주는 뷰
private class PaperStorageCollectionHeader: UICollectionReusableView {
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
            make.leading.equalToSuperview().offset(34)
        })
    }
    
    func setHeader(text: String) {
        title.text = text
    }
}

// 컬렉션 뷰에 들어가는 셀들을 보여주는 뷰
private class PaperStorageCollectionCell: UICollectionViewCell {
    static let identifier = "CollectionCell"
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
        cell.addSubview(title)
        cell.addSubview(timer)
        timer.addArrangedSubview(clock)
        timer.addArrangedSubview(time)
        
        cell.snp.makeConstraints({ make in
            make.edges.equalToSuperview()
        })
        
        preview.layer.masksToBounds = true
        preview.layer.cornerRadius = Length.paperThumbnailCornerRadius
        preview.snp.makeConstraints({ make in
            make.top.equalToSuperview()
            make.leading.equalToSuperview()
            make.width.equalTo(Length.paperThumbnailWidth)
            make.height.equalTo(Length.paperThumbnailHeight)
        })
        
        title.font = .preferredFont(forTextStyle: .body)
        title.textColor = UIColor(rgb: 0x808080)
        title.textAlignment = .center
        title.snp.makeConstraints({ make in
            make.top.equalTo(preview.snp.bottom).offset(Length.paperTitleTopMargin)
            make.centerX.equalToSuperview()
            make.width.equalToSuperview()
        })
        
        timer.layer.cornerRadius = Length.timerCornerRadius
        timer.distribution = .equalSpacing
        timer.layoutMargins = UIEdgeInsets(top: Length.timerTopPadding, left: Length.timerLeftPadding, bottom: Length.timerBottomPadding, right: Length.timerRightPadding)
        timer.isLayoutMarginsRelativeArrangement = true
        timer.layer.cornerRadius = Length.timerCornerRadius
        timer.spacing = Length.timerSpace
        timer.snp.makeConstraints({ make in
            make.top.equalTo(title.snp.bottom).offset(Length.timerTopMargin)
            make.centerX.equalToSuperview()
        })
        
        clock.image = UIImage(systemName: "timer")
        clock.tintColor = .white
        clock.contentMode = .scaleAspectFit
        clock.snp.makeConstraints({ make in
            make.width.equalTo(Length.clockImageWidth)
            make.height.equalTo(Length.clockImageHeight)
        })
        
        time.font = .preferredFont(forTextStyle: .body)
        time.textAlignment = .right
        time.textColor = .white
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
        if timeInterval > 0 {
            // 진행중인 페이퍼라면
            timer.backgroundColor = UIColor(rgb: 0xFF3B30)
            time.text = changeTimeFormat(second: timeInterval)
            clock.isHidden = false
        } else {
            // 종료된 페이퍼라면
            timer.backgroundColor = UIColor(rgb: 0xADADAD)
            time.text = changeDateFormat(date: now)
            clock.isHidden = true
        }
        
        title.text = paper.title
        preview.image = thumbnail
    }
}
