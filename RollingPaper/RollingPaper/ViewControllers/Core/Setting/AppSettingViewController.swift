//
//  AppSettingViewController.swift
//  RollingPaper
//
//  Created by Kelly Chui on 2022/11/12.
//

import Combine
import CombineCocoa
import Foundation
import SnapKit
import UIKit

final class AppSettingViewController: UIViewController, UICollectionViewDelegate {
    private var viewModel = AppSettingViewModel()
    private var cancellables = Set<AnyCancellable>()
    private var dataSource: UICollectionViewDiffableDataSource<AppSettingViewModel.Section, ListItem>! = nil
    
    @objc private func tapUserProfile() {
        navigationController?.pushViewController(SettingScreenViewController(), animated: true)
    }
    
    private let userPhoto: UIImageView = {
        let photo = UIImageView()
        photo.contentMode = UIView.ContentMode.scaleAspectFill
        return photo
    }()
    
    private let userName: UILabel = {
        let name = UILabel()
        name.text = "Guest"
        name.font = UIFont.preferredFont(forTextStyle: .title1)
        name.sizeToFit()
        return name
    }()
    
    private let userMail: UILabel = {
        let userMail = UILabel()
        userMail.text = "Guest@Email.com"
        userMail.font = UIFont.preferredFont(forTextStyle: .subheadline)
        userMail.sizeToFit()
        return userMail
    }()
    
    private lazy var userNameStack: UIStackView = {
        let userNameStack = UIStackView(arrangedSubviews: [userName, userMail])
        userNameStack.axis = .vertical
        userNameStack.alignment = .leading
        userNameStack.distribution = .equalCentering
        return userNameStack
    }()
    
    private lazy var userNamePhotoStack: UIStackView = {
        let userNamePhotoStack = UIStackView(arrangedSubviews: [userPhoto, userNameStack])
        userNamePhotoStack.axis = .horizontal
        userNamePhotoStack.alignment = .center
        userNamePhotoStack.distribution = .equalSpacing
        userNamePhotoStack.spacing = 16
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
    
    lazy var colorSelectAccessory = UICellAccessory.CustomViewConfiguration(
        customView: colorSelectButton,
        placement: .trailing(),
        isHidden: false,
        reservedLayoutWidth: .actual,
        maintainsFixedSize: true
    )
    
    let colorSelectButton: UISegmentedControl = {
        let colorSelectButton = UISegmentedControl(items: ["Light", "Dark", "System"])
        colorSelectButton.backgroundColor = UIColor.systemGray4
        colorSelectButton.tintColor = UIColor.black
        return colorSelectButton
    }()
    
    lazy var collectionView: UICollectionView = {
        var collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: setLayout())
        collectionView.isScrollEnabled = false
        return collectionView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bind()
        setupInitialConfig()
        configureDataSource()
        setupView()
        
        switch traitCollection.userInterfaceStyle {
        case .light, .unspecified:
            colorSelectButton.selectedSegmentIndex = 0
        case .dark:
            colorSelectButton.selectedSegmentIndex = 1
        }
        
        colorSelectButton.addTarget(self, action: #selector(didChangeValue(segment: )), for: .valueChanged)
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapUserProfile))
        userInfoStack.addGestureRecognizer(tap)
    }
    
    @objc private func didChangeValue(segment: UISegmentedControl) {
        if segment.selectedSegmentIndex == 0 {
            view.window?.overrideUserInterfaceStyle = .light
        } else if segment.selectedSegmentIndex == 1 {
            view.window?.overrideUserInterfaceStyle = .dark
        } else { // TODO: 수정필요
            switch traitCollection.userInterfaceStyle {
            case .light, .unspecified:
                view.window?.overrideUserInterfaceStyle = .dark
            case .dark:
                view.window?.overrideUserInterfaceStyle = .light
            }
        }
    }
    
    private func setupInitialConfig() {
        view.backgroundColor = .systemGray6
    }
    
    private func bind() {
        viewModel
            .currentUserSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] userModel in
                if let userModel = userModel {
                    print("aaa bind")
                    self?.userName.text = userModel.name
                    self?.userMail.text = userModel.email
                } else {
                    print("aaa bind")
                    self?.userName.text = "Guest"
                    self?.userMail.text = "Your@Email.signin"
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
        let layout = UICollectionViewCompositionalLayout { _, layoutEnvironment in
            var config = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
            config.headerMode = .none
            return NSCollectionLayoutSection.list(using: config, layoutEnvironment: layoutEnvironment)
        }
        return layout
    }
    
    private func configureDataSource() {
        
        let cellRegistration = UICollectionView.CellRegistration<SettingContentCell, AppSettingSectionModel> { (cell, indexPath, item) in
            var content = cell.defaultContentConfiguration()
            var headerDisclosureOption = UICellAccessory.OutlineDisclosureOptions(style: .header)
            headerDisclosureOption.tintColor = .black
            
            switch indexPath {
            case [0, 0]:
                cell.accessories = [.customView(configuration: self.colorSelectAccessory)]
            case [0, 1]:
                cell.accessories = [.customView(configuration: self.toggleSwitchConfiguration())]
            case [1, 0]:
                let headerDisclosureOption = UICellAccessory.OutlineDisclosureOptions(style: .header)
                cell.accessories = [.outlineDisclosure(options: headerDisclosureOption)]
            default:
                break
            }
            content.text = item.title
            cell.contentConfiguration = content
            
        }
        
        let subCellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, AppSettingSectionSubCellModel> {
            (cell, indexPath, subCellItem) in
            var content = cell.defaultContentConfiguration()
            content.image = subCellItem.icon
            content.text = subCellItem.title
            cell.accessories = indexPath == [1, 1] ? [.label(text: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "_") ] : []
            cell.contentConfiguration = content
        }

        dataSource = UICollectionViewDiffableDataSource<AppSettingViewModel.Section, ListItem>(collectionView: collectionView) { (collectionView: UICollectionView, indexPath: IndexPath, item: ListItem) -> UICollectionViewCell? in
            
            switch item {
            case .header(let headerItem):
                return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: headerItem)
            case .subCell(let subCellItem):
                return collectionView.dequeueConfiguredReusableCell(using: subCellRegistration, for: indexPath, item: subCellItem)
            }
        }

        let sections: [AppSettingViewModel.Section] = [.section1, .section2]
        
        var snapshot = NSDiffableDataSourceSnapshot<AppSettingViewModel.Section, ListItem>()
        snapshot.appendSections(sections)
        dataSource.apply(snapshot)
        
        applySnapshot(sectionData: viewModel.sectionData1, section: .section1)
        applySnapshot(sectionData: viewModel.sectionData2, section: .section2)
    }
    
    private func applySnapshot(sectionData: [AppSettingSectionModel], section: AppSettingViewModel.Section) {
        var sectionSnapshot = NSDiffableDataSourceSectionSnapshot<ListItem>()
        
        for headerItem in sectionData {

            let headerListItem = ListItem.header(headerItem)
            sectionSnapshot.append([headerListItem])
            
            let subCellListItemArray = headerItem.subCells?.map { ListItem.subCell($0) }
            if let subCellListItemArray = subCellListItemArray {
                sectionSnapshot.append(subCellListItemArray, to: headerListItem)
            }
        }
        dataSource.apply(sectionSnapshot, to: section, animatingDifferences: true)
    }
    
    @objc private func toggleSwitch(sender: UISwitch) {
        if sender.isOn {
            UIApplication.shared.registerForRemoteNotifications()
        } else {
            UIApplication.shared.unregisterForRemoteNotifications()
        }
    }
    
    private func setupView() {
        view.addSubview(userInfoStack)
        userInfoStack.backgroundColor = .systemBackground
        userInfoStack.layer.cornerRadius = 12
        // userInfoStack.layer.borderWidth =
        // userInfoStack.layer.borderColor = UIColor.black.cgColor
        view.addSubview(collectionView)
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        
        userInfoStack.snp.makeConstraints { make in
            make.leading.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.trailing.equalTo(view.safeAreaLayoutGuide).inset(16)
            make.height.equalTo(150)
            make.top.equalTo(view.safeAreaLayoutGuide)
        }
        
        userPhoto.snp.makeConstraints { make in
            make.height.equalTo(userInfoStack.snp.height).inset(10)
            make.width.equalTo(userPhoto.snp.height)
        }
        
        collectionView.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
            make.top.equalTo(userInfoStack.snp.bottom)
        }
        
        userNameStack.layoutMargins = UIEdgeInsets(top: 50, left: 0, bottom: 50, right: 0)
    }
}

