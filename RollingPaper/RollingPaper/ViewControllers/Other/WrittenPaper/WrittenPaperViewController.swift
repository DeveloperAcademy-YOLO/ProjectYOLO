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
import UIKit

final class WrittenPaperViewController: UIViewController {
    private var viewModel: WrittenPaperViewModel = WrittenPaperViewModel()
    private let authManager: AuthManager = FirebaseAuthManager.shared
    private let timeManager: TimeFlowManager = TimeFlowManager()
    
    private let timerInput: PassthroughSubject<TimeFlowManager.Input, Never> = .init()
    private let currentUserSubject = PassthroughSubject<UserModel?, Never>()
    private lazy var cancellables = Set<AnyCancellable>()
    
    private lazy var paperLinkBtnIsPressed: Bool = false
    private lazy var stopPaperBtnIsPressed: Bool = false
    private lazy var timerBalloonBtnPressed: Bool = false
    private lazy var signInWithModal: Bool = false
    private let deviceWidth = UIScreen.main.bounds.size.width
    private let deviceHeight = UIScreen.main.bounds.size.height
    private let now: Date = Date()
    private var refreshControl: UIRefreshControl = {
        let control = UIRefreshControl()
        control.attributedTitle = NSAttributedString(string: "데이터를 불러오는 중입니다...")
        control.addTarget(self, action: #selector(pullToRefresh), for: .valueChanged)
        
        return control
    }()
    
    private lazy var showBalloonButton: UIButton = UIButton()
    private lazy var customBackBtn: UIButton = {
        let btnImg = UIImage(systemName: "chevron.backward")?
            .withTintColor(UIColor(named: "customBlack") ?? UIColor(red: 27, green: 27, blue: 27), renderingMode: .alwaysOriginal)
        let btn = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 23))
        btn.setTitle("보관함", for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 20)
        btn.setTitleColor(UIColor(named: "customBlack"), for: .normal)
        btn.setImage(btnImg, for: .normal)
        btn.addLeftPadding(5)
        
