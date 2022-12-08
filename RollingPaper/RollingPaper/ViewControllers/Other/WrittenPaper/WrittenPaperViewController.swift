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
    private var isFirst: Bool = true
    private var viewModel: WrittenPaperViewModel = WrittenPaperViewModel()
    private let authManager: AuthManager = FirebaseAuthManager.shared
    private let timeManager: TimeFlowManager = TimeFlowManager()
    
    private let inputToVM: PassthroughSubject<WrittenPaperViewModel.Input, Never> = .init()
    private let timerInput: PassthroughSubject<TimeFlowManager.Input, Never> = .init()
    private lazy var cancellables = Set<AnyCancellable>()
    
    private lazy var stopPaperBtnIsPressed: Bool = false
    private lazy var timerBalloonBtnPressed: Bool = false
    private lazy var signInWithModal: Bool = false
    lazy var fromCardView: Bool = false
    private let deviceWidth = UIScreen.main.bounds.size.width
    private let deviceHeight = UIScreen.main.bounds.size.height
    var timeInterval: Double?
    private let now: Date = Date()
    
    private lazy var showBalloonButton: UIButton = UIButton()
    private lazy var customBackBtn: UIButton = {
        let btnImg = UIImage(systemName: "chevron.backward")?
            .withTintColor(UIColor(named: "customBlack") ?? UIColor(red: 27, green: 27, blue: 27), renderingMode: .alwaysOriginal)
        let btn = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 23))
        btn.setTitle("담벼락", for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 20)
        btn.setTitleColor(.black, for: .normal)
        btn.setImage(btnImg, for: .normal)
        btn.addLeftPadding(5)
        
        return btn
    }()
    
    //페이퍼의 제목 수정과 페이퍼 삭제, 두 곳에 쓰이는 UITextField 이므로 직접 쓰이는 곳에서 initialize를 해줘야 합니다.
    lazy private var titleEmbedingTextField: UITextField = UITextField()
    
    lazy private var timeLabel: TimerView = {
        let timeLabel = TimerView()
        timeLabel.addSubview(showBalloonButton)
        return timeLabel
    }()
    private let timerDiscriptionBalloon = TimerDiscriptionBalloon()
    lazy private var titleLabel: BasePaddingLabel = {
        let titleLabel = BasePaddingLabel()
        //titleLabel.frame = CGRect(x: 0, y: 0, width: 400, height: 36)
        titleLabel.textAlignment = .left
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
    
    private lazy var managePaperBtn: UIButton = {
        let btnImg = UIImage(systemName: "ellipsis.circle")?
            .resized(to: CGSize(width: 30, height: 30))
        let btn = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        btn.setImage(btnImg, for: .normal)
        
        return btn
    }()
    private lazy var paperLinkBtn: UIButton = {
        let btnImg = UIImage(systemName: "square.and.arrow.up")?
            .resized(to: CGSize(width: 30, height: 30))
        let btn = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        btn.setImage(btnImg, for: .normal)
        
        return btn
    }()
    private lazy var createCardBtn: UIButton = {
        let btnImg = UIImage(systemName: "plus.rectangle.fill")?
            .resized(to: CGSize(width: 40, height: 30))
        let btn = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        btn.setImage(btnImg, for: .normal)
        
        return btn
    }()
    private lazy var giftLinkBtn: UIButton = {
        let btnImg = UIImage(systemName: "giftcard.fill")?
            .resized(to: CGSize(width: 51, height: 36))
        let btn = UIButton(frame: CGRect(x: 0, y: 0, width: 90, height: 50))
        btn.setImage(btnImg, for: .normal)
        
        return btn
    }()
    
    private lazy var cardsList: UICollectionView = {
        let cardsListView = CardsInPaperViewController()
        cardsListView.viewModel = self.viewModel
        cardsListView.callingVC = self
        return cardsListView
    }()
    
    private lazy var spinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView()
        spinner.color = .label
        spinner.startAnimating()
        return spinner
    }()
    
    private lazy var tapGesture: UITapGestureRecognizer = {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        tapGesture.cancelsTouchesInView = true
        
        return tapGesture
    }()
    
    @objc func hideKeyboard() {
        timerDiscriptionBalloon.view.isHidden = true
        self.tapGesture.isEnabled = false
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        self.navigationController?.isNavigationBarHidden = true
        bind()
        bindTimer()
        self.splitViewController?.hide(.primary)
        inputToVM.send(.fetchingPaper)
        spinnerConstraints()
        view.addSubview(spinner)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.splitViewController?.hide(.primary)
        if fromCardView {
            self.navigationController?.isNavigationBarHidden = false
            //해당 뷰컨이 카드 생성후에 나타났을 때는 네비바가 사라지지 않게하기 위함
        }
        self.timeInterval = self.viewModel.currentPaperPublisher.value?.endTime.timeIntervalSince(Date())
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
        checkTimerBallon()
    }
    
    private func bind() {
        let outputFromVM = viewModel.transform(inputFromVC: inputToVM.eraseToAnyPublisher())
        outputFromVM
            .receive(on: DispatchQueue.main)
            .sink { [weak self] receivedValue in
                guard let self = self else { return }
                switch receivedValue {
                case .cardDeleted:
                    break
                case .paperStopped:
                    self.setCustomNavBarButtons()
                    self.timeLabel.setEndTime(time: self.viewModel.currentPaperPublisher.value?.endTime ?? Date())
                case .paperDeleted:
                    self.inputToVM.send(.moveToStorageTapped)
                    self.moveToPaperStorageView()
                case .paperTitleChanged:
                    self.titleLabel.text = self.viewModel.currentPaperPublisher.value?.title
                case .paperLinkMade(let url):
                    self.presentShareSheet(self.paperLinkBtn, url: url)
                case .giftLinkMade(let url):
                    self.presentShareSheet(self.giftLinkBtn, url: url)
                }
            }
            .store(in: &cancellables)
        
        FirebaseAuthManager.shared
            .userProfileSubject
            .sink { [weak self] userModel in
                if
                    let userModel = userModel,
                    var currentPaper = self?.viewModel.currentPaperPublisher.value {
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
            .sink(receiveValue: { [weak self] paper in
                print("aaa currentPaperPublisher has changed: \(paper)")
                guard let self = self else {return}
                if let paper = paper {
                    // 내꺼에서 보관함에서 터치해서 -> 최초에 페이퍼가 설정됐을때 하는 것들
                    // 다른 사람이 카드를 추가한다거나 등등의 상황에도 실행이됨
                    if self.isFirst {
                        self.checkFetchingCorrectly(paper) // 딱 1번만 실행되야함
                        self.isFirst = false
                    }
                    self.titleLabel.text = paper.title
                    self.timeLabel.setEndTime(time: paper.endTime)
                    self.cardsList.reloadData()
                }
            })
            .store(in: &cancellables)
        
        showBalloonButton
            .tapPublisher
            .sink { [weak self] in
                guard let tapGesture = self?.tapGesture else {return}
                if self?.viewModel.currentPaperPublisher.value?.endTime != self?.viewModel.currentPaperPublisher.value?.date {
                    self?.view.addGestureRecognizer(tapGesture)
                    self?.timerBalloonBtnPressed = true
                    self?.tapGesture.isEnabled = true
                    self?.navigationController?.navigationBar.addSubview(self?.timerDiscriptionBalloon.view ?? UIView())
                    self?.timerDiscriptionBalloon.view.isHidden = false
                    self?.setBalloonLocation()
                }
            }
            .store(in: &cancellables)
        
        customBackBtn
            .tapPublisher
            .sink { [weak self] in
                self?.moveToPaperStorageView()
                self?.inputToVM.send(.moveToStorageTapped)
                self?.signInWithModal = false
            }
            .store(in: &cancellables)
        
        managePaperBtn
            .tapPublisher
            .sink { [weak self] in
                self?.checkTimerBallon()
                self?.setPopOverView(self?.managePaperBtn ?? UIButton())
            }
            .store(in: &cancellables)
        
        paperLinkBtn
            .tapPublisher
            .sink { [weak self] in
                guard let self = self else { return }
                self.checkTimerBallon()
                if self.viewModel.isSameCurrentUserAndCreator == true && self.viewModel.currentPaperPublisher.value?.creator != nil {
                    self.inputToVM.send(.paperShareTapped)
                } else {
                    self.presentSignUpModal(self.paperLinkBtn)
                }
            }
            .store(in: &cancellables)
        
        createCardBtn
            .tapPublisher
            .sink { [weak self] in
                self?.checkTimerBallon()
                self?.moveToCardRootView()
            }
            .store(in: &cancellables)
        
        giftLinkBtn
            .tapPublisher
            .sink { [weak self] in
                if self?.viewModel.currentPaperPublisher.value?.creator != nil {
                    self?.inputToVM.send(.giftTapped)
                } else {
                    self?.presentSignUpModal(self?.giftLinkBtn ?? UIButton())
                }
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
                    // 1초마다 신호가 들어와서 아래 코드들이 실행됨
                    // 시간이 업데이트됨에 따라서 페이퍼 분류 및 UI 업데이트 하도록 시그널 보내기
                case .timeIsUpdated:
                    self.timeLabel.updateTime()
                    // 현재 페이퍼의 endtime - 현재 시간 -> 글자로 표시
                    // 현재 페이퍼의 endtime? -> setEndtime 설정을 해줌
                    self.timeInterval = self.viewModel.currentPaperPublisher.value?.endTime.timeIntervalSince(Date())
                    if self.timeInterval ?? 0.0 <= 0.0 {
                        self.setCustomNavBarButtons()
                        self.cardsList.reloadData()
                    }
                }
            })
            .store(in: &cancellables)
    }
    
    private func drawView() {
        setCustomNavBarButtons()
        stackViewConstraints()
        navigationItem.titleView = stackView
        titleLabelConstraints()
        view.addSubview(cardsList)
        self.spinner.stopAnimating()
        self.spinner.isHidden = true
    }
    
    private func checkFetchingCorrectly(_ paper: PaperModel?) {
        DispatchQueue.main.asyncAfter(deadline: .now()+0.5) {
            self.timeLabel.setEndTime(time: paper?.endTime ?? Date())
            self.navigationController?.isNavigationBarHidden = false
            self.titleLabel.text = paper?.title
            self.drawView()
        }
    }
    
    private func setCustomNavBarButtons() {
        guard let currentPaper = self.viewModel.currentPaperPublisher.value else {return}
        let firstBarButton = UIBarButtonItem(customView: customBackBtn)
        let secondBarButton = UIBarButtonItem(customView: managePaperBtn)
        let thirdBarButton = UIBarButtonItem(customView: paperLinkBtn)
        let fourthBarButton = UIBarButtonItem(customView: createCardBtn)
        let fifthBarButton = UIBarButtonItem(customView: giftLinkBtn)
        
        let signInSetting: [UIBarButtonItem] = [fourthBarButton, thirdBarButton, secondBarButton]
        let signOutSetting: [UIBarButtonItem] = [fourthBarButton, thirdBarButton]
        let stoppedPaperSetting: [UIBarButtonItem] = [fifthBarButton]
        
        navigationItem.rightBarButtonItems = signOutSetting
        navigationItem.leftBarButtonItem = firstBarButton
        if currentPaper.creator != nil && currentPaper.creator?.email == viewModel.currentUser?.email {
            navigationItem.rightBarButtonItems = signInSetting
        } // creator 있는 페이지에 다른 사람이 로그인 하면 페이퍼 관리 버튼 안 보이게 하는 로직
        if currentPaper.endTime == currentPaper.date || self.timeInterval ?? 1.0 <= 0.0 {
            navigationItem.rightBarButtonItems = stoppedPaperSetting
        }
        viewModel.isSameCurrentUserAndCreator = (currentPaper.creator != nil && currentPaper.creator?.email == viewModel.currentUser?.email) ? true : false
    }
    
    private func setPopOverView(_ sender: UIButton) {
        guard let currentPaper = self.viewModel.currentPaperPublisher.value else {return}
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
                    self.inputToVM.send(.changePaperTitleTapped(changedTitle: changedPaperTitle, from: .fromServer))
                } else {
                    self.inputToVM.send(.changePaperTitleTapped(changedTitle: changedPaperTitle, from: .fromLocal))
                }
            }
            let cancel = UIAlertAction(title: "취소", style: .cancel)
            alert.addAction(cancel)
            alert.addAction(edit)
            alert.addTextField { (editTitleTextField) in
                editTitleTextField.text = currentPaper.title
                self.titleEmbedingTextField = editTitleTextField
            }
            alert.preferredAction = edit
            self.present(alert, animated: true, completion: nil)
        }))
        allertController.addAction(UIAlertAction(title: "마감", style: .default,
                                                 handler: {_ in
            let alert = UIAlertController(title: "페이퍼 마감", message: "마감하면 더이상 메세지 카드를 남길 수 없습니다. 마감하시겠어요?", preferredStyle: .alert)
            let stop = UIAlertAction(title: "확인", style: .default) { _ in
                self.timerInput.send(.viewDidDisappear)
                self.inputToVM.send(.stopPaperTapped)
                self.stopPaperBtnIsPressed = true
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
                self.timerInput.send(.viewDidDisappear)
                self.deletePaper()
            }
            let cancel = UIAlertAction(title: "취소", style: .cancel)
            alert.addAction(delete)
            alert.addAction(cancel)
            alert.preferredAction = delete
            alert.addTextField { (deleteTitleTextField) in
                deleteTitleTextField.placeholder = currentPaper.title
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
    
    private func deletePaper() {
        let deleteVerifyText = self.titleEmbedingTextField.text
        if deleteVerifyText == self.viewModel.currentPaperPublisher.value?.title {
            self.inputToVM.send(.deletePaperTapped)
        } else {
            let alert = UIAlertController(title: "제목을 잘못 입력하셨습니다", message: nil, preferredStyle: .alert)
            let confirm = UIAlertAction(title: "확인", style: .default)
            alert.addAction(confirm)
            alert.preferredAction = confirm
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    private func presentSignUpModal(_ sender: UIButton) {
        signInWithModal = true
        let signInVC = SignInViewController()
        let navVC = UINavigationController(rootViewController: signInVC)
        navVC.modalPresentationStyle = .formSheet //로그인 모달에 x버튼 넣기 위함
        present(navVC, animated: true)
    }
    
    private func presentShareSheet(_ sender: UIButton, url: URL) {
        let applicationActivities: [UIActivity]? = nil
        let activityViewController = UIActivityViewController(
            activityItems: [url] ,
            applicationActivities: applicationActivities)
        
        let popover = activityViewController.popoverPresentationController
        popover?.sourceView = sender
        self.present(activityViewController, animated: true)
    }
    
    private func moveToCardRootView() {
        let isLocalDB: Bool = viewModel.paperFrom == .fromLocal ? true : false
        //해당 뷰컨이 카드 생성후에 나타났을 때는 네비바가 사라지지 않게하기 위함
        fromCardView = true
        guard let currentPaper = viewModel.currentPaperPublisher.value else { return }
        self.navigationController?.pushViewController(CardRootViewController(viewModel: CardViewModel(isLocalDB: isLocalDB), isLocalDB: isLocalDB, currentPaper: currentPaper), animated: true)
    }
    
    private func moveToPaperStorageView() {
        if let paper = viewModel.currentPaperPublisher.value {
            if viewModel.isPaperLinkMade {
                viewModel.serverDatabaseManager.updatePaper(paper: paper)
                viewModel.localDatabaseManager.updatePaper(paper: paper)
            } else {
                viewModel.localDatabaseManager.updatePaper(paper: paper)
            }
        }
        navigationController?.popViewController(true, completion: {
            self.viewModel.cancellables.removeAll()
        })

    }
    
    func checkTimerBallon() {
        if self.timerBalloonBtnPressed == true {
            self.view.removeGestureRecognizer(self.tapGesture)
            self.timerDiscriptionBalloon.view.isHidden = true
        }
    }
}

extension WrittenPaperViewController {
    private func stackViewConstraints() {
        stackView.snp.makeConstraints({ make in
            make.height.equalTo(36)
        })
    }
    
    private func spinnerConstraints() {
        spinner.snp.makeConstraints({ make in
            make.width.equalTo(deviceWidth)
            make.height.equalTo(deviceHeight)
        })
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
            make.top.equalTo(50)
            make.width.equalTo(224)
            make.height.equalTo(81)
        }
    }
}
