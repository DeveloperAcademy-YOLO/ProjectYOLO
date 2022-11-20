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

final class AppSettingViewController: UIViewController {
    private var viewModel = AppSettingViewModel()
    private var dataSource: UICollectionViewDiffableDataSource<AppSettingViewModel.Section, AppSettingSectionModel>! = nil
    
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
    
    private let chevronButton: UIButton = {
        let chevronButton = UIButton(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        chevronButton.setImage(UIImage(systemName: "chevron.forward"), for: .normal)
        return chevronButton
    }()
    
    let colorSelectButton: UISegmentedControl = {
        let colorSelectButton = UISegmentedControl(items: ["Light", "Dark", "Custom"])
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
        setView()
    }
    
    private func setupInitialConfig() {
        view.backgroundColor = .systemGray6
    }
    
    private func bind() {
        // bind()
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
            cell.accessories = [.customView(configuration: self.colorSelectConfiguration())]
            case [0, 1]:
                cell.accessories = [.customView(configuration: self.toggleSwitchConfiguration())]
            case [1, 0]:
                cell.accessories = [.outlineDisclosure(options: headerDisclosureOption)]
            case [1, 1]:
                cell.accessories = [.disclosureIndicator()]
            default:
                break
            }
            content.text = item.title
            cell.contentConfiguration = content
        }

        dataSource = UICollectionViewDiffableDataSource<AppSettingViewModel.Section, AppSettingSectionModel>(collectionView: collectionView) { (collectionView: UICollectionView, indexPath: IndexPath, item: AppSettingSectionModel) -> UICollectionViewCell? in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
        }

        let sections: [AppSettingViewModel.Section] = [.section1, .section2]
        var snapshot = NSDiffableDataSourceSnapshot<AppSettingViewModel.Section, AppSettingSectionModel>()
        snapshot.appendSections(sections)
        dataSource.apply(snapshot, animatingDifferences: false)

        for section in sections {
            switch section {
            case .section1:
                var sectionSnapshot = NSDiffableDataSourceSectionSnapshot<AppSettingSectionModel>()
                sectionSnapshot.append(viewModel.sectionData1)
                dataSource.apply(sectionSnapshot, to: section)
            case .section2:
                var sectionSnapshot = NSDiffableDataSourceSectionSnapshot<AppSettingSectionModel>()
                sectionSnapshot.append(viewModel.sectionData2)
                dataSource.apply(sectionSnapshot, to: section)
            }
        }
    }
    
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
    
    @objc private func toggleSwitch(sender: UISwitch) {
        if sender.isOn {
            print("Expansion")
        } else {
            print("Collapse")
        }
    }
    
    private func setView() {
        view.addSubview(collectionView)
        
        collectionView.snp.makeConstraints { make in
            make.top.bottom.leading.trailing.equalToSuperview()
        }
    }
}

class SettingContentCell: UICollectionViewListCell {
    
}

class LocalPushContentView: UIView, UIContentView {
    var configuration: UIContentConfiguration
    
    init(configuration: UIContentConfiguration) {
        self.configuration = configuration
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SelectedColorContentView: UIView, UIContentView {
    var configuration: UIContentConfiguration
    init(configuration: UIContentConfiguration) {
        self.configuration = configuration
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class InformationContentView: UIView, UIContentView {
    var configuration: UIContentConfiguration
    init(configuration: UIContentConfiguration) {
        self.configuration = configuration
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
