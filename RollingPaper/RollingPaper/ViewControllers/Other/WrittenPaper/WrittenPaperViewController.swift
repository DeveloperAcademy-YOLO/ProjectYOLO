//
//  WrittenPaperViewController.swift
//  RollingPaper
//
//  Created by SeungHwanKim on 2022/10/12.
//
import AVFoundation
import Combine
import Foundation
import LinkPresentation
import SnapKit
import PencilKit
import Photos
import StickerView
import UIKit

final class WrittenPaperViewController: UIViewController {
    private var viewModel: WrittenPaperViewModel = WrittenPaperViewModel()
    private let authManager: AuthManager = FirebaseAuthManager.shared
    private let currentUserSubject = PassthroughSubject<UserModel?, Never>()
    private var cancellables = Set<AnyCancellable>()
    private var paperLinkBtnIsPressed: Bool = false
    private var deviceWidth = UIScreen.main.bounds.size.width
    private var deviceHeight = UIScreen.main.bounds.size.height
    lazy private var cardsList: UICollectionView = {
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
        cardsList.reloadData()
        
        return cardsList
    }()
    
    //페이퍼의 제목 수정과 페이퍼 삭제, 두 곳에 쓰이는 UITextField 이므로 직접 쓰이는 곳에서 initialize를 해줘야 합니다.
    lazy private var titleEmbedingTextField: UITextField = UITextField()
    
    
    lazy private var titleLabel: BasePaddingLabel = {
        let titleLabel = BasePaddingLabel()
        //titleLabel.frame = CGRect(x: 0, y: 0, width: 400, height: 36)
        titleLabel.textAlignment = .left
        titleLabel.text = viewModel.currentPaper?.title
        titleLabel.font = UIFont.preferredFont(for: UIFont.TextStyle.title3, weight: UIFont.Weight.bold)
        titleLabel.numberOfLines = 1
        return titleLabel
    }()
    //도피가 만든 타이머로 바뀌는 부분
    lazy private var timeLabel = TimerOfPaperViewController()
    lazy private var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = NSLayoutConstraint.Axis.horizontal
        stackView.distribution = UIStackView.Distribution.equalSpacing
        stackView.addArrangedSubview(self.timeLabel.view)
        stackView.addArrangedSubview(self.titleLabel)
        titleLabelConstraints()
        return stackView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        bind()
        self.splitViewController?.hide(.primary)
        navigationItem.titleView = stackView
        setCustomNavBarButtons()
        view.addSubview(cardsList)
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
                    var currentPaper = self?.viewModel.currentPaper {
                    self?.viewModel.setCurrentUser()
                    if currentPaper.creator == nil {
                        currentPaper.creator = userModel
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
    
    private func resetCurrentPaper() {
        viewModel
            .currentPaperPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] paperModel in
                if let paperModel = paperModel {
                    self?.titleLabel.text = paperModel.title
                }
            }
            .store(in: &cancellables)
    }
    
