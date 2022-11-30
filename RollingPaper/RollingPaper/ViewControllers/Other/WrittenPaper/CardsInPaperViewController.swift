//
//  CardsInPaperViewController.swift
//  RollingPaper
//
//  Created by SeungHwanKim on 2022/11/26.
//

import Foundation
import Combine
import SnapKit
import UIKit

class CardsInPaperViewController: UICollectionView {
    var viewModel: WrittenPaperViewModel?
    var callingVC: WrittenPaperViewController?
    private let inputToVM: PassthroughSubject<WrittenPaperViewModel.Input, Never> = .init()
    private lazy var cancellables = Set<AnyCancellable>()
    private var timeInterval: Double?
    
    private var refreshController: UIRefreshControl = {
        let control = UIRefreshControl()
        control.attributedTitle = NSAttributedString(string: "데이터를 불러오는 중입니다...")
        
        return control
    }()
    
    init() {
        let deviceWidth = UIScreen.main.bounds.size.width
        let deviceHeight = UIScreen.main.bounds.size.height
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 25, left: 20, bottom: 25, right: 20 )
        layout.itemSize = CGSize(width: (deviceWidth-80)/3, height: ((deviceWidth-120)/3)*0.75)
        layout.minimumInteritemSpacing = 20
        layout.minimumLineSpacing = 20
        super.init(frame: CGRect(x: 0, y: 0, width: deviceWidth, height: deviceHeight), collectionViewLayout: layout)
        bind()
        self.showsVerticalScrollIndicator = false
        self.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "MyCell")
        self.dataSource = self
        self.delegate = self
        self.alwaysBounceVertical = true
        self.addSubview(refreshController)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func bind() {
        refreshController
            .isRefreshingPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.callingVC?.checkTimerBallon()
                self?.reloadData()
                self?.refreshController.endRefreshing()
            }
            .store(in: &cancellables)
    }
    
    private func moveToCardRootView() {
        let isLocalDB: Bool = viewModel?.paperFrom == .fromLocal ? true : false
        //해당 뷰컨이 카드 생성후에 나타났을 때는 네비바가 사라지지 않게하기 위함
        print("isLocalDB: \(isLocalDB)")
        guard let currentPaper = viewModel?.currentPaperPublisher.value else { return }
        guard let callingVC = callingVC else { return }
        callingVC.fromCardView = true
        callingVC.navigationController?.pushViewController(CardRootViewController(viewModel: CardViewModel(), isLocalDB: isLocalDB, currentPaper: currentPaper), animated: true)
    }
}

