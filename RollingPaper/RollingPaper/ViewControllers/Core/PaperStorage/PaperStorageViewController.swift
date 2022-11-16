//
//  PaperStorageViewController.swift
//  RollingPaper
//
//  Created by 김동락 on 2022/10/12.
//

import Combine
import SnapKit
import UIKit

final class PaperStorageViewController: UIViewController {
    private let splitViewManager = SplitViewManager.shared
    private let viewModel = PaperStorageViewModel()
    private let input: PassthroughSubject<PaperStorageViewModel.Input, Never> = .init()
    
    private var cancellables = Set<AnyCancellable>()
    private var splitViewIsOpened: Bool = true
    private var viewIsChange: Bool = false
    private var dataState: DataState = .nothing
    
    lazy private var titleEmbedingTextField: UITextField = UITextField()
    
    enum DataState {
        case nothing, onlyOpened, onlyClosed, both
    }
    
    // 데이터 로딩시 보여줄 스피너
    private lazy var spinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView()
        spinner.color = .label
        return spinner
    }()
    // 페이퍼 목록 보여주는 컬렉션뷰
    private lazy var paperCollectionView: PaperStorageCollectionView = {
        let paperCollectionView = PaperStorageCollectionView(frame: .zero, collectionViewLayout: .init())
        paperCollectionView.setCollectionViewLayout(getCollectionViewLayout(), animated: false)
        
        paperCollectionView.backgroundColor = .systemBackground
        paperCollectionView.alwaysBounceVertical = true
        
        paperCollectionView.register(PaperStorageOpenedCollectionCell.self, forCellWithReuseIdentifier: PaperStorageOpenedCollectionCell.identifier)
        paperCollectionView.register(PaperStorageClosedCollectionCell.self, forCellWithReuseIdentifier: PaperStorageClosedCollectionCell.identifier)
        paperCollectionView.register(PaperStorageCollectionHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: PaperStorageCollectionHeader.identifier)
        
        paperCollectionView.dataSource = self
        paperCollectionView.delegate = self
        paperCollectionView.isHidden = true
        
        return paperCollectionView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bind()
        splitViewBind()
        setMainView()
        configure()
        setConstraints()
    }
    
    // splitview 나오게 하기
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.splitViewController?.show(.primary)
    }
    
    // 뷰모델한테 뷰 나타났다고 알려주기
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateLoadingView(isLoading: true)
        input.send(.viewDidAppear)
        viewIsChange = false
    }
    
    // 뷰모델한테 뷰 사라졌다고 알려주기
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        paperCollectionView.isHidden = true
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
                    // 변화가 있으면 UI 업데이트 하기
                case .initPapers:
                    self.updateLoadingView(isLoading: false)
                case .papersAreUpdatedByTimer, .papersAreUpdatedInDatabase:
                    break
                }
                self.setDataState()
                self.paperCollectionView.reloadData()
            })
            .store(in: &cancellables)
    }
    
    // splitView가 열리고 닫힘에 따라 어떤 행동을 할지 정하기
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
    
    // 메인 뷰 초기화
    private func setMainView() {
        view.backgroundColor = .systemBackground
    }
    
    // 진행중인거, 종료된거에 따라 데이터 상태 변경하기
    private func setDataState() {
        if viewModel.openedPapers.isEmpty && viewModel.closedPapers.isEmpty {
            dataState = .nothing
        } else if viewModel.openedPapers.isEmpty {
            dataState = .onlyClosed
        } else if viewModel.closedPapers.isEmpty {
            dataState = .onlyOpened
        } else {
            dataState = .both
        }
    }
    
    // 컬렉션 뷰 셀의 가로 길이 업데이트하기
    private func updateLayout() {
        let multiplyVal = splitViewIsOpened ? 0.75 : 1.0
        PaperStorageLength.openedPaperThumbnailWidth = (UIScreen.main.bounds.width*multiplyVal-(PaperStorageLength.sectionLeftMargin+PaperStorageLength.sectionRightMargin+PaperStorageLength.openedCellHorizontalSpace+2))/2
        PaperStorageLength.closedPaperThumbnailWidth = (UIScreen.main.bounds.width*multiplyVal-(PaperStorageLength.sectionLeftMargin+PaperStorageLength.sectionRightMargin))
        
        UIView.performWithoutAnimation({ [weak self] in
            guard let self = self else {return}
            let openedIndexPath = Array(0..<self.viewModel.openedPapers.count).map({ IndexPath(item: $0, section: 0) })
            self.paperCollectionView.reloadItems(at: openedIndexPath)
            self.paperCollectionView.reloadSections(IndexSet(integer: 1))
        })
    }
    
    // 로딩뷰 띄워주거나 없애기
    private func updateLoadingView(isLoading: Bool) {
        if isLoading {
            paperCollectionView.isHidden = true
            spinner.isHidden = false
            spinner.startAnimating()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now()+0.5) { [weak self] in
                guard let self = self else {return}
                self.paperCollectionView.isHidden = false
                self.spinner.isHidden = true
                self.spinner.stopAnimating()
            }
        }
    }
    
    // 컬렉션 뷰 레이아웃 가져오기
    private func getCollectionViewLayout() -> PaperStorageFlowLayout {
        let sectionInset = UIEdgeInsets(top: PaperStorageLength.sectionTopMargin, left: PaperStorageLength.sectionLeftMargin, bottom: PaperStorageLength.sectionBottomMargin, right: PaperStorageLength.sectionRightMargin)
        let collectionViewLayout = PaperStorageFlowLayout(cellSpacing: PaperStorageLength.openedCellHorizontalSpace, inset: sectionInset)
        collectionViewLayout.headerReferenceSize = .init(width: PaperStorageLength.headerWidth, height: PaperStorageLength.headerHeight)
        collectionViewLayout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        return collectionViewLayout
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
        return indexPath.section == 0 ? CGSize(width: PaperStorageLength.openedPaperThumbnailWidth, height: PaperStorageLength.openedPaperThumbnailHeight) : CGSize(width: PaperStorageLength.closedPaperThumbnailWidth, height: PaperStorageLength.closedPaperThumbnailHeight)
    }
    // 위아래 셀 간격
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return section == 0 ? PaperStorageLength.openedCellVerticalSpace : PaperStorageLength.closedCellVerticalSpace
    }
    // 좌우 셀 간격
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return section == 0 ? PaperStorageLength.openedCellHorizontalSpace : PaperStorageLength.closedCellHorizontalSpace
    }
    // 섹션별 셀 개수
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            return viewModel.openedPapers.count
        } else {
            if dataState == .onlyOpened {
                return 1
            } else {
                return viewModel.closedPapers.count
            }
        }
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
            if dataState == .onlyOpened {
                cell.setCell(paper: nil, thumbnail: nil)
            } else {
                let paper = viewModel.closedPapers[indexPath.item]
                let thumbnail = viewModel.thumbnails[paper.paperId, default: paper.template.thumbnail]
                cell.setCell(paper: paper, thumbnail: thumbnail)
            }
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
    
    private func deletePaper(_ paper: PaperPreviewModel) {
        let deleteVerifyText = self.titleEmbedingTextField.text
        if deleteVerifyText == paper.title {
            input.send(.paperDeleted(paperId: paper.paperId))
        } else {
            let alert = UIAlertController(title: "제목을 잘못 입력하셨습니다", message: nil, preferredStyle: .alert)
            let confirm = UIAlertAction(title: "확인", style: .default)
            alert.addAction(confirm)
            alert.preferredAction = confirm
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func deleteAlert(_ sender: CGRect, _ paper: PaperPreviewModel) {
        let allertController = UIAlertController(title: "페이퍼 삭제", message: "페이퍼를 삭제하려면 페이퍼 제목을 하단에 입력해주세요.", preferredStyle: .alert)
        let delete = UIAlertAction(title: "삭제", style: .destructive) { _ in
            self.deletePaper(paper)
        }
        let cancel = UIAlertAction(title: "취소", style: .cancel)
        allertController.addAction(delete)
        allertController.addAction(cancel)
        allertController.preferredAction = delete
        allertController.addTextField { (deleteTitleTextField) in
            deleteTitleTextField.placeholder = paper.title
            self.titleEmbedingTextField = deleteTitleTextField
        }
        let popover = allertController.popoverPresentationController
        popover?.sourceView = self.view
        popover?.backgroundColor = .systemBackground
        present(allertController, animated: true)
    }
    
    //셀 눌렀을 때 ContextMenu 추가
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemsAt indexPaths: [IndexPath], point: CGPoint) -> UIContextMenuConfiguration? {
        let senderPoint = CGRect(x: 0, y: 0, width: point.x, height: point.y)
        guard let indexPath = indexPaths.first else { return nil }
        let papers = indexPath.section == 0 ? self.viewModel.openedPapers: self.viewModel.closedPapers
        let selectedPaper = papers[indexPath.item]
        let config = UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            
            let share = UIAction(
                title: "페이퍼 공유하기",
                image: UIImage(systemName: "square.and.arrow.up"),
                identifier: nil,
                discoverabilityTitle: nil,
                state: .off
            ) { [weak self] _ in
            }
            
            let delete = UIAction(
                title: "페이퍼 삭제하기",
                image: UIImage(systemName: "trash"),
                identifier: nil,
                discoverabilityTitle: nil,
                attributes: .destructive,
                state: .off
            ) { [weak self] _ in
                self?.deleteAlert(senderPoint, selectedPaper)
            }
            
            return UIMenu(
                image: nil,
                identifier: nil,
                options: .singleSelection,
                children: [share,delete]
            )
        }
        return config
    }
}

// 스냅킷 설정
extension PaperStorageViewController {
    private func configure() {
        view.addSubview(spinner)
        view.addSubview(paperCollectionView)
    }
    
    private func setConstraints() {
        spinner.snp.makeConstraints({ make in
            make.edges.equalToSuperview()
        })
        paperCollectionView.snp.makeConstraints({ make in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide)
        })
    }
}

// 진행중인 페이퍼와 종료된 페이퍼들을 모두 보여주는 컬렉션 뷰
final private class PaperStorageCollectionView: UICollectionView {}
