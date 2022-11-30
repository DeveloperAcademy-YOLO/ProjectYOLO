//
//  TemplateSelectViewController.swift
//  RollingPaper
//
//  Created by 김동락 on 2022/10/05.
//

import UIKit
import SnapKit
import Combine

class PaperTemplateSelectViewController: UIViewController {
    private let splitViewManager = SplitViewManager.shared
    private let viewModel = PaperTemplateSelectViewModel()
    private let input: PassthroughSubject<PaperTemplateSelectViewModel.Input, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    private var isLoading: Bool = true
    private var recentTemplates = [TemplateEnum]()
    private var isRecentExist: Bool {
        return recentTemplates.count == 0 ? false : true
    }
    
    enum RecentExistState {
        case none, one, two, all
    }
    
    // 데이터 로딩시 보여줄 스피너
    private lazy var spinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView()
        spinner.color = .label
        return spinner
    }()
    // 템플릿 목록 보여주는 컬렉션뷰
    private lazy var templateCollectionView: PaperTemplateCollectionView = {
        let templateCollectionView = PaperTemplateCollectionView(frame: .zero, collectionViewLayout: .init())
        templateCollectionView.setCollectionViewLayout(getCollectionViewLayout(), animated: false)
        
        templateCollectionView.backgroundColor = .systemBackground
        templateCollectionView.alwaysBounceVertical = true
        
        templateCollectionView.register(PaperTemplateCollectionCell.self, forCellWithReuseIdentifier: PaperTemplateCollectionCell.identifier)
        templateCollectionView.register(PaperTemplateCollectionHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: PaperTemplateCollectionHeader.identifier)
        
        templateCollectionView.dataSource = self
        templateCollectionView.delegate = self
        templateCollectionView.isHidden = true
        
        return templateCollectionView
    }()
    
    // splitview 나오게 하기
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.splitViewController?.show(.primary)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateLoadingView()
        bind()
        splitViewBind()
        setMainView()
        configure()
        setConstraints()
    }
    
    // view가 나타날때마다 최근 템플릿 확인하기 위해 input에 값 설정하기
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        input.send(.viewDidAppear)
    }
    
    // Input이 설정될때마다 자동으로 transform 함수가 실행되고 그 결과값으로 Output이 오면 어떤 행동을 할지 정하기
    private func bind() {
        let output = viewModel.transform(input: input.eraseToAnyPublisher())
        output
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] event in
                guard let self = self else {return}
                switch event {
                // 최근 템플릿 설정하기
                case .getRecentTemplateSuccess(let templates):
                    self.recentTemplates = templates
                case .getRecentTemplateFail:
                    self.recentTemplates = []
                }
                
                self.templateCollectionView.reloadData()
                if !self.isLoading {
                    self.updateLoadingView()
                }
                
            })
            .store(in: &cancellables)
    }
    
    // splitView에 대한 어떤 행동을 받고 그에 따라 어떤 행동을 할지 정하기
    private func splitViewBind() {
        let output = splitViewManager.getOutput()
        output
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] event in
                guard let self = self else {return}
                var extraLeftMargin: Int
                var extraRightMargin: Int
                switch event {
                case .viewIsOpened:
                    extraLeftMargin = 0
                    extraRightMargin = 0
                case .viewIsClosed:
                    extraLeftMargin = 54
                    extraRightMargin = 24
                }
                self.templateCollectionView.snp.updateConstraints({ make in
                    make.leading.equalToSuperview().offset(extraLeftMargin)
                    make.trailing.equalToSuperview().offset(extraRightMargin)
                })
                UIView.animate(withDuration: 0.5, delay: 0, animations: { [weak self] in
                    guard let self = self else {return}
                    self.view.layoutIfNeeded()
                })
            })
            .store(in: &cancellables)
    }
    
    // 로딩뷰 띄워주거나 없애기
    private func updateLoadingView() {
        if isLoading {
            templateCollectionView.isHidden = true
            spinner.isHidden = false
            spinner.startAnimating()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now()+0.3) { [weak self] in
                guard let self = self else {return}
                self.templateCollectionView.isHidden = false
                self.spinner.isHidden = true
                self.spinner.stopAnimating()
            }
        }
        isLoading.toggle()
    }
    
    // 메인 뷰 초기화
    private func setMainView() {
        view.backgroundColor = .systemBackground
    }
    
    // 컬렉션 뷰 레이아웃 초기화
    private func getCollectionViewLayout() -> UICollectionViewFlowLayout {
        let collectionViewLayer = UICollectionViewFlowLayout()
        collectionViewLayer.sectionInset = UIEdgeInsets(top: PaperTemplateSelectLength.sectionTopMargin, left: PaperTemplateSelectLength.sectionLeftMargin, bottom: PaperTemplateSelectLength.sectionBottomMargin, right: PaperTemplateSelectLength.sectionRightMargin)
        collectionViewLayer.minimumInteritemSpacing = PaperTemplateSelectLength.cellHorizontalSpace
        collectionViewLayer.minimumLineSpacing = PaperTemplateSelectLength.cellVerticalSpace
        collectionViewLayer.headerReferenceSize = .init(width: PaperTemplateSelectLength.headerWidth, height: PaperTemplateSelectLength.headerHeight)
        return collectionViewLayer
    }
}