extension AppSettingViewController {
    private func toggleSwitchConfiguration() -> UICellAccessory.CustomViewConfiguration {
        lazy var toggleSwitch: UISwitch = {
            let toggleSwitch = UISwitch(frame: .zero)
            toggleSwitch.isOn = false
            toggleSwitch.addTarget(self, action: #selector(toggleSwitch(sender: )), for: .valueChanged)
            return toggleSwitch
        }()
        
        lazy var toggleAccessory = UICellAccessory.CustomViewConfiguration(
            customView: toggleSwitch,
            placement: .trailing(),
            isHidden: false
        )
        
        return toggleAccessory
    }
    
    private func colorSelectConfiguration() -> UICellAccessory.CustomViewConfiguration {
        let colorSelectButton: UISegmentedControl = {
            let colorSelectButton = UISegmentedControl(items: ["Light", "Dark", "Custom"])
            colorSelectButton.backgroundColor = UIColor.systemGray4
            colorSelectButton.tintColor = UIColor.black
            return colorSelectButton
        }()
        
        lazy var colorSelectAccessory = UICellAccessory.CustomViewConfiguration(
            customView: colorSelectButton,
            placement: .trailing(),
            isHidden: false,
            reservedLayoutWidth: .actual,
            maintainsFixedSize: true
        )
        
        return colorSelectAccessory
    }
}

class SettingContentCell: UICollectionViewListCell {
    override func updateConfiguration(using state: UICellConfigurationState) {
        super.updateConfiguration(using: state)
        
        guard var backgroundConfig = self.backgroundConfiguration?.updated(for: state) else { return }
        backgroundConfig.backgroundColorTransformer = UIConfigurationColorTransformer { _ in
            state.isSelected || state.isHighlighted ? .systemBackground : .systemBackground
        }

        self.backgroundConfiguration = backgroundConfig
    }
}
