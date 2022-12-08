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
    static let userChevronFrameWidth = Int(Double(userInfoStackWidthSuperView) * 0.3 * 0.24)
    static let userChevronWidthHeight = 15
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
        CategoryModel(name: "새로운 보드", icon: "square.and.pencil"),
        CategoryModel(name: "담벼락", icon: "square.grid.2x2"),
        CategoryModel(name: "선물 상자", icon: "giftcard"),
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
    
    private lazy var userNamePhotoStack: UIStackView = {
        let userNamePhotoStack = UIStackView(arrangedSubviews: [userPhoto, userName])
        userNamePhotoStack.axis = .horizontal
        userNamePhotoStack.alignment = .fill
        userNamePhotoStack.distribution = .equalSpacing
        userNamePhotoStack.spacing = Layout.userPhotoToNamePadding
        return userNamePhotoStack
    }()
    
    private let chevronButton: UIButton = {
        let chevronButton = UIButton(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        chevronButton.setImage(UIImage(systemName: "chevron.forward"), for: .normal)
        chevronButton.imageView?.contentMode = .scaleAspectFit
        return chevronButton
    }()
    
    private lazy var userInfoStack: UIStackView = {
        let userInfo = UIStackView(arrangedSubviews: [userNamePhotoStack, chevronButton])
        userInfo.axis = .horizontal
        userInfo.alignment = .center
        userInfo.distribution = .equalSpacing
        userInfo.spacing = 0
        userInfo.setCustomSpacing(10, after: userName)
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
            selector: #selector(changeSecondaryView(notification:)),
            name: Notification.Name.viewChange,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(changeSecondaryView(notification:)),
            name: Notification.Name.viewChangeFromSidebar,
            object: nil
        )

        chevronButton.tapPublisher
            .sink { _ in
                NotificationCenter.default.post(
                    name: Notification.Name.viewChangeFromSidebar,
                    object: nil,
                    userInfo: [NotificationViewKey.view: "프로필"])
            }
            .store(in: &cancellables)
    }
    
    @objc private func didTapUserInfo(_ sender: UITapGestureRecognizer) {
        print("UserInfoTapped!", sender)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setProfileView()
        setupCollectionView()
    }
    
    private func setInitialConfig() {
        view.backgroundColor = .systemGray6
        collectionView.selectItem(at: IndexPath(row: 0, section: 0),
                                  animated: false,
                                  scrollPosition: UICollectionView.ScrollPosition.centeredVertically)
    }
    
    @objc private func changeSecondaryView(notification: Notification) {
        guard let object = notification.userInfo?[NotificationViewKey.view] as? String else { return }
        if object == "담벼락" {
            self.collectionView.selectItem(at: IndexPath(row: 1, section: 0), animated: false, scrollPosition: UICollectionView.ScrollPosition.centeredHorizontally)
        } else if object == "프로필" {
            self.collectionView.selectItem(at: IndexPath(row: 3, section: 0), animated: false, scrollPosition: UICollectionView.ScrollPosition.centeredHorizontally)
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
    
    private func setupCollectionView() {
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
            make.leading.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.trailing.equalTo(view.safeAreaLayoutGuide).inset(16)
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
            state.isSelected || state.isHighlighted ? .systemBackground : .label
        }
        contentConfig.imageProperties.tintColor = state.isSelected || state.isHighlighted ? .white : .tintColor
        
        guard var backgroundConfig = self.backgroundConfiguration?.updated(for: state) else { return }
        backgroundConfig.backgroundColorTransformer = UIConfigurationColorTransformer { _ in
            state.isSelected || state.isHighlighted ? .tintColor : .clear
        }
        
        self.contentConfiguration = contentConfig
        self.backgroundConfiguration = backgroundConfig
    }
}