        return btn
    }()
    private lazy var managePaperBtn: UIButton = {
        let btnImg = UIImage(systemName: "ellipsis.circle")!
                        .resized(to: CGSize(width: 30, height: 30))
        let btn = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        btn.setImage(btnImg, for: .normal)
        
        return btn
    }()
    private lazy var paperLinkBtn: UIButton = {
        let btnImg = UIImage(systemName: "square.and.arrow.up")!
                        .resized(to: CGSize(width: 30, height: 30))
        let btn = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        btn.setImage(btnImg, for: .normal)
        
        return btn
    }()
    private lazy var createCardBtn: UIButton = {
        let btnImg = UIImage(systemName: "plus.rectangle.fill")!
                        .resized(to: CGSize(width: 40, height: 30))
        let btn = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        btn.setImage(btnImg, for: .normal)
        
        return btn
    }()
    private lazy var giftLinkBtn: UIButton = {
        let btnImg = UIImage(systemName: "giftcard.fill")!
                        .resized(to: CGSize(width: 51, height: 36))
        let btn = UIButton(frame: CGRect(x: 0, y: 0, width: 90, height: 50))
        btn.setImage(btnImg, for: .normal)
        
        return btn
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
        cardsList.addSubview(refreshControl)
        
        return cardsList
    }()
    
    //페이퍼의 제목 수정과 페이퍼 삭제, 두 곳에 쓰이는 UITextField 이므로 직접 쓰이는 곳에서 initialize를 해줘야 합니다.
    lazy private var titleEmbedingTextField: UITextField = UITextField()
    
    lazy private var timeLabel: TimerView = {
        let timeLabel = TimerView()
        timeLabel.setEndTime(time: viewModel.currentPaperPublisher.value?.endTime ?? Date())
        timeLabel.addSubview(showBalloonButton)
        return timeLabel
    }()
    
    private let timerDiscriptionBalloon = TimerDiscriptionBalloon()
    
    lazy private var titleLabel: BasePaddingLabel = {
        let titleLabel = BasePaddingLabel()
        //titleLabel.frame = CGRect(x: 0, y: 0, width: 400, height: 36)
        titleLabel.textAlignment = .left
        titleLabel.text = viewModel.currentPaper?.title
        titleLabel.font = UIFont.preferredFont(for: UIFont.TextStyle.title3, weight: UIFont.Weight.bold)
        titleLabel.numberOfLines = 1
        
        return titleLabel
    }()
    
    lazy private var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = NSLayoutConstraint.Axis.horizontal
        stackView.distribution = UIStackView.Distribution.equalSpacing
        stackView.addArrangedSubview(self.timeLabel)
        stackView.addArrangedSubview(self.titleLabel)
        setBalloonBtnLocation()
        
        return stackView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        bindTimer()
        bind()
        self.splitViewController?.hide(.primary)
        stackViewConstraints()
        navigationItem.titleView = stackView
        setCustomNavBarButtons()
        titleLabelConstraints()
        view.addSubview(cardsList)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.splitViewController?.hide(.primary)
        self.navigationController?.isNavigationBarHidden = false
        cardsList.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        timerInput.send(.viewDidAppear)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        timerInput.send(.viewDidDisappear)
    }
    
    override func viewWillDisappear  (_ animated: Bool) {
        super.viewWillDisappear(animated)
        if timerBalloonBtnPressed == true {
            timerDiscriptionBalloon.view.removeFromSuperview()
        }
    }
    
    private func bind() {
        FirebaseAuthManager.shared
            .userProfileSubject
            .sink { [weak self] userModel in
                if
                    let userModel = userModel,
                    var currentPaper = self?.viewModel.currentPaper {
                    self?.viewModel.setCurrentUser()
                    if currentPaper.creator == nil && self?.signInWithModal == true {
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
        viewModel
            .currentPaperPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] paper in
                if let paper = paper {
                    self?.cardsList.reloadData()
                }
            }
            .store(in: &cancellables)
        
        showBalloonButton
            .tapPublisher
            .sink { [weak self] in
                self?.timerBalloonBtnPressed = true
                self?.cardsList.addSubview(self?.timerDiscriptionBalloon.view ?? UIView())
                self?.setBalloonLocation()
            }
            .store(in: &cancellables)
        
        customBackBtn
            .tapPublisher
            .sink { [weak self] in
                self?.moveToPaperStorageView()
                self?.signInWithModal = false
            }
            .store(in: &cancellables)
        
        managePaperBtn
            .tapPublisher
            .sink { [weak self] in
                self?.setPopOverView(self?.managePaperBtn ?? UIButton())
                if self?.timerBalloonBtnPressed == true {
                    self?.timerDiscriptionBalloon.view.removeFromSuperview()
                }
            }
            .store(in: &cancellables)
        
        paperLinkBtn
            .tapPublisher
            .sink { [weak self] in
                self?.makeShareLink()
            }
            .store(in: &cancellables)
        
        createCardBtn
            .tapPublisher
            .sink{ [weak self] in
                self?.moveToCardRootView()
            }
            .store(in: &cancellables)
        
        giftLinkBtn
            .tapPublisher
            .sink{ [weak self] in
                print("선물하기 링크 생성 완료")
            }
            .store(in: &cancellables)
    }
    
    private func bindTimer() {
        let timerOutput = timeManager.transform(input: timerInput.eraseToAnyPublisher())
        timerOutput
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] event in
                guard let self = self else {return}
                switch event {
                    // 시간이 업데이트됨에 따라서 페이퍼 분류 및 UI 업데이트 하도록 시그널 보내기
                case .timeIsUpdated:
                    self.timeLabel.setEndTime(time: self.viewModel.currentPaperPublisher.value!.endTime)
                    self.timeLabel.updateTime()
                }
            })
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
        let firstBarButton = UIBarButtonItem(customView: customBackBtn)
        let secondBarButton = UIBarButtonItem(customView: managePaperBtn)
        let thirdBarButton = UIBarButtonItem(customView: paperLinkBtn)
        let fourthBarButton = UIBarButtonItem(customView: createCardBtn)
        let fifthBarButton = UIBarButtonItem(customView: giftLinkBtn)
        
        let signInSetting: [UIBarButtonItem] = [fourthBarButton, thirdBarButton, secondBarButton]
        let signOutSetting: [UIBarButtonItem] = [fourthBarButton, thirdBarButton]
        let stoppedPaperSetting: [UIBarButtonItem] = [fifthBarButton]
        
        navigationItem.rightBarButtonItems = (viewModel.currentPaper?.creator != nil && viewModel.currentPaper?.creator?.email == viewModel.currentUser?.email) ? signInSetting : signOutSetting // creator 있는 페이지에 다른 사람이 로그인 하면 페이퍼 관리 버튼 안 보이게 하는 로직
        if self.stopPaperBtnIsPressed == true {
            navigationItem.rightBarButtonItems = stoppedPaperSetting
        }
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
            userInfo: [NotificationViewKey.view: "보관함"]
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
    
    private func makeShareLink() {
        if self.timerBalloonBtnPressed == true {
            self.timerDiscriptionBalloon.view.removeFromSuperview()
        }
        
        if self.viewModel.isSameCurrentUserAndCreator {
            self.makeCurrentPaperLink()
            self.paperLinkBtnIsPressed = true
            self.viewModel
                .currentPaperPublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] paperModel in
                    if self?.paperLinkBtnIsPressed == true {
                        self?.presentShareSheet(self?.paperLinkBtn ?? UIButton())
                    }
                }
                .store(in: &cancellables)
        } else {
            presentSignUpModal(paperLinkBtn)
        }
    }
    
    private func moveToCardRootView() {
        let isLocalDB: Bool = viewModel.paperFrom == .fromLocal ? true : false
        
        guard let currentPaper = viewModel.currentPaperPublisher.value else { return }
        self.navigationController?.pushViewController(CardRootViewController(viewModel: CardViewModel(), isLocalDB: isLocalDB, currentPaper: currentPaper), animated: true)
    }
    
    private func presentSignUpModal(_ sender: UIButton) {
        if timerBalloonBtnPressed == true {
            timerDiscriptionBalloon.view.removeFromSuperview()
        }
        signInWithModal = true
        let signInVC = SignInViewController()
        let navVC = UINavigationController(rootViewController: signInVC)
        navVC.modalPresentationStyle = .formSheet //로그인 모달에 x버튼 넣기 위함
        present(navVC, animated: true)
    }
    
    private func presentShareSheet(_ sender: UIButton) {
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
            let stop = UIAlertAction(title: "확인", style: .default) { _ in
                self.stopPaperBtnIsPressed = true
                self.viewModel.stopPaper()
                self.cardsList.reloadData()
                self.setCustomNavBarButtons()
            }
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
    
    @objc private func pullToRefresh() {
        DispatchQueue.main.async {
            self.cardsList.reloadData()
            self.refreshControl.endRefreshing()
        }
    }
}

