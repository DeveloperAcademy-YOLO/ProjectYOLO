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
    static let paperThumbnailCornerRadius: CGFloat = 12
    static let headerWidth: CGFloat = 200 // 임시
    static let headerHeight: CGFloat = 29
    static let headerLeftMargin: CGFloat = 37
    static let sectionTopMargin: CGFloat = 16
    static let sectionBottomMargin: CGFloat = 48
    static let sectionRightMargin: CGFloat = 36
    static let sectionLeftMargin: CGFloat = 36
    
    static var openedPaperThumbnailWidth: CGFloat = (UIScreen.main.bounds.width*0.75-(sectionLeftMargin+sectionRightMargin+openedCellHorizontalSpace+2))/2 // 반응형
    static let openedPaperThumbnailHeight: CGFloat = openedPaperThumbnailWidth*0.33
    static let openedPaperTitleBottomMargin: CGFloat = 16
    static let openedPaperTitleRightMargin: CGFloat = 16
    static let openedCellHorizontalSpace: CGFloat = 18
    static let openedCellVerticalSpace: CGFloat = 18
    static let timerTopMargin: CGFloat = 8
    static let timerLeftMargin: CGFloat = 8
    static let timerTopPadding: CGFloat = 5
    static let timerBottomPadding: CGFloat = 5
    static let timerRightPadding: CGFloat = 7
    static let timerLeftPadding: CGFloat = 7
    static let timerSpace: CGFloat = 5
    static let timerCornerRadius: CGFloat = 8
    static let clockImageWidth: CGFloat = 14
    static let clockImageHeight: CGFloat = 14
    
    static var closedPaperThumbnailWidth: CGFloat = (UIScreen.main.bounds.width*0.75-(sectionLeftMargin+sectionRightMargin)) // 반응형
    static let closedPaperThumbnailHeight: CGFloat = closedPaperThumbnailWidth*0.16
    static let closedCellHorizontalSpace: CGFloat = 0
    static let closedCellVerticalSpace: CGFloat = 10
    static let labelSpacing: CGFloat = 10
}

class PaperStorageViewController: UIViewController {
    private let splitViewManager = SplitViewManager.shared
    private let viewModel = PaperStorageViewModel()
    private let input: PassthroughSubject<PaperStorageViewModel.Input, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    private var paperCollectionView: PaperStorageCollectionView?
    private var splitViewIsOpened: Bool = true
    private var viewIsChange: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bind()
        splitViewBind()
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
        viewIsChange = false
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
    
    // splitView에 대한 어떤 행동을 받고 그에 따라 어떤 행동을 할지 정하기
    private func splitViewBind() {
        viewIsChange = false
        let output = splitViewManager.getOutput()
        output
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] event in
                guard let self = self else {return}
                if !self.viewIsChange {
                    switch event {
                    case .viewIsOpened:
                        self.splitViewIsOpened = true
                    case .viewIsClosed:
                        self.splitViewIsOpened = false
                    }
                    self.updateLayout()
                }
            })
            .store(in: &cancellables)
    }
    
    // 스플릿뷰 열고닫음에 따라 뷰 업데이트하기
    private func updateLayout() {
        let multiplyVal = splitViewIsOpened ? 0.75 : 1.0
        Length.openedPaperThumbnailWidth = (UIScreen.main.bounds.width*multiplyVal-(Length.sectionLeftMargin+Length.sectionRightMargin+Length.openedCellHorizontalSpace+2))/2
        Length.closedPaperThumbnailWidth = (UIScreen.main.bounds.width*multiplyVal-(Length.sectionLeftMargin+Length.sectionRightMargin))
        paperCollectionView?.reloadData()
    }
    
    // 메인 뷰 초기화
    private func setMainView() {
        view.backgroundColor = .systemBackground
    }
    
    // 컬렉션 뷰 레이아웃 초기화
    private func setCollectionViewLayout() {
        let collectionViewLayer = UICollectionViewFlowLayout()
        collectionViewLayer.sectionInset = UIEdgeInsets(top: Length.sectionTopMargin, left: Length.sectionLeftMargin, bottom: Length.sectionBottomMargin, right: Length.sectionRightMargin)
        collectionViewLayer.headerReferenceSize = .init(width: Length.headerWidth, height: Length.headerHeight)
        self.paperCollectionView?.setCollectionViewLayout(collectionViewLayer, animated: false)
    }
    
    // 컬렉션 뷰 초기화
    private func setCollectionView() {
        paperCollectionView = PaperStorageCollectionView(frame: .zero, collectionViewLayout: .init())
        setCollectionViewLayout()
        
        guard let collectionView = paperCollectionView else {return}
        collectionView.backgroundColor = .systemBackground
        collectionView.alwaysBounceVertical = true
        collectionView.register(PaperStorageOpenedCollectionCell.self, forCellWithReuseIdentifier: PaperStorageOpenedCollectionCell.identifier)
        collectionView.register(PaperStorageClosedCollectionCell.self, forCellWithReuseIdentifier: PaperStorageClosedCollectionCell.identifier)
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
        return indexPath.section == 0 ? CGSize(width: Length.openedPaperThumbnailWidth, height: Length.openedPaperThumbnailHeight) : CGSize(width: Length.closedPaperThumbnailWidth, height: Length.closedPaperThumbnailHeight)
    }
    // 위아래 셀 간격
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return section == 0 ? Length.openedCellVerticalSpace : Length.closedCellVerticalSpace
    }
    // 좌우 셀 간격
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return section == 0 ? Length.openedCellHorizontalSpace : Length.closedCellHorizontalSpace
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
        if indexPath.section == 0 {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PaperStorageOpenedCollectionCell.identifier, for: indexPath) as? PaperStorageOpenedCollectionCell else {return UICollectionViewCell()}
            let paper = viewModel.openedPapers[indexPath.item]
            let thumbnail = viewModel.thumbnails[paper.paperId, default: paper.template.thumbnail]
            cell.setCell(paper: paper, thumbnail: thumbnail, now: viewModel.currentTime)
            return cell
        } else {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PaperStorageClosedCollectionCell.identifier, for: indexPath) as? PaperStorageClosedCollectionCell else {return UICollectionViewCell()}
            let paper = viewModel.closedPapers[indexPath.item]
            let thumbnail = viewModel.thumbnails[paper.paperId, default: paper.template.thumbnail]
            cell.setCell(paper: paper, thumbnail: thumbnail)
            return cell
        }
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
        viewIsChange = true
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
            make.leading.equalToSuperview().offset(Length.headerLeftMargin)
        })
    }
    
    func setHeader(text: String) {
        title.text = text
    }
}