    private func setCustomNavBarButtons() {
        let customBackBtnImage = UIImage(systemName: "chevron.backward")?.withTintColor(UIColor(named: "customBlack") ?? UIColor(red: 100, green: 100, blue: 100), renderingMode: .alwaysOriginal)
        let customBackBtn = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 23))
        customBackBtn.setTitle("보관함", for: .normal)
        customBackBtn.titleLabel?.font = UIFont.systemFont(ofSize: 20)
        customBackBtn.setTitleColor(.black, for: .normal)
        customBackBtn.setImage(customBackBtnImage, for: .normal)
        customBackBtn.addAction(UIAction(handler: { [self] _ in moveToPaperStorageView()}), for: .touchUpInside)
        customBackBtn.addLeftPadding(5)
        
        let managePaperBtnImage = UIImage(systemName: "ellipsis.circle")!.resized(to: CGSize(width: 30, height: 30))
        let managePaperBtn = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        managePaperBtn.setImage(managePaperBtnImage, for: .normal)
        managePaperBtn.addAction(UIAction(handler: {_ in self.setPopOverView(managePaperBtn)}), for: .touchUpInside)
        
        let paperLinkBtnImage = UIImage(systemName: "square.and.arrow.up")!.resized(to: CGSize(width: 30, height: 30))
        paperLinkBtnImage.withTintColor(.systemBlue)
        let paperLinkBtn = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        paperLinkBtn.setImage(paperLinkBtnImage, for: .normal)
        paperLinkBtn.addAction(UIAction(handler: { [self] _ in
            if viewModel.isSameCurrentUserAndCreator {
                makeCurrentPaperLink()
                paperLinkBtnIsPressed = true
                viewModel
                    .currentPaperPublisher
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] paperModel in
                        if self?.paperLinkBtnIsPressed == true {
                            self?.presentShareSheet(paperLinkBtn)}
                    }
                    .store(in: &self.cancellables)
                
            } else {
                presentSignUpModal(paperLinkBtn)
            }
        }), for: .touchUpInside)
        
        let createCardBtnImage = UIImage(systemName: "plus.rectangle.fill")!.resized(to: CGSize(width: 40, height: 30))
        let createCardBtn = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        createCardBtn.setImage(createCardBtnImage, for: .normal)
        createCardBtn.addAction(UIAction(handler: { [self] _ in moveToCardRootView()}), for: .touchUpInside)
        
        let firstBarButton = UIBarButtonItem(customView: customBackBtn)
        let secondBarButton = UIBarButtonItem(customView: managePaperBtn)
        let thirdBarButton = UIBarButtonItem(customView: paperLinkBtn)
        let fourthBarButton = UIBarButtonItem(customView: createCardBtn)
        
        let signInSetting: [UIBarButtonItem] = [fourthBarButton, thirdBarButton, secondBarButton]
        let signOutSetting: [UIBarButtonItem] = [fourthBarButton, thirdBarButton]
        
        navigationItem.rightBarButtonItems = (viewModel.currentPaper?.creator != nil && viewModel.currentPaper?.creator?.email == viewModel.currentUser?.email) ? signInSetting : signOutSetting // creator 있는 페이지에 다른 사람이 로그인 하면 페이퍼 관리 버튼 안 보이게 하는 로직
        viewModel.isSameCurrentUserAndCreator = (viewModel.currentPaper?.creator != nil && viewModel.currentPaper?.creator?.email == viewModel.currentUser?.email) ? true : false
        navigationItem.leftBarButtonItem = firstBarButton
    }
    
    private func deletePaper() {
        let deleteVerifyText = self.titleEmbedingTextField.text
        if deleteVerifyText == self.viewModel.currentPaper?.title {
            if viewModel.isPaperLinkMade { //링크가 만들어진 것이 맞다면 서버에 페이퍼가 저장되어있으므로
                viewModel.deletePaper(viewModel.currentPaper!.paperId, from: .fromServer)
            } else {
                viewModel.deletePaper(viewModel.currentPaper!.paperId, from: .fromLocal)
            }
            moveToPaperStorageView()
        } else {
            let alert = UIAlertController(title: "제목을 잘못 입력하셨습니다", message: nil, preferredStyle: .alert)
            let confirm = UIAlertAction(title: "확인", style: .default)
            alert.addAction(confirm)
            alert.preferredAction = confirm
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    private func moveToPaperStorageView() {
        if viewModel.currentPaper != nil {
            guard let paper = viewModel.currentPaper else { return }
            if viewModel.isPaperLinkMade {
                viewModel.serverDatabaseManager.updatePaper(paper: paper)
            } else {
                viewModel.localDatabaseManager.updatePaper(paper: paper)
            }
        }
        NotificationCenter.default.post(
            name: Notification.Name.viewChange,
            object: nil,
            userInfo: [NotificationViewKey.view: "페이퍼 보관함"]
        )
    }
    
    private func makeCurrentPaperLink() {
        guard let paper = viewModel.currentPaper else {return}
        getPaperShareLink(with: paper, route: .write)
            .receive(on: DispatchQueue.global(qos: .background))
            .sink { (completion) in
                switch completion {
                    // 링크가 만들어지면 isPaperLinkMade 값을 바꿔줌
                case .finished: break
                case .failure(let error): print(error)
                }
            } receiveValue: { [weak self] url in
                self?.viewModel.makePaperLinkToShare(input: url)
            }
            .store(in: &cancellables)
    }
    
    private func moveToCardRootView() {
        let isLocalDB: Bool = viewModel.paperFrom == .fromLocal ? true : false
        
        guard let currentPaper = viewModel.currentPaperPublisher.value else { return }
        self.navigationController?.pushViewController(CardRootViewController(viewModel: CardViewModel(), isLocalDB: isLocalDB, currentPaper: currentPaper), animated: true)
    }
    
    private func presentSignUpModal(_ sender: UIButton) {
        let signInVC = SignInViewController()
        let navVC = UINavigationController(rootViewController: signInVC)
        navVC.modalPresentationStyle = .formSheet //로그인 모달에 x버튼 넣기 위함
        present(navVC, animated: true)
    }
    
    private func presentShareSheet(_ sender: UIButton) {
        let text = "dummy text. 여기에 소개 멘트가 들어갈 자리입니다. 페이퍼를 공유해보세요~~ 등등"
        //TODO : 카톡으로 공유하기
        guard let link = self.viewModel.currentPaperPublisher.value?.linkUrl else {return}
        let applicationActivities: [UIActivity]? = nil
        let activityViewController = UIActivityViewController(
            activityItems: [link] ,
            applicationActivities: applicationActivities)
        
        let popover = activityViewController.popoverPresentationController
        popover?.sourceView = sender
        self.present(activityViewController, animated: true)
        self.paperLinkBtnIsPressed = false
    }
    
    private func setPopOverView(_ sender: UIButton) {
        let attributedTitleString = NSAttributedString(string: "페이지 관리", attributes: [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15),
            NSAttributedString.Key.strokeWidth: -5 ])
        let attributedMessageString = NSAttributedString(string: "정보를 수정하거나 삭제할 수 있습니다.", attributes: [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15) ])
        
        let allertController = UIAlertController(title: "", message: "", preferredStyle: .actionSheet)
        
        allertController.addAction(UIAlertAction(title: "수정", style: .default,
                                                 handler: {_ in
            let alert = UIAlertController(title: "페이퍼 제목 수정", message: "", preferredStyle: .alert)
            let edit = UIAlertAction(title: "수정", style: .default) { _ in
                guard let changedPaperTitle = self.titleEmbedingTextField.text else { return }
                
                if self.viewModel.isPaperLinkMade { //링크가 만들어진 것이 맞다면 서버에 페이퍼가 저장되어있으므로
                    self.viewModel.changePaperTitle(input: changedPaperTitle, from: .fromServer)
                    self.resetCurrentPaper()
                } else {
                    self.viewModel.changePaperTitle(input: changedPaperTitle, from: .fromLocal)
                    self.resetCurrentPaper()
                }
            }
            let cancel = UIAlertAction(title: "취소", style: .cancel)
            alert.addAction(cancel)
            alert.addAction(edit)
            alert.addTextField { (editTitleTextField) in
                editTitleTextField.text = self.viewModel.currentPaper?.title
                self.titleEmbedingTextField = editTitleTextField
            }
            alert.preferredAction = edit
            self.present(alert, animated: true, completion: nil)
        }))
        allertController.addAction(UIAlertAction(title: "마감", style: .default,
                                                 handler: {_ in
            let alert = UIAlertController(title: "페이퍼 마감", message: "마감하면 더이상 메세지 카드를 남길 수 없습니다. 마감하시겠어요?", preferredStyle: .alert)
            let stop = UIAlertAction(title: "확인", style: .default) { (stop) in  }
            let cancel = UIAlertAction(title: "취소", style: .cancel)
            alert.addAction(cancel)
            alert.addAction(stop)
            alert.preferredAction = stop
            self.present(alert, animated: true, completion: nil)
        }))
        
        allertController.addAction(UIAlertAction(title: "삭제", style: .destructive,
                                                 handler: {_ in
            let alert = UIAlertController(title: "페이퍼 삭제", message: "페이퍼를 삭제하려면 페이퍼 제목을 하단에 입력해주세요.", preferredStyle: .alert)
            let delete = UIAlertAction(title: "삭제", style: .destructive) { _ in
                self.deletePaper()
            }
            let cancel = UIAlertAction(title: "취소", style: .cancel)
            alert.addAction(delete)
            alert.addAction(cancel)
            alert.preferredAction = delete
            alert.addTextField { (deleteTitleTextField) in
                deleteTitleTextField.placeholder = self.viewModel.currentPaper?.title
                self.titleEmbedingTextField = deleteTitleTextField
            }
            self.present(alert, animated: true, completion: nil)
        }))
        
        allertController.setValue(attributedTitleString, forKey: "attributedTitle")
        allertController.setValue(attributedMessageString, forKey: "attributedMessage")
        
        let popover = allertController.popoverPresentationController
        popover?.sourceView = sender
        popover?.backgroundColor = .systemBackground
        present(allertController, animated: true)
    }
    
    //    func deletePaper() {
    //        let deleteVerifyText = self.titleEmbedingTextField.text
    //        if deleteVerifyText == self.viewModel.currentPaper?.title {
    //            if viewModel.isPaperLinkMade { //링크가 만들어진 것이 맞다면 서버에 페이퍼가 저장되어있으므로
    //                viewModel.deletePaper(viewModel.currentPaper!.paperId, from: .fromServer)
    //            } else {
    //                viewModel.deletePaper(viewModel.currentPaper!.paperId, from: .fromLocal)
    //            }
    //            self.moveToPaperStorageView()
    //        } else {
    //            let alert = UIAlertController(title: "제목을 잘못 입력하셨습니다", message: nil, preferredStyle: .alert)
    //            let confirm = UIAlertAction(title: "확인", style: .default)
    //            alert.addAction(confirm)
    //            alert.preferredAction = confirm
    //            self.present(alert, animated: true, completion: nil)
    //        }
    //    }
    
    func setCollectionView() -> UICollectionView {
        var cardsCollection: UICollectionView?
        
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 25, left: 20, bottom: 25, right: 20 )
        layout.itemSize = CGSize(width: (self.view.frame.width-80)/3, height: ((self.view.frame.width-120)/3)*0.75)
        layout.minimumInteritemSpacing = 20
        layout.minimumLineSpacing = 20
        
        cardsCollection = UICollectionView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height), collectionViewLayout: layout)
        cardsCollection?.center.x = view.center.x
        cardsCollection?.showsVerticalScrollIndicator = false
        cardsCollection?.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "MyCell")
        cardsCollection?.dataSource = self
        cardsCollection?.delegate = self
        cardsCollection?.reloadData()
        return cardsCollection ?? UICollectionView()
    }
}

