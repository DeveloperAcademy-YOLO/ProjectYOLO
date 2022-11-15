//
//  SideBarViewController.swift
//  RollingPaper
//
//  Created by Kelly Chui on 2022/10/05.
//

import UIKit
import SnapKit
import Combine
import CombineCocoa

final private class Layout {
    static let userPhotoFrameWidthHeight = 44
    static let userNameFontSize: CGFloat = 20
    static let userPhotoToNamePadding: CGFloat = 16
    static let collectionViewCellBackgroundInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 6, trailing: 0)
    static let collectionViewCellimageToTextPadding: CGFloat = 16
    static let collectionViewCellInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
    static let collectionViewHeight: CGFloat = 56
    static let collectionViewCellImageSize = CGSize(width: 25, height: 25)
    static let collectionViewLeadingOffset = 128
    static let collectionViewTrailingOffset = -28
    static let collectionViewToUserInfoStackPadding = 40
    static let userInfoStackRadius: CGFloat = 12
    static let userInfoStackInset = UIEdgeInsets(top: 14, left: 16, bottom: 14, right: 16)
    static let userInfoStackWidthSuperView = -156
    static let userInfoStackLeadingSuperView = 128
    static let userInfoStackTrailingSuperView = -28
    static let userInfoStackTopSafeArea = 40
}

final class SidebarViewController: UIViewController {
    private var dataSource: UICollectionViewDiffableDataSource<SidebarViewModel.SidebarSection, CategoryModel>! = nil
    private var categories: [CategoryModel] = []
    private let viewModel = SidebarViewModel()
    private var cancellables = Set<AnyCancellable>()
    private let sideBarCategories: [CategoryModel] = [
        CategoryModel(name: "페이퍼 템플릿", icon: "doc.on.doc"),
        CategoryModel(name: "페이퍼 보관함", icon: "folder"),
        CategoryModel(name: "설정", icon: "gearshape")
    ]
    
    private let userPhoto: UIImageView = {
        let photo = UIImageView()
        photo.contentMode = UIView.ContentMode.scaleAspectFill
        return photo
    }()
    
    private let userName: UILabel = {
        let name = UILabel()
        name.text = "Guest"
        name.font = UIFont.preferredFont(forTextStyle: .title3)
        name.sizeToFit()
        return name
    }()
    
    private lazy var userInfoStack: UIStackView = {
        let userInfo = UIStackView(arrangedSubviews: [userPhoto, userName])
        userInfo.axis = .horizontal
        userInfo.alignment = .center
        userInfo.distribution = .fillProportionally
        userInfo.spacing = 0
        userInfo.setCustomSpacing(Layout.userPhotoToNamePadding, after: userPhoto)
        return userInfo
    }()
    
