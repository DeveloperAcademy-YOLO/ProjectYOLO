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
        view.backgroundColor = .white
        setCollectionView()
    }
    
    /// CollectionView 초기화
    private func setCollectionView() {
        let collectionViewLayer = UICollectionViewFlowLayout()
        collectionViewLayer.sectionInset = UIEdgeInsets.zero
        collectionViewLayer.minimumInteritemSpacing = 30
        collectionViewLayer.minimumLineSpacing = 30
        collectionViewLayer.headerReferenceSize = .init(width: 200, height: 50)
        
        let myCollectionView = MyCollectionView(frame: .zero, collectionViewLayout: collectionViewLayer)
        myCollectionView.backgroundColor = .secondarySystemBackground
        
        myCollectionView.register(MyCollectionViewCell.self, forCellWithReuseIdentifier: MyCollectionViewCell.id)
        myCollectionView.register(
            CollectionHeaderView.self,
          forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
          withReuseIdentifier: CollectionHeaderView.id
        )
        
        myCollectionView.dataSource = self
        myCollectionView.delegate = self
        
        view.addSubview(myCollectionView)
        
        myCollectionView.snp.makeConstraints { make in
            make.left.right.top.bottom.equalToSuperview().offset(50)
        }
    }
}

extension TemplateSelectViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    /// sizeForItemAt
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 240, height: 200)
    }
    
    /// numberOfItemsInSection
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else {
            return viewModel.getTemplates().count
        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    /// cellForItemAt
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MyCollectionViewCell.id, for: indexPath) as? MyCollectionViewCell
        
        var currentTemplate: TemplateModel
        if indexPath.section == 0 {
            currentTemplate = viewModel.getRecentTemplate()!.template
        } else {
            currentTemplate = viewModel.getTemplates()[indexPath.item].template
        }
        cell?.imageView.image = currentTemplate.thumbnail
        cell?.title.text = currentTemplate.templateString
        
        return cell!
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let supplementaryView = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: CollectionHeaderView.id,
                for: indexPath
            ) as? CollectionHeaderView
            if indexPath.section == 0 {
                supplementaryView?.prepare(title: "최근 사용한")
            } else {
                supplementaryView?.prepare(title: "모두")
            }
            return supplementaryView!
        } else {
            return UICollectionReusableView()
        }
    }
}

class MyCollectionViewCell: UICollectionViewCell {
    
    static var id: String {
        return NSStringFromClass(Self.self).components(separatedBy: ".").last!
    }
    
    let thumbnail = UIView()
    let title = UILabel()
    let imageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder: NSCoder) {
        fatalError("Not implemented required init?(coder: NSCoder)")
    }
    
    private func configure() {
        contentView.addSubview(thumbnail)
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
            make.top.bottom.left.right.equalToSuperview()
        }
    }
    
}

class MyCollectionView: UICollectionView {
    // Nothing todo
}

class CollectionHeaderView: UICollectionReusableView {
    static let id = "CollectionHeaderView"
    private let title = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(title)
        title.font = .systemFont(ofSize: 32)
        title.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func prepareForReuse() {
        super.prepareForReuse()
        self.prepare(title: nil)
    }
    
    func prepare(title: String?) {
        self.title.text = title
    }
}
