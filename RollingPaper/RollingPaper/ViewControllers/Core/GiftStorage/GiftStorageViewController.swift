//
//  GiftStorageViewController.swift
//  RollingPaper
//
//  Created by 김동락 on 2022/11/15.
//

import Combine
import SnapKit
import UIKit

final class GiftStorageViewController: UIViewController {
    private let splitViewManager = SplitViewManager.shared
    private let viewModel = GiftStorageViewModel()
    private let input: PassthroughSubject<GiftStorageViewModel.Input, Never> = .init()
    
    private var cancellables = Set<AnyCancellable>()
    private var splitViewIsOpened: Bool = true
    private var viewIsChange: Bool = false
    
    // 데이터 로딩시 보여줄 스피너
    private lazy var spinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView()
        spinner.color = .label
        return spinner
    }()
    // 페이퍼 목록 보여주는 컬렉션뷰
    private lazy var paperCollectionView: GiftStorageCollectionView = {
        let paperCollectionView = GiftStorageCollectionView(frame: .zero, collectionViewLayout: .init())
        paperCollectionView.setCollectionViewLayout(getCollectionViewLayout(), animated: false)
 
        paperCollectionView.backgroundColor = .systemBackground
        paperCollectionView.alwaysBounceVertical = true

        paperCollectionView.register(GiftStorageCollectionCell.self, forCellWithReuseIdentifier: GiftStorageCollectionCell.identifier)
        paperCollectionView.register(GiftStorageCollectionHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: GiftStorageCollectionHeader.identifier)
        
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
                case .papersAreUpdatedInDatabase:
                    break
                }
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
    
    // 컬렉션 뷰 셀의 가로 길이 업데이트하기
    private func updateLayout() {
        let multiplyVal = splitViewIsOpened ? 0.75 : 1.0
        GiftStorageLength.paperThumbnailWidth = (UIScreen.main.bounds.width*multiplyVal-(GiftStorageLength.sectionLeftMargin+GiftStorageLength.sectionRightMargin+GiftStorageLength.cellHorizontalSpace+2))/2
        paperCollectionView.reloadData()
    }
    
    // 로딩뷰 띄워주거나 없애기
    private func updateLoadingView(isLoading: Bool) {
        if isLoading {
            paperCollectionView.isHidden = true
            spinner.isHidden = false
            spinner.startAnimating()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now()+0.2) { [weak self] in
                guard let self = self else {return}
                self.paperCollectionView.isHidden = false
                self.spinner.isHidden = true
                self.spinner.stopAnimating()
            }
        }
    }
    
    // 컬렉션 뷰 레이아웃 가져오기
    private func getCollectionViewLayout() -> UICollectionViewFlowLayout {
        let collectionViewLayer = UICollectionViewFlowLayout()
        collectionViewLayer.sectionInset = UIEdgeInsets(top: GiftStorageLength.sectionTopMargin, left: GiftStorageLength.sectionLeftMargin, bottom: GiftStorageLength.sectionBottomMargin, right: GiftStorageLength.sectionRightMargin)
        collectionViewLayer.minimumInteritemSpacing = GiftStorageLength.cellHorizontalSpace
        collectionViewLayer.minimumLineSpacing = GiftStorageLength.cellVerticalSpace
        collectionViewLayer.headerReferenceSize = .init(width: GiftStorageLength.headerWidth, height: GiftStorageLength.headerHeight)
        return collectionViewLayer
    }
    
    // 특정 페이퍼를 선택하면 알려주기
    func setSelectedPaper(paperId: String) {
        input.send(.paperSelected(paperId: paperId))
    }
}

// 컬렉션 뷰에 대한 여러 설정들을 해줌
extension GiftStorageViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    // 셀의 사이즈
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: GiftStorageLength.paperThumbnailWidth, height: GiftStorageLength.paperThumbnailHeight)
    }
    // 위아래 셀 간격
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return GiftStorageLength.cellVerticalSpace
    }
    // 좌우 셀 간격
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return GiftStorageLength.cellHorizontalSpace
    }
    // 섹션별 셀 개수
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.papers.count
    }
    // 섹션의 개수
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    // 특정 위치의 셀
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GiftStorageCollectionCell.identifier, for: indexPath) as? GiftStorageCollectionCell else {return UICollectionViewCell()}

        let paper = viewModel.papers[indexPath.item]
        let thumbnail = viewModel.thumbnails[paper.paperId, default: paper.template.thumbnail]
        cell.setCell(paper: paper, thumbnail: thumbnail)
        
        return cell
    }
    // 특정 위치의 헤더
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            guard let supplementaryView = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: GiftStorageCollectionHeader.identifier,
                for: indexPath
            ) as? GiftStorageCollectionHeader else {return UICollectionReusableView()}
            supplementaryView.setHeader(text: "aaa")
            return supplementaryView
        } else {
            return UICollectionReusableView()
        }
    }
    // 특정 셀 눌렀을 떄의 동작
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        setSelectedPaper(paperId: viewModel.papers[indexPath.item].paperId )
        viewIsChange = true
        navigationController?.pushViewController(WrittenPaperViewController(), animated: true)
        return true
    }
}

// 스냅킷 설정
extension GiftStorageViewController {
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
final private class GiftStorageCollectionView: UICollectionView {}