    private lazy var collectionView: UICollectionView = {
        var collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: setLayout())
        collectionView.isScrollEnabled = false
        return collectionView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bind()
        configureDataSource()
        setInitialConfig()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(changeSecondaryView(noitificaiton:)),
            name: Notification.Name.viewChange,
            object: nil
        )
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setProfileView()
        setCollectionView()
    }
    
    private func setInitialConfig() {
        view.backgroundColor = .systemGray6
        collectionView.selectItem(at: IndexPath(row: 0, section: 0),
                                  animated: false,
                                  scrollPosition: UICollectionView.ScrollPosition.centeredVertically)
    }
    
    @objc private func changeSecondaryView(noitificaiton: Notification) {
        guard let object = noitificaiton.userInfo?[NotificationViewKey.view] as? String else { return }
        if object == "페이퍼 보관함" {
            self.collectionView.selectItem(at: IndexPath(row: 1, section: 0), animated: false, scrollPosition: UICollectionView.ScrollPosition.centeredHorizontally)
        }
    }
    
    private func bind() {
        viewModel
            .currentUserSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] userModel in
                if let userModel = userModel {
                    self?.userName.text = userModel.name
                } else {
                    self?.userName.text = "Guest"
                }
            }
            .store(in: &cancellables)
        viewModel
            .currentPhotoSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] image in
                if let image = image {
                    self?.userPhoto.image = image
                } else {
                    self?.userPhoto.image = UIImage(systemName: "person.fill")
                }
            }
            .store(in: &cancellables)
    }
    
    private func setLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { section, layoutEnvironment in
            var config = UICollectionLayoutListConfiguration(appearance: .sidebar)
            config.headerMode = .none
            return NSCollectionLayoutSection.list(using: config, layoutEnvironment: layoutEnvironment)
        }
    }
    
    private func configureDataSource() {
        let cellRegistration = UICollectionView.CellRegistration<CategoryCell, CategoryModel> { (cell, indexPath, category) in
            cell.categoryData = [category.name, category.icon]
            var content = cell.defaultContentConfiguration()
            content.image = UIImage(systemName: category.icon)
            content.text = category.name
            content.textProperties.font = UIFont.preferredFont(forTextStyle: .title3)
            content.imageToTextPadding = Layout.collectionViewCellimageToTextPadding
            content.imageProperties.tintColor = .systemGray3
            content.imageProperties.maximumSize = Layout.collectionViewCellImageSize
            content.directionalLayoutMargins = Layout.collectionViewCellInsets
            cell.contentConfiguration = content
        }
        
        dataSource = UICollectionViewDiffableDataSource<SidebarViewModel.SidebarSection, CategoryModel>(collectionView: collectionView) {
            (collectionView: UICollectionView, indexPath: IndexPath, item: CategoryModel) -> CategoryCell? in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
        }
        
        let sections: [SidebarViewModel.SidebarSection] = [.main]
        var snapshot = NSDiffableDataSourceSnapshot<SidebarViewModel.SidebarSection, CategoryModel>()
        snapshot.appendSections(sections)
        dataSource.apply(snapshot, animatingDifferences: false)
        
        for section in sections {
            switch section {
            case .main:
                var sectionSnapshot = NSDiffableDataSourceSectionSnapshot<CategoryModel>()
                sectionSnapshot.append(sideBarCategories)
                dataSource.apply(sectionSnapshot, to: section)
            }
        }
    }
    
    private func setCollectionView() {
        view.addSubview(collectionView)
        collectionView.delegate = self
        collectionView.backgroundColor = .clear
        collectionView.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
            make.top.equalTo(userInfoStack.snp.bottom).offset(Layout.collectionViewToUserInfoStackPadding)
        }
    }
    
    private func setProfileView() {
        view.addSubview(userInfoStack)
        userInfoStack.backgroundColor = .systemBackground
        userInfoStack.layer.cornerRadius = Layout.userInfoStackRadius
        userInfoStack.isLayoutMarginsRelativeArrangement = true
        userInfoStack.layoutMargins = Layout.userInfoStackInset
        userInfoStack.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Layout.userInfoStackLeadingSuperView)
            make.trailing.equalToSuperview().offset(Layout.userInfoStackTrailingSuperView)
            make.height.equalTo(userInfoStack.snp.width).dividedBy(3)
            make.top.equalTo(view.safeAreaLayoutGuide).offset(Layout.userInfoStackTopSafeArea)
        }
        userPhoto.snp.makeConstraints { make in
            make.height.equalTo(userInfoStack.snp.height).offset(-28)
            make.width.equalTo(userPhoto.snp.height)
        }
        userPhoto.layer.cornerRadius = userPhoto.frame.width / 2
        userPhoto.layer.masksToBounds = true
    }
}

extension SidebarViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let category = self.sideBarCategories[indexPath.row]
        NotificationCenter.default.post(
            name: Notification.Name.viewChangeFromSidebar,
            object: nil,
            userInfo: [NotificationViewKey.view: category.name])
    }
}

class CategoryCell: UICollectionViewListCell {
    var categoryData = ["", ""]
    
    override func updateConfiguration(using state: UICellConfigurationState) {
        super.updateConfiguration(using: state)
        guard var contentConfig = self.contentConfiguration?.updated(for: state) as? UIListContentConfiguration else { return }
        contentConfig.textProperties.colorTransformer = UIConfigurationColorTransformer { color in
            state.isSelected || state.isHighlighted ? .black : .black
        }
        contentConfig.image = UIImage(systemName: state.isSelected || state.isHighlighted ? categoryData[1] + ".fill" : categoryData[1])
        contentConfig.imageProperties.tintColor = state.isSelected || state.isHighlighted ? .black : .systemGray3
        guard var backgroundConfig = self.backgroundConfiguration?.updated(for: state) else { return }
        backgroundConfig.backgroundColorTransformer = UIConfigurationColorTransformer { _ in
            state.isSelected || state.isHighlighted ? .white : .clear
        }
        
        self.contentConfiguration = contentConfig
        self.backgroundConfiguration = backgroundConfig
        
    }
    
}
