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

class AppSettingViewController: UIViewController {
    var dataSource: UICollectionViewDiffableDataSource<Section, ListItem>!
    private var viewModel = AppSettingViewModel()
    
    let colorSelectButton: UISegmentedControl = {
        let colorSelectButton = UISegmentedControl(items: ["Light", "Dark", "Custom"])
        colorSelectButton.backgroundColor = UIColor.systemGray4
        colorSelectButton.tintColor = UIColor.black
        return colorSelectButton
    }()
    
    lazy var collectionView: UICollectionView = {
        var collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: setLayout())
        return collectionView
    }()
    
    let modelObjects = [
        AppSettingCollectionCellModel(title: "색상 테마", symbols: UIView()),
        AppSettingCollectionCellModel(title: "알림", symbols: UIView()),
        AppSettingCollectionCellModel(title: "고객 지원", symbols: UIView()),
        AppSettingCollectionCellModel(title: "정보", symbols: UIView())
    ]
    
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
        let layoutConfig = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        return UICollectionViewCompositionalLayout.list(using: layoutConfig)
    }
    
    private func configureDataSource() {
        let headerCellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, AppSettingCollectionCellModel> {
            (cell, indexPath, headerItem) in
            var content = cell.defaultContentConfiguration()
            content.text = headerItem.title
            cell.contentConfiguration = content
            let headerDisclosureOption = UICellAccessory.OutlineDisclosureOptions(style: .header)
            cell.accessories = [.outlineDisclosure(options: headerDisclosureOption)]
        }
        
        dataSource = UICollectionViewDiffableDataSource<Section, ListItem>(collectionView: collectionView) {
            (collectionView, indexPath, listItem) -> UICollectionViewCell? in
            switch listItem {
            case .header(let headerItem):
                let cell = collectionView.dequeueConfiguredReusableCell(using: headerCellRegistration, for: indexPath, item: headerItem)
                return cell
            }
        }
        var dataSourceSnapshot = NSDiffableDataSourceSnapshot<Section, ListItem>()

        dataSourceSnapshot.appendSections([.main])
        dataSource.apply(dataSourceSnapshot)
        
        var sectionSnapshot = NSDiffableDataSourceSectionSnapshot<ListItem>()

        for headerItem in modelObjects {
            let headerListItem = ListItem.header(headerItem)
            sectionSnapshot.append([headerListItem])
            sectionSnapshot.expand([headerListItem])
        }

        dataSource.apply(sectionSnapshot, to: .main, animatingDifferences: false)
    }
    
    private func setView() {
        view.addSubview(collectionView)
        view.addSubview(colorSelectButton)
        
        collectionView.snp.makeConstraints { make in
            make.top.bottom.leading.trailing.equalToSuperview()
        }
    }
}
