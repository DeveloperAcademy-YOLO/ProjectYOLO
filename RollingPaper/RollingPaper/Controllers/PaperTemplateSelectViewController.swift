//
//  TemplateSelectViewController.swift
//  RollingPaper
//
//  Created by 김동락 on 2022/10/05.
//

import UIKit
import SnapKit
import Combine

private class Length {
    static let templateThumbnailWidth: CGFloat = (UIScreen.main.bounds.width*0.75-(24*5))/4
    static let templateThumbnailHeight: CGFloat = templateThumbnailWidth*0.75
    static let templateThumbnailCornerRadius: CGFloat = 12
    static let templateTitleHeight: CGFloat = 19
    static let templateTitleTopMargin: CGFloat = 16
    static let cellWidth: CGFloat = templateThumbnailWidth
    static let cellHeight: CGFloat = templateThumbnailHeight + templateTitleTopMargin + templateTitleHeight
    static let cellHorizontalSpace: CGFloat = 20
    static let cellVerticalSpace: CGFloat = 28
    static let sectionTopMargin: CGFloat = 28
    static let sectionBottomMargin: CGFloat = 48
    static let sectionRightMargin: CGFloat = 28
    static let sectionLeftMargin: CGFloat = 28
    static let headerWidth: CGFloat = 116
    static let headerHeight: CGFloat = 29
    static let headerLeftMargin: CGFloat = 34
}

class PaperTemplateSelectViewController: UIViewController {
    private let splitViewManager = SplitViewManager.shared
    private let viewModel = PaperTemplateSelectViewModel()
    private let input: PassthroughSubject<PaperTemplateSelectViewModel.Input, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    private var recentTemplate: TemplateEnum?
    private var templateCollectionView: PaperTemplateCollectionView?
    private var isRecentExist: Bool {
        return recentTemplate == nil ? false : true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.splitViewController?.show(.primary)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setMainView()
        setCollectionView()
        bind()
        splitViewBind()
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
                case .getRecentTemplateSuccess(let template):
                    self.recentTemplate = template
                case .getRecentTemplateFail:
                    self.recentTemplate = nil
                }
                self.templateCollectionView?.reloadData()
            })
            .store(in: &cancellables)
    }
    
    // splitView에 대한 어떤 행동을 받고 그에 따라 어떤 행동을 할지 정하기
    private func splitViewBind() {
        let output = splitViewManager.getOutput()
        output
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { event in
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
                self.templateCollectionView?.snp.updateConstraints({ make in
                    make.leading.equalToSuperview().offset(extraLeftMargin)
                    make.trailing.equalToSuperview().offset(extraRightMargin)
                })
                UIView.animate(withDuration: 0.5, delay: 0, animations: {
                    self.view.layoutIfNeeded()
                })
            })
            .store(in: &cancellables)
    }
    
    // 메인 뷰 초기화
    private func setMainView() {
        view.backgroundColor = .white
    }
    
    // 컬렉션 뷰 레이아웃 초기화
    private func setCollectionViewLayout() {
        let collectionViewLayer = UICollectionViewFlowLayout()
        collectionViewLayer.sectionInset = UIEdgeInsets(top: Length.sectionTopMargin, left: Length.sectionLeftMargin, bottom: Length.sectionBottomMargin, right: Length.sectionRightMargin)
        collectionViewLayer.minimumInteritemSpacing = Length.cellHorizontalSpace
        collectionViewLayer.minimumLineSpacing = Length.cellVerticalSpace
        collectionViewLayer.headerReferenceSize = .init(width: Length.headerWidth, height: Length.headerHeight)
        self.templateCollectionView?.setCollectionViewLayout(collectionViewLayer, animated: true)
    }
    
    // 컬렉션 뷰 초기화
    private func setCollectionView() {
        templateCollectionView = PaperTemplateCollectionView(frame: .zero, collectionViewLayout: .init())
        setCollectionViewLayout()
        
        guard let collectionView = templateCollectionView else {return}
        collectionView.backgroundColor = .systemBackground
        collectionView.alwaysBounceVertical = true
        collectionView.register(PaperTemplateCollectionCell.self, forCellWithReuseIdentifier: PaperTemplateCollectionCell.identifier)
        collectionView.register(PaperTemplateCollectionHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: PaperTemplateCollectionHeader.identifier)
        collectionView.dataSource = self
        collectionView.delegate = self
        
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints({ make in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide)
        })
    }
}

// 컬렉션 뷰에 대한 여러 설정들을 해줌
extension PaperTemplateSelectViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    // 셀 크기
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: Length.cellWidth, height: Length.cellHeight)
    }
    
    // 섹션별 셀 개수
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return isRecentExist && section == 0 ? 1 : viewModel.getTemplates().count
    }
    
    // 섹션의 개수
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return isRecentExist ? 2 : 1
    }
    
    // 특정 위치의 셀
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PaperTemplateCollectionCell.identifier, for: indexPath) as? PaperTemplateCollectionCell else {return UICollectionViewCell()}
        if isRecentExist && indexPath.section == 0 {
            guard let recentTemplate = recentTemplate?.template else {return UICollectionViewCell()}
            cell.setCell(template: recentTemplate)
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
            guard let recentTemplate = recentTemplate else {return false}
            navigationController?.pushViewController(PaperSettingViewController(template: recentTemplate), animated: true) {
                self.input.send(.newTemplateTap(template: recentTemplate))
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

// 최근 사용한 템플릿과 원래 템플릿들을 모두 보여주는 컬렉션 뷰
private class PaperTemplateCollectionView: UICollectionView {}

// 컬렉션 뷰에서 섹션의 제목을 보여주는 뷰
private class PaperTemplateCollectionHeader: UICollectionReusableView {
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

// 컬렉션 뷰에 들어가는 셀들을 보여주는 뷰
private class PaperTemplateCollectionCell: UICollectionViewCell {
    static let identifier = "CollectionCell"
    private let cell = UIStackView()
    private let title = UILabel()
    private let imageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configure() {
        addSubview(cell)
        cell.addArrangedSubview(imageView)
        cell.addArrangedSubview(title)
        
        cell.spacing = Length.templateTitleTopMargin
        cell.axis = .vertical
        cell.snp.makeConstraints({ make in
            make.edges.equalToSuperview()
        })
        
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = Length.templateThumbnailCornerRadius
        imageView.snp.makeConstraints({ make in
            make.top.equalToSuperview()
            make.leading.equalToSuperview()
            make.width.equalTo(Length.templateThumbnailWidth)
            make.height.equalTo(Length.templateThumbnailHeight)
        })
        
        title.font = .preferredFont(forTextStyle: .body)
        title.textColor = UIColor(rgb: 0x808080)
        title.textAlignment = .center
        title.snp.makeConstraints({ make in
            make.centerX.equalTo(imageView)
            make.width.equalToSuperview()
        })
    }
    
    func setCell(template: TemplateModel) {
        imageView.image = template.thumbnail
        title.text = template.templateString
    }
}
