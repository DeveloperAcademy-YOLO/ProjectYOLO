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

final class AppSettingViewController: UIViewController {
    private var viewModel = AppSettingViewModel()
    private var dataSource: UICollectionViewDiffableDataSource<AppSettingViewModel.Section, AppSettingSectionModel>! = nil
    
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
        
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, AppSettingSectionModel> { (cell, indexPath, item) in
            var content = cell.defaultContentConfiguration()
            content.text = item.title
            cell.contentConfiguration = content
            cell.accessories = []
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
    
    private func setView() {
        view.addSubview(collectionView)
        // view.addSubview(colorSelectButton)
        
        collectionView.snp.makeConstraints { make in
            make.top.bottom.leading.trailing.equalToSuperview()
        }
    }
}

class LocalPushCell: UICollectionViewListCell {
    // LocalPushCell (토글)
}

class LocalPushContentView: UIView, UIContentView {
    // localPush 내부 뷰
}

class SelectedColorContentView: UIView, UIContentView {
    // SelectedColor 내부 뷰
}

class InformationContentView: UIView, UIContentView {
    // InformationContent 내부 뷰
}

