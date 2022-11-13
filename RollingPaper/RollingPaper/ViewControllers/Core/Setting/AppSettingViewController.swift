//
//  AppSettingViewController.swift
//  RollingPaper
//
//  Created by Kelly Chui on 2022/11/12.
//

import AVFoundation
import Combine
import CombineCocoa
import Foundation
import Photos
import SnapKit
import UIKit

enum Section {
    case main
}

enum ListItem: Hashable {
    case header(AppSettingCollectionCellModel)
}

struct AppSettingCollectionCellModel: Hashable {
    let title: String
    let symbols: UIView
}

struct SFSymbolItem: Hashable {
    let name: String
    let image: UIImage
    
    init(name: String) {
        self.name = name
        self.image = UIImage(systemName: name)!
    }
}

class AppSettingViewController: UIViewController {
    let colorSelectButton: UISegmentedControl = {
        let colorSelectButton = UISegmentedControl(items: ["Light", "Dark", "Custom"])
        colorSelectButton.backgroundColor = UIColor.systemGray4
        colorSelectButton.tintColor = UIColor.black
        return colorSelectButton
    }()
    
    let modelObjects = [
        AppSettingCollectionCellModel(title: "색상 테마", symbols: UIView()),
        AppSettingCollectionCellModel(title: "알림", symbols: UIView()),
        AppSettingCollectionCellModel(title: "고객 지원", symbols: UIView()),
        AppSettingCollectionCellModel(title: "정보", symbols: UIView())
    ]
    
    var collectionView: UICollectionView!
    var dataSource: UICollectionViewDiffableDataSource<Section, ListItem>!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // MARK: Create list layout
        let layoutConfig = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        let listLayout = UICollectionViewCompositionalLayout.list(using: layoutConfig)
        
        // MARK: Configure collection view
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: listLayout)
        view.addSubview(collectionView)
        view.addSubview(colorSelectButton)
        
        // Make collection view take up the entire view
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0.0),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0.0),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0.0),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0.0),
        ])
        
        // MARK: Cell registration
        let headerCellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, AppSettingCollectionCellModel> {
            (cell, indexPath, headerItem) in
            var content = cell.defaultContentConfiguration()
            content.text = headerItem.title
            cell.contentConfiguration = content
            
            // Add outline disclosure accessory
            // With this accessory, the header cell's children will expand / collapse when the header cell is tapped.
            let headerDisclosureOption = UICellAccessory.OutlineDisclosureOptions(style: .header)
            cell.accessories = [.outlineDisclosure(options:headerDisclosureOption)]
        }
        
        let symbolCellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, SFSymbolItem> {
            (cell, indexPath, symbolItem) in
            
            // Set symbolItem's data to cell
            var content = cell.defaultContentConfiguration()
            content.image = symbolItem.image
            content.text = symbolItem.name
            cell.contentConfiguration = content
        }
        
        // MARK: Initialize data source
        dataSource = UICollectionViewDiffableDataSource<Section, ListItem>(collectionView: collectionView) {
            (collectionView, indexPath, listItem) -> UICollectionViewCell? in
            switch listItem {
            case .header(let headerItem):
                let cell = collectionView.dequeueConfiguredReusableCell(using: headerCellRegistration, for: indexPath, item: headerItem)
                return cell
            }
        }
        
        // MARK: Setup snapshots
        var dataSourceSnapshot = NSDiffableDataSourceSnapshot<Section, ListItem>()

        // Create a section in the data source snapshot
        dataSourceSnapshot.appendSections([.main])
        dataSource.apply(dataSourceSnapshot)
        
        // Create a section snapshot for main section
        var sectionSnapshot = NSDiffableDataSourceSectionSnapshot<ListItem>()

        for headerItem in modelObjects {
            // Create a header ListItem & append as parent
            let headerListItem = ListItem.header(headerItem)
            sectionSnapshot.append([headerListItem])
            // Expand this section by default
            sectionSnapshot.expand([headerListItem])
        }

        // Apply section snapshot to main section
        dataSource.apply(sectionSnapshot, to: .main, animatingDifferences: false)
    }
}


/*
final class AppSettingViewController: UIViewController {
    private var dataSource: UICollectionViewDiffableDataSource<Section, ListItem>! = nil
    private let viewModel = AppSettingViewModel()
    private lazy var collectionView: UICollectionView = {
        var collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewCompositionalLayout.list(using: UICollectionLayoutListConfiguration(appearance: .insetGrouped)))
        return collectionView
    }()
    
    let modelData = [
        SettingMainCellModel(title: "1"),
        SettingMainCellModel(title: "2"),
        SettingMainCellModel(title: "3")
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }
    
    private func setLayout() {
        view.addSubview(collectionView)
    }
    
    private func configure() {
        let mainRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, SettingMainCellModel> {
            (cell, indexPath, SettingMainCellModel) in
            
            
            var content = cell.defaultContentConfiguration()
            content.text = SettingMainCellModel.title
            cell.contentConfiguration = content
            
            let headerDisclosureOption = UICellAccessory.OutlineDisclosureOptions(style: .header)
            cell.accessories = [.outlineDisclosure(options:headerDisclosureOption)]
        }
    }
    
    private func configureDataSource() {
        let mainRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, SettingMainCellModel> {
            (cell, indexPath, SettingMainCellModel) in
            
            
            var content = cell.defaultContentConfiguration()
            content.text = SettingMainCellModel.title
            cell.contentConfiguration = content
            
            let headerDisclosureOption = UICellAccessory.OutlineDisclosureOptions(style: .header)
            cell.accessories = [.outlineDisclosure(options:headerDisclosureOption)]
        }
        
        dataSource = UICollectionViewDiffableDataSource<Section, ListItem>(collectionView: collectionView) {
            (collectionView, indexPath, listItem) -> UICollectionViewCell? in
            switch listItem {
            case .main(let mainItem):
                let cell = collectionView.dequeueConfiguredReusableCell(using: mainRegistration, for: indexPath, item: mainItem)
                return cell
            }
        }
        var sectionSnapshot = NSDiffableDataSourceSectionSnapshot<ListItem>()
        
        for
    }
    
}

/*
extension AppSettingViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        <#code#>
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: , for: <#T##IndexPath#>)
    }
}
*/
class SettingCollectionViewCell: UICollectionViewCell {
    override var isSelected: Bool {
        didSet {
            expandCell()
        }
    }
}

class ProfileViewCell: UICollectionViewCell {
    
    private let userPhoto: UIImageView = {
        let photo = UIImageView()
        photo.layer.cornerRadius = photo.frame.width / 2
        photo.layer.masksToBounds = true
        photo.contentMode = UIView.ContentMode.scaleAspectFit
        return photo
    }()
    
    private let userName: UILabel = {
        let name = UILabel()
        name.text = "Guest"
        name.font = UIFont.preferredFont(forTextStyle: .title3)
        name.sizeToFit()
        return name
    }()
    
    private let userEmailAddress: UILabel = {
        let name = UILabel()
        name.text = "dummy@dummy.dummy"
        name.font = UIFont.preferredFont(forTextStyle: .title3)
        name.sizeToFit()
        return name
    }()
}

enum SettingViewSection {
    case main
}

enum ListItem: Hashable {
    case main(SettingMainCellModel)
}

struct SettingMainCellModel: Hashable {
    let title: String
}
*/