// 컬렉션 뷰에 대한 여러 설정들을 해줌
extension PaperTemplateSelectViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    // 셀 크기
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: PaperTemplateSelectLength.cellWidth, height: PaperTemplateSelectLength.cellHeight)
    }
    // 섹션별 셀 개수
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return isRecentExist && section == 0 ? recentTemplates.count : viewModel.getTemplates().count
    }
    // 섹션의 개수
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return isRecentExist ? 2 : 1
    }
    // 특정 위치의 셀
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PaperTemplateCollectionCell.identifier, for: indexPath) as? PaperTemplateCollectionCell else {return UICollectionViewCell()}
        if isRecentExist && indexPath.section == 0 {
            cell.setCell(template: recentTemplates[indexPath.item].template)
        } else {
            cell.setCell(template: viewModel.getTemplates()[indexPath.item].template)
        }
        
        return cell
    }
    // 특정 위치의 헤더
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            guard let supplementaryView = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: PaperTemplateCollectionHeader.identifier,
                for: indexPath
            ) as? PaperTemplateCollectionHeader else {return UICollectionReusableView()}
            supplementaryView.setHeader(text: isRecentExist && indexPath.section == 0 ? "최근 사용한" : "모두")
            return supplementaryView
        } else {
            return UICollectionReusableView()
        }
    }
    // 특정 셀 눌렀을 떄의 동작
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        // 템플릿을 터치하는 순간 최근 템플릿으로 설정하기 위해 input에 값 설정하기
        if isRecentExist && indexPath.section == 0 {
            navigationController?.pushViewController(PaperSettingViewController(template: recentTemplates[indexPath.item]), animated: true) {
                self.input.send(.newTemplateTap(template: self.recentTemplates[indexPath.item]))
            }
        } else {
            let selectedTemplate = viewModel.getTemplates()[indexPath.item]
            navigationController?.pushViewController(PaperSettingViewController(template: selectedTemplate), animated: true) {
                self.input.send(.newTemplateTap(template: selectedTemplate))
            }
        }
        return true
    }
}

// 스냅킷 설정
extension PaperTemplateSelectViewController {
    private func configure() {
        view.addSubview(templateCollectionView)
        view.addSubview(spinner)
    }
    
    private func setConstraints() {
        templateCollectionView.snp.makeConstraints({ make in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide)
        })
        spinner.snp.makeConstraints({ make in
            make.edges.equalToSuperview()
        })
    }
}

// 최근 사용한 템플릿과 원래 템플릿들을 모두 보여주는 컬렉션 뷰
private class PaperTemplateCollectionView: UICollectionView {}
