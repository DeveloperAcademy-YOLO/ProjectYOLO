//
//  TemplateSelectViewController.swift
//  RollingPaper
//
//  Created by 김동락 on 2022/10/05.
//

import UIKit
import SnapKit

class TemplateSelectViewController: UIViewController {
    private let viewModel = TemplateSelectViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setMainView()
        setCollectionView()
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
        
        let myCollectionView = CollectionView(frame: .zero, collectionViewLayout: collectionViewLayer)
        myCollectionView.backgroundColor = .white
        myCollectionView.register(CollectionCell.self, forCellWithReuseIdentifier: CollectionCell.id)
        myCollectionView.register(CollectionHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: CollectionHeader.id)
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
        if viewModel.isRecentExist && section == 0 {
            return 1
        } else {
            return viewModel.getTemplates().count
        }
    }
    
    // 섹션의 개수
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if viewModel.isRecentExist {
            return 2
        } else {
            return 1
        }
    }
    
    // 특정 위치의 셀
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CollectionCell.id, for: indexPath) as? CollectionCell else {return UICollectionViewCell()}

        if viewModel.isRecentExist && indexPath.section == 0 {
            guard let recentTemplate = viewModel.getRecentTemplate()?.template else {return UICollectionViewCell()}
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
                withReuseIdentifier: CollectionHeader.id,
                for: indexPath
            ) as? CollectionHeader else {return UICollectionReusableView()}
            
            if viewModel.isRecentExist && indexPath.section == 0 {
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
        if viewModel.isRecentExist && indexPath.section == 0 {
            guard let selectedTemplate = viewModel.getRecentTemplate()?.template else {return false}
            print(selectedTemplate.templateString)
        } else {
            let selectedTemplate = viewModel.getTemplates()[indexPath.item].template
            print(selectedTemplate.templateString)
        }
        return true
    }
}

// 최근 사용한 템플릿과 원래 템플릿들을 모두 보여주는 컬렉션 뷰
private class CollectionView: UICollectionView {}

// 컬렉션 뷰에서 섹션의 제목을 보여주는 뷰
private class CollectionHeader: UICollectionReusableView {
    static let id = "CollectionHeader"
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
        
        title.font = .systemFont(ofSize: 32)
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
    static let id = "CollectionCell"
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
        
        title.font = .systemFont(ofSize: 20)
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