extension WrittenPaperViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.viewModel.currentPaper?.cards.count ?? 0
    }
    //commit collectionView
    
    func saveCard( _ indexPath : Int) {
        guard let currentPaper = viewModel.currentPaper else { return }
        let card = currentPaper.cards[indexPath]
        
        if let image = NSCacheManager.shared.getImage(name: card.contentURLString) {
            UIImageWriteToSavedPhotosAlbum(image, self, #selector(imageSave(_:didFinishSavingWithError:contextInfo:)), nil)
        }
    }
    
    func shareCard( _ indexPath: Int, _ sender: CGPoint) {
        guard let currentPaper = viewModel.currentPaper else { return }
        let card = currentPaper.cards[indexPath]
        
        if let image = NSCacheManager.shared.getImage(name: card.contentURLString) {
            imageShare(sender,image)
        }
    }
    
    func deleteCard( _ indexPath : Int) {
        guard let currentPaper = viewModel.currentPaper else { return }
        let card = currentPaper.cards[indexPath]
        
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let myCell = collectionView.dequeueReusableCell(withReuseIdentifier: "MyCell", for: indexPath)
        myCell.layer.cornerRadius = 12
        myCell.layer.masksToBounds = true
        
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
        return myCell
    }
}

extension WrittenPaperViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let currentPaper = viewModel.currentPaper else { return  }
        let card = currentPaper.cards[indexPath.row]
        let presentingVC = MagnifiedCardViewController()
        
        presentingVC.selectedCardIndex = indexPath.row
        presentingVC.modalPresentationStyle = .overCurrentContext
        present(presentingVC, animated: true)
        
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemsAt indexPaths: [IndexPath], point: CGPoint) -> UIContextMenuConfiguration? {
        guard let indexPath = indexPaths.first?.row else { return nil }
        let config = UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            
            let save = UIAction(
                title: "사진 앱에 저장하기",
                image: UIImage(systemName: "photo.on.rectangle"),
                identifier: nil,
                discoverabilityTitle: nil,
                state: .off
            ){ [weak self] _ in
                self?.saveCard(indexPath)
            }
            
            let share = UIAction(
                title: "공유하기",
                image: UIImage(systemName: "square.and.arrow.up"),
                identifier: nil,
                discoverabilityTitle: nil,
                state: .off
            ){ [weak self] _ in
                self?.shareCard(indexPath, point)
            }
            
            let delete = UIAction(
                title: "삭제하기",
                image: UIImage(systemName: "trash"),
                identifier: nil,
                discoverabilityTitle: nil,
                attributes: .destructive,
                state: .off
            ) { _ in
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
            present(alert, animated: true)
        } else {
            let alert = UIAlertController(title: "Saved!", message: "이미지가 사진첩에 저장이 되었습니다", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
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
        self.present(shareSheetVC, animated: true, completion: nil)
        
        let rect: CGRect = .init(origin: sender, size: CGSize(width: 200, height: 200))
        
        shareSheetVC.popoverPresentationController?.sourceView = self.view
        shareSheetVC.popoverPresentationController?.sourceRect = rect
    }
}

extension WrittenPaperViewController {
    private func titleLabelConstraints() {
        titleLabel.snp.makeConstraints({ make in
            make.height.equalTo(36)
            make.leading.equalTo(timeLabel.view.snp.trailing).offset(10)
        })
    }
}
