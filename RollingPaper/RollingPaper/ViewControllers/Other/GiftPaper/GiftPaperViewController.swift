//
//  GiftPaperViewController.swift
//  RollingPaper
//
//  Created by Junyeong Park on 2022/11/15.
//

import UIKit
import Combine
import SnapKit

class GiftPaperViewController: UIViewController {
    
    private var viewModel: GiftPaperViewModel = GiftPaperViewModel()
    private let authManager: AuthManager = FirebaseAuthManager.shared
    private lazy var cancellables = Set<AnyCancellable>()
    
    private let deviceWidth = UIScreen.main.bounds.size.width
    private let deviceHeight = UIScreen.main.bounds.size.height
    
    lazy var leftButton: UIBarButtonItem = {
        let customBackBtnImage = UIImage(systemName: "chevron.backward")?.withTintColor(UIColor.label ?? UIColor(red: 128, green: 128, blue: 128), renderingMode: .alwaysOriginal)
        let customBackBtn = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 23))
        customBackBtn.setTitle("선물 상자", for: .normal)
        customBackBtn.titleLabel?.font = UIFont.systemFont(ofSize: 20)
        customBackBtn.setTitleColor(.label, for: .normal)
        customBackBtn.setImage(customBackBtnImage, for: .normal)
        customBackBtn.addLeftPadding(5)
        customBackBtn.addTarget(self, action: #selector(cancelBtnPressed(_:)), for: .touchUpInside)
        let button = UIBarButtonItem(customView: customBackBtn)
        return button
    }()
    
    lazy private var giftImage: UIImageView = {
        let giftImage = UIImageView()
        giftImage.image = UIImage(systemName: "giftcard.fill")?.resized(to: CGSize(width: 32, height: 22))
        giftImage.tintColor = .label
        giftImage.contentMode = .scaleAspectFit
        return giftImage
    }()
    
    lazy private var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.frame = CGRect(x: 0, y: 0, width: 400, height: 36)
        titleLabel.textAlignment = .center
        titleLabel.text = "선물 받은 보드"
        titleLabel.font = UIFont.preferredFont(for: UIFont.TextStyle.title3, weight: UIFont.Weight.bold)
        titleLabel.numberOfLines = 1
        return titleLabel
    }()
    
    lazy private var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = NSLayoutConstraint.Axis.horizontal
        stackView.distribution = UIStackView.Distribution.equalSpacing
        stackView.addArrangedSubview(self.giftImage)
        stackView.addArrangedSubview(self.titleLabel)
        return stackView
    }()
    
    private lazy var cardsList: UICollectionView = {
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 25, left: 20, bottom: 25, right: 20 )
        layout.itemSize = CGSize(width: (deviceWidth-80)/3, height: ((deviceWidth-120)/3)*0.75)
        layout.minimumInteritemSpacing = 20
        layout.minimumLineSpacing = 20
        
        cardsList = UICollectionView(frame: CGRect(x: 0, y: 0, width: deviceWidth, height: deviceHeight), collectionViewLayout: layout)
        cardsList.center.x = view.center.x
        cardsList.showsVerticalScrollIndicator = false
        cardsList.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "MyCell")
        cardsList.dataSource = self
        cardsList.delegate = self
        cardsList.alwaysBounceVertical = true
        
        return cardsList
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationItem.titleView = stackView
        stackViewConstraints()
        titleLabelConstraints()

        bind()
        
        view.backgroundColor = .blue
        self.splitViewController?.hide(.primary)
        setCustomNavBarButtons()
        
        view.addSubview(cardsList)
        
        print("@@@@@@@@viewDidLoad self.viewModel.currentPaper?.cards.count\(self.viewModel.currentPaper?.cards.count)")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.splitViewController?.hide(.primary)
        cardsList.reloadData()
    }
    
    private func bind() {
        
        FirebaseAuthManager.shared
            .userProfileSubject
            .sink { [weak self] userModel in
                if
                    let userModel = userModel,
                    var currentPaper = self?.viewModel.currentPaperPublisher.value {
                    self?.viewModel.setCurrentUser()
                    if currentPaper.creator == nil {
                        currentPaper.creator = userModel
                        self?.setCustomNavBarButtons()
                        self?.viewModel.localDatabaseManager.updatePaper(paper: currentPaper)
                        self?.viewModel.localDatabaseManager.fetchPaper(paperId: currentPaper.paperId)
                        // 게스트가 생성 후 로그인하면 네비바의 오른 쪽 버튼 UI다시 그려주기 위함
                    } else {
                        self?.viewModel.localDatabaseManager.fetchPaper(paperId: currentPaper.paperId)
                        // creator 있던 페이퍼에 만든 사람이 로그인하면 네비바의 오른 쪽 버튼 UI다시 그려주기 위함
                    }
                    self?.setCustomNavBarButtons()
                }
            }
            .store(in: &cancellables)
    }
    
    @objc func cancelBtnPressed(_ gesture: UITapGestureRecognizer) {
        print("cancelBtnPressed")
        self.navigationController?.popViewController(animated: true)
    }
    
    private func setCustomNavBarButtons() {
        navigationItem.leftBarButtonItem = leftButton
        
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = .systemGray6
        navBarAppearance.shadowImage = UIImage.hideNavBarLine(color: UIColor.clear)
        
        self.navigationItem.standardAppearance = navBarAppearance
        self.navigationItem.scrollEdgeAppearance = navBarAppearance
    }
}

extension GiftPaperViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if self.viewModel.currentPaperPublisher.value?.endTime == self.viewModel.currentPaperPublisher.value?.date{
            return self.viewModel.currentPaper?.cards.count ?? 0
            print("@@@@@@@@self.viewModel.currentPaper?.cards.count\(self.viewModel.currentPaper?.cards.count)")
        } else {
            return ((self.viewModel.currentPaper?.cards.count ?? 0) + 1 )
            print("@@@@@@@@self.viewModel.currentPaper?.cards.count\(self.viewModel.currentPaper?.cards.count)")
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let myCell = collectionView.dequeueReusableCell(withReuseIdentifier: "MyCell", for: indexPath)
        myCell.layer.cornerRadius = 12
        myCell.layer.masksToBounds = true
        
        if self.viewModel.currentPaperPublisher.value?.endTime == self.viewModel.currentPaperPublisher.value?.date && self.viewModel.currentPaperPublisher.value?.isGift == true {
            guard let currentPaper = viewModel.currentPaper else { return myCell }
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
                guard let currentPaper = viewModel.currentPaper else { return myCell }
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
    }
}

extension GiftPaperViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("User tapped on item \(indexPath.row)")
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
    }
}

extension GiftPaperViewController {
    private func stackViewConstraints() {
        stackView.snp.makeConstraints { make in
            make.height.equalTo(36)
        }
    }
    
    private func titleLabelConstraints() {
        titleLabel.snp.makeConstraints({ make in
            make.height.equalTo(36)
            make.leading.equalTo(giftImage.snp.trailing).offset(5)
        })
    }
}