// 컬렉션 뷰에 들어가는 셀들을 보여주는 뷰 (진행중인거)
private class PaperStorageOpenedCollectionCell: UICollectionViewCell {
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
        preview.layer.cornerRadius = Length.paperThumbnailCornerRadius
        preview.contentMode = .scaleAspectFill
        preview.snp.makeConstraints({ make in
            make.top.equalToSuperview()
            make.leading.equalToSuperview()
            make.width.equalTo(Length.openedPaperThumbnailWidth)
            make.height.equalTo(Length.openedPaperThumbnailHeight)
        })
        
        title.font = .preferredFont(for: .title1, weight: .semibold)
        title.textColor = UIColor.white
        title.textAlignment = .center
        title.snp.makeConstraints({ make in
            make.bottom.equalTo(preview.snp.bottom).offset(-Length.openedPaperTitleBottomMargin)
            make.trailing.equalTo(preview.snp.trailing).offset(-Length.openedPaperTitleRightMargin)
        })
        
        timer.layer.cornerRadius = Length.timerCornerRadius
        timer.distribution = .equalSpacing
        timer.layoutMargins = UIEdgeInsets(top: Length.timerTopPadding, left: Length.timerLeftPadding, bottom: Length.timerBottomPadding, right: Length.timerRightPadding)
        timer.isLayoutMarginsRelativeArrangement = true
        timer.layer.cornerRadius = Length.timerCornerRadius
        timer.spacing = Length.timerSpace
        timer.snp.makeConstraints({ make in
            make.top.equalTo(preview.snp.top).offset(Length.timerTopMargin)
            make.leading.equalTo(preview.snp.leading).offset(Length.timerLeftMargin)
        })
        
        clock.image = UIImage(systemName: "timer")
        clock.tintColor = UIColor.white
        clock.contentMode = .scaleAspectFit
        clock.snp.makeConstraints({ make in
            make.width.equalTo(Length.clockImageWidth)
            make.height.equalTo(Length.clockImageHeight)
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
            make.width.equalTo(Length.openedPaperThumbnailWidth)
            make.height.equalTo(Length.openedPaperThumbnailHeight)
        })
    }
}

// 컬렉션 뷰에 들어가는 셀들을 보여주는 뷰 (종료된거)
private class PaperStorageClosedCollectionCell: UICollectionViewCell {
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
        preview.layer.cornerRadius = Length.paperThumbnailCornerRadius
        preview.contentMode = .scaleAspectFill
        preview.snp.makeConstraints({ make in
            make.top.equalToSuperview()
            make.leading.equalToSuperview()
            make.width.equalTo(Length.closedPaperThumbnailWidth)
            make.height.equalTo(Length.closedPaperThumbnailHeight)
        })
        
        previewOverlay.backgroundColor = UIColor.black.withAlphaComponent(0.25)
        previewOverlay.snp.makeConstraints({ make in
            make.edges.equalToSuperview()
        })
        
        label.axis = .vertical
        label.spacing = Length.labelSpacing
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
    
    func setCell(paper: PaperPreviewModel, thumbnail: UIImage?) {
        date.text = changeDateFormat(date: paper.endTime)
        title.text = paper.title
        preview.image = thumbnail
        preview.snp.updateConstraints({ make in
            make.width.equalTo(Length.closedPaperThumbnailWidth)
            make.height.equalTo(Length.closedPaperThumbnailHeight)
        })
    }
}