extension CardsInPaperViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let currentPaper = viewModel?.currentPaperPublisher.value else { return 0 }
        if currentPaper.endTime == currentPaper.date || self.timeInterval ?? 1.0 <= 0.0 {
            return currentPaper.cards.count
        } else {
            return ((currentPaper.cards.count) + 1 )
        }
    }
    //commit collectionView
    func saveCard(_ indexPath: IndexPath) {
        guard let currentPaper = viewModel?.currentPaperPublisher.value else { return }
        let card = currentPaper.cards[indexPath.row - 1]
        
        if let image = NSCacheManager.shared.getImage(name: card.contentURLString) {
            UIImageWriteToSavedPhotosAlbum(image, self, #selector(imageSave(_:didFinishSavingWithError:contextInfo:)), nil)
        }
    }
    
    func shareCard( _ indexPath: IndexPath, _ sender: CGPoint) {
        guard let currentPaper = viewModel?.currentPaperPublisher.value else { return }
        let card = currentPaper.cards[indexPath.row - 1]
        
        if let image = NSCacheManager.shared.getImage(name: card.contentURLString) {
            imageShare(sender, image)
        }
    }
    
    func deleteCard(_ indexPath: IndexPath) {
        guard let viewModel = viewModel else {return}
        guard let currentPaper = viewModel.currentPaperPublisher.value else { return }
        let card = currentPaper.cards[indexPath.row - 1]
        
        if viewModel.isPaperLinkMade { //링크가 만들어진 것이 맞다면 서버에 페이퍼가 저장되어있으므로
            viewModel.deleteCard(card, from: .fromServer)
        } else {
            viewModel.deleteCard(card, from: .fromLocal)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let myCell = collectionView.dequeueReusableCell(withReuseIdentifier: "MyCell", for: indexPath)
        myCell.layer.cornerRadius = 12
        myCell.layer.masksToBounds = true
        guard let currentPaper = viewModel?.currentPaperPublisher.value else { return myCell }
        if viewModel?.paperFrom == .fromLocal {
            if currentPaper.endTime == currentPaper.date || self.timeInterval ?? 1.0 <= 0.0 {
                let card = currentPaper.cards[indexPath.row]
                if let image = NSCacheManager.shared.getImage(name: card.contentURLString) {
                    let imageView = UIImageView(image: image)
                    imageView.layer.masksToBounds = true
                    myCell.addSubview(imageView)
                    imageView.snp.makeConstraints { make in
                        make.top.bottom.leading.trailing.equalTo(myCell)
                    }
                    return myCell
                } else {
                    LocalStorageManager.downloadData(urlString: card.contentURLString)
                        .receive(on: DispatchQueue.main)
                        .sink { completion in
                            switch completion {
                            case .failure(let error): print(error)
                            case .finished: break
                            }
                        } receiveValue: { [weak self] data in
                            if
                                let data = data,
                                let image = UIImage(data: data) {
                                NSCacheManager.shared.setImage(image: image, name: card.contentURLString)
                                let imageView = UIImageView(image: image)
                                imageView.layer.masksToBounds = true
                                myCell.addSubview(imageView)
                                imageView.snp.makeConstraints { make in
                                    make.top.bottom.leading.trailing.equalTo(myCell)
                                }
                            } else {
                                myCell.addSubview(UIImageView(image: UIImage(systemName: "person.circle")))
                            }
                        }
                        .store(in: &cancellables)
                }
            } else {
                if indexPath.row == 0 {
                    let addCardBtn = AddCardViewController()
                    myCell.addSubview(addCardBtn.view)
                } else {
                    guard let currentPaper = viewModel?.currentPaperPublisher.value else { return myCell }
                    let card = currentPaper.cards[indexPath.row-1]
                    if let image = NSCacheManager.shared.getImage(name: card.contentURLString) {
                        let imageView = UIImageView(image: image)
                        imageView.layer.masksToBounds = true
                        myCell.addSubview(imageView)
                        imageView.snp.makeConstraints { make in
                            make.top.bottom.leading.trailing.equalTo(myCell)
                        }
                        return myCell
                    } else {
                        LocalStorageManager.downloadData(urlString: card.contentURLString)
                            .receive(on: DispatchQueue.main)
                            .sink { completion in
                                switch completion {
                                case .failure(let error): print(error)
                                case .finished: break
                                }
                            } receiveValue: { [weak self] data in
                                if
                                    let data = data,
                                    let image = UIImage(data: data) {
                                    NSCacheManager.shared.setImage(image: image, name: card.contentURLString)
                                    let imageView = UIImageView(image: image)
                                    imageView.layer.masksToBounds = true
                                    myCell.addSubview(imageView)
                                    imageView.snp.makeConstraints { make in
                                        make.top.bottom.leading.trailing.equalTo(myCell)
                                    }
                                } else {
                                    myCell.addSubview(UIImageView(image: UIImage(systemName: "person.circle")))
                                }
                            }
                            .store(in: &cancellables)
                    }
                }
            }
            return myCell
        } else {
            if currentPaper.endTime == currentPaper.date || self.timeInterval ?? 1.0 <= 0.0 {
                let card = currentPaper.cards[indexPath.row]
                if let image = NSCacheManager.shared.getImage(name: card.contentURLString) {
                    let imageView = UIImageView(image: image)
                    imageView.layer.masksToBounds = true
                    myCell.addSubview(imageView)
                    imageView.snp.makeConstraints { make in
                        make.top.bottom.leading.trailing.equalTo(myCell)
                    }
                    return myCell
                } else {
                    FirebaseStorageManager.downloadData(urlString: card.contentURLString)
                        .receive(on: DispatchQueue.main)
                        .sink { completion in
                            switch completion {
                            case .failure(let error): print(error)
                            case .finished: break
                            }
                        } receiveValue: { [weak self] data in
                            if
                                let data = data,
                                let image = UIImage(data: data) {
                                NSCacheManager.shared.setImage(image: image, name: card.contentURLString)
                                let imageView = UIImageView(image: image)
                                imageView.layer.masksToBounds = true
                                myCell.addSubview(imageView)
                                imageView.snp.makeConstraints { make in
                                    make.top.bottom.leading.trailing.equalTo(myCell)
                                }
                            } else {
                                myCell.addSubview(UIImageView(image: UIImage(systemName: "person.circle")))
                            }
                        }
                        .store(in: &cancellables)
                }
            } else {
                if indexPath.row == 0 {
                    let addCardBtn = AddCardViewController()
                    myCell.addSubview(addCardBtn.view)
                } else {
                    guard let currentPaper = viewModel?.currentPaperPublisher.value else { return myCell }
                    let card = currentPaper.cards[indexPath.row-1]
                    if let image = NSCacheManager.shared.getImage(name: card.contentURLString) {
                        let imageView = UIImageView(image: image)
                        imageView.layer.masksToBounds = true
                        myCell.addSubview(imageView)
                        imageView.snp.makeConstraints { make in
                            make.top.bottom.leading.trailing.equalTo(myCell)
                        }
                        return myCell
                    } else {
                        FirebaseStorageManager.downloadData(urlString: card.contentURLString)
                            .receive(on: DispatchQueue.main)
                            .sink { completion in
                                switch completion {
                                case .failure(let error): print(error)
                                case .finished: break
                                }
                            } receiveValue: { [weak self] data in
                                if
                                    let data = data,
                                    let image = UIImage(data: data) {
                                    NSCacheManager.shared.setImage(image: image, name: card.contentURLString)
                                    let imageView = UIImageView(image: image)
                                    imageView.layer.masksToBounds = true
                                    myCell.addSubview(imageView)
                                    imageView.snp.makeConstraints { make in
                                        make.top.bottom.leading.trailing.equalTo(myCell)
                                    }
                                } else {
                                    myCell.addSubview(UIImageView(image: UIImage(systemName: "person.circle")))
                                }
                            }
                            .store(in: &cancellables)
                    }
                }
            }
            return myCell
        }
    }
}

extension CardsInPaperViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let currentPaper = viewModel?.currentPaperPublisher.value else { return }
        if currentPaper.endTime == currentPaper.date  || self.timeInterval ?? 1.0 <= 0.0 {
            
            let blurredVC = BlurredViewController()
            blurredVC.viewModel = self.viewModel
            blurredVC.selectedCardIndex = indexPath.row
            
            blurredVC.modalTransitionStyle = .crossDissolve
            blurredVC.modalPresentationStyle = .currentContext
            callingVC?.present(blurredVC, animated: true)
            
            collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        } else {
            if indexPath.row == 0 {
                moveToCardRootView()
            } else {
                let blurredVC = BlurredViewController()
                blurredVC.viewModel = self.viewModel
                blurredVC.selectedCardIndex = indexPath.row - 1
                
                blurredVC.modalTransitionStyle = .crossDissolve
                blurredVC.modalPresentationStyle = .currentContext
                callingVC?.present(blurredVC, animated: true)

                collectionView.scrollToItem(at: [0, indexPath.row - 1], at: .centeredHorizontally, animated: true)
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemsAt indexPaths: [IndexPath], point: CGPoint) -> UIContextMenuConfiguration? {
        guard let indexPath = indexPaths.first else { return nil }
        if indexPath.row == 0 {
            return nil
        }
        let config = UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            
            let save = UIAction(
                title: "사진 앱에 저장하기",
                image: UIImage(systemName: "photo.on.rectangle"),
                identifier: nil,
                discoverabilityTitle: nil,
                state: .off
            ) { [weak self] _ in
                self?.saveCard(indexPath)
            }
            
            let share = UIAction(
                title: "공유하기",
                image: UIImage(systemName: "square.and.arrow.up"),
                identifier: nil,
                discoverabilityTitle: nil,
                state: .off
            ) { [weak self] _ in
                self?.shareCard(indexPath, point)
            }
            
            let delete = UIAction(
                title: "삭제하기",
                image: UIImage(systemName: "trash"),
                identifier: nil,
                discoverabilityTitle: nil,
                attributes: .destructive,
                state: .off
            ) { [weak self] _ in
                self?.deleteCard(indexPath)
            }
            
            return UIMenu(
                image: nil,
                identifier: nil,
                options: .singleSelection,
                children: [save, share, delete]
            )
        }
        return config
    }
    
    @objc func imageSave(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            let alert = UIAlertController(title: "Save error", message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            callingVC?.present(alert, animated: true)
        } else {
            let alert = UIAlertController(title: "Saved!", message: "이미지가 사진첩에 저장이 되었습니다", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            callingVC?.present(alert, animated: true)
        } //실기계에서는 잘 작동하나 시뮬레이터에서 쓰면 앱이 죽습니다
    }
    
    private func imageShare(_ sender: CGPoint, _ image: UIImage) {
        let shareSheetVC = UIActivityViewController(
            activityItems:
                [
                    image
                ], applicationActivities: nil)
        
        // exclude some activity types from the list (optional)
        shareSheetVC.excludedActivityTypes = [
            UIActivity.ActivityType.message,
            UIActivity.ActivityType.saveToCameraRoll,
            UIActivity.ActivityType.assignToContact,
            UIActivity.ActivityType.copyToPasteboard,
            UIActivity.ActivityType.print,
            UIActivity.ActivityType.addToReadingList
        ]
        
        // present the view controller
        callingVC?.present(shareSheetVC, animated: true, completion: nil)
        
        let rect: CGRect = .init(origin: sender, size: CGSize(width: 200, height: 200))
        
        shareSheetVC.popoverPresentationController?.sourceView = callingVC?.view
        shareSheetVC.popoverPresentationController?.sourceRect = rect
    }
}
