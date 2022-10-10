//
//  TemplateSelectViewController.swift
//  RollingPaper
//
//  Created by 김동락 on 2022/10/05.
//

import UIKit
import SnapKit
import Combine

class TemplateSelectViewController: UIViewController {
    private let viewModel = TemplateSelectViewModel()
    private let input: PassthroughSubject<TemplateSelectViewModel.Input, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    private var recentTemplate: TemplateEnum?
    private var templateCollectionView: CollectionView?
    private var isRecentExist: Bool {
        return recentTemplate == nil ? false : true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setMainView()
        setCollectionView()
        bind()
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
            .sink { [weak self] event in
                guard let self = self else {return}
                switch event {
                case .getRecentTemplateSuccess(let template):
                    self.recentTemplate = template
                case .getRecentTemplateFail:
                    self.recentTemplate = nil
                }
                self.templateCollectionView?.reloadData()
            }
            .store(in: &cancellables)
    }
    
    // 메인 뷰 초기화
    private func setMainView() {
        view.backgroundColor = .white
    }
    
    // 컬렉션 뷰 초기화
    private func setCollectionView() {
        let collectionViewLayer = UICollectionViewFlowLayout()
        collectionViewLayer.sectionInset = UIEdgeInsets(top: 27, left: 50, bottom: 0, right: 50)
        collectionViewLayer.minimumInteritemSpacing = 30
        collectionViewLayer.minimumLineSpacing = 30
        collectionViewLayer.headerReferenceSize = .init(width: 200, height: 90)
        
        templateCollectionView = CollectionView(frame: .zero, collectionViewLayout: collectionViewLayer)
        guard let myCollectionView = templateCollectionView else {return}
        myCollectionView.backgroundColor = .white
        myCollectionView.register(CollectionCell.self, forCellWithReuseIdentifier: CollectionCell.identifier)
        myCollectionView.register(CollectionHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: CollectionHeader.identifier)
        myCollectionView.dataSource = self
        myCollectionView.delegate = self
        
        view.addSubview(myCollectionView)
        myCollectionView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide)
        }
    }
}

// 컬렉션 뷰에 대한 여러 설정들을 해줌
extension TemplateSelectViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    // 셀의 사이즈
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 240, height: 200)
    }
    
    // 섹션별 셀 개수
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if isRecentExist && section == 0 {
            return 1
        } else {
            return viewModel.getTemplates().count
        }
    }
    
    // 섹션의 개수
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if isRecentExist {
            return 2
        } else {
            return 1
        }
    }
    
    // 특정 위치의 셀
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CollectionCell.identifier, for: indexPath) as? CollectionCell else {return UICollectionViewCell()}
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
                withReuseIdentifier: CollectionHeader.identifier,
                for: indexPath
            ) as? CollectionHeader else {return UICollectionReusableView()}
            
            if isRecentExist && indexPath.section == 0 {
                supplementaryView.setHeader(text: "최근 사용한")
            } else {
                supplementaryView.setHeader(text: "모두")
            }
            return supplementaryView
        } else {
            return UICollectionReusableView()
        }
    }
    
    // 특정 셀 눌렀을 떄의 동작
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        // TODO: 해당 템플릿으로 이동하기
        // 템플릿을 터치하는 순간 최근 템플릿으로 설정하기 위해 input에 값 설정하기
        if isRecentExist && indexPath.section == 0 {
            guard let recentTemplate = recentTemplate else {return false}
            input.send(.newTemplateTap(template: recentTemplate))
        } else {
            let selectedTemplate = viewModel.getTemplates()[indexPath.item]
            input.send(.newTemplateTap(template: selectedTemplate))
        }
        return true
    }
}

// 최근 사용한 템플릿과 원래 템플릿들을 모두 보여주는 컬렉션 뷰
private class CollectionView: UICollectionView {}

// 컬렉션 뷰에서 섹션의 제목을 보여주는 뷰
private class CollectionHeader: UICollectionReusableView {
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
        
        title.font = .preferredFont(forTextStyle: .largeTitle)
        title.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(50)
            make.left.equalToSuperview().offset(50)
        }
    }
    
    func setHeader(text: String) {
        title.text = text
    }
}

// 컬렉션 뷰에 들어가는 셀들을 보여주는 뷰
private class CollectionCell: UICollectionViewCell {
    static let identifier = "CollectionCell"
    private let thumbnail = UIView()
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
        addSubview(thumbnail)
        thumbnail.addSubview(imageView)
        thumbnail.addSubview(title)
        
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = 12
        imageView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.equalToSuperview()
            make.width.equalTo(240)
        }
        
        title.font = .preferredFont(forTextStyle: .title3)
        title.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom).offset(10)
            make.centerX.equalTo(imageView)
        }
        
        thumbnail.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    func setCell(template: TemplateModel) {
        imageView.image = template.thumbnail
        title.text = template.templateString
    }
}