extension WrittenPaperViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if self.stopPaperBtnIsPressed == true {
            return self.viewModel.currentPaper?.cards.count ?? 0
        } else {
            return ((self.viewModel.currentPaper?.cards.count ?? 0) + 1 )
        }
    }
    //commit collectionView
    func saveCard(_ indexPath: IndexPath) {
        guard let currentPaper = viewModel.currentPaper else { return }
        let card = currentPaper.cards[indexPath.row - 1]
        
        if let image = NSCacheManager.shared.getImage(name: card.contentURLString) {
            UIImageWriteToSavedPhotosAlbum(image, self, #selector(imageSave(_:didFinishSavingWithError:contextInfo:)), nil)
        }
    }
    
    func shareCard( _ indexPath: IndexPath, _ sender: CGPoint) {
        guard let currentPaper = viewModel.currentPaper else { return }
        let card = currentPaper.cards[indexPath.row - 1]
        
        if let image = NSCacheManager.shared.getImage(name: card.contentURLString) {
            imageShare(sender, image)
        }
    }
    
    func deleteCard(_ indexPath: IndexPath) {
        guard let currentPaper = viewModel.currentPaper else { return }
        let card = currentPaper.cards[indexPath.row]

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
        
        if self.stopPaperBtnIsPressed == true {
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

extension WrittenPaperViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if self.stopPaperBtnIsPressed == true {
            let presentingVC = MagnifiedCardViewController()
            let blurredVC = BlurredViewController()
            
            blurredVC.modalTransitionStyle = .crossDissolve
            blurredVC.modalPresentationStyle = .currentContext
            self.present(blurredVC, animated: true)
            
            presentingVC.backgroundViewController = blurredVC
            presentingVC.selectedCardIndex = indexPath.row
            presentingVC.modalPresentationStyle = .overFullScreen
            present(presentingVC, animated: true)
            
            collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        } else {
            if indexPath.row == 0 {
                moveToCardRootView()
            } else {
                let presentingVC = MagnifiedCardViewController()
                let blurredVC = BlurredViewController()
                
                blurredVC.modalTransitionStyle = .crossDissolve
                blurredVC.modalPresentationStyle = .currentContext
                self.present(blurredVC, animated: true)
                
                presentingVC.backgroundViewController = blurredVC
                presentingVC.selectedCardIndex = indexPath.row - 1
                presentingVC.modalPresentationStyle = .overFullScreen
                present(presentingVC, animated: true)
                
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
    private func stackViewConstraints() {
        stackView.snp.makeConstraints { make in
            make.height.equalTo(36)
        }
    }
    
    private func titleLabelConstraints() {
        titleLabel.snp.makeConstraints({ make in
            make.height.equalTo(36)
            make.leading.equalTo(timeLabel.snp.trailing).offset(10)
        })
    }
    
    private func setBalloonBtnLocation() {
        showBalloonButton.snp.makeConstraints({ make in
            make.width.equalTo(timeLabel.snp.width)
            make.height.equalTo(timeLabel.snp.height)
        })
    }
    
    private func setBalloonLocation() {
        timerDiscriptionBalloon.view.snp.makeConstraints { make in
            make.centerX.equalTo(timeLabel.snp.centerX)
            make.width.equalTo(224)
            make.height.equalTo(81)
        }
    }
}
