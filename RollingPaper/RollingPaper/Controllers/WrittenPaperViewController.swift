//
//  WrittenPaperViewController.swift
//  RollingPaper
//
//  Created by SeungHwanKim on 2022/10/12.
//

import Foundation
import UIKit
import SnapKit
import Combine

class WrittenPaperViewController: UIViewController {
    private var viewModel: WrittenPaperViewModel = WrittenPaperViewModel()
    private var cardsList: UICollectionView?
    lazy private var titleEmbedingTextField: UITextField = UITextField()
    lazy private var changedPaperTitle: String = ""
    
    
    let authManager: AuthManager = FirebaseAuthManager.shared
    private let currentUserSubject = PassthroughSubject<UserModel?, Never>()
    var currentUser: UserModel?
    var currentPaper: PaperModel?
    var urlToShare: [URL]?
    
    lazy private var titleLabel: BasePaddingLabel = {
        let titleLabel = BasePaddingLabel()
        //titleLabel.frame = CGRect(x: 0, y: 0, width: 400, height: 36)
        titleLabel.textAlignment = .left
        titleLabel.text = viewModel.currentPaper?.title
        titleLabel.sizeToFit()
        titleLabel.font = UIFont.preferredFont(for: UIFont.TextStyle.title3, weight: UIFont.Weight.bold)
        titleLabel.numberOfLines = 1
        return titleLabel
    }()
    
    lazy private var timeLabel: BasePaddingLabel = {
        let now: Date = Date()
        //이거 야매라서 리팩토링 해야함
        let timeInterval = Int(viewModel.currentPaper?.endTime.timeIntervalSince(now) ?? 3600*2-1)
        let timeLabel = BasePaddingLabel()
        
        //   timeLabel.frame = CGRect(x: 0, y: 0, width: 120, height: 36)
        timeLabel.textAlignment = .center
        
        let imageAttachment = NSTextAttachment()
        imageAttachment.image = UIImage(systemName: "timer")?.withTintColor(.white)
        imageAttachment.bounds = CGRect(x: 0, y: -5, width: 20, height: 20)
        let attachmentString = NSAttributedString(attachment: imageAttachment)
        let completeText = NSMutableAttributedString(string: "")
        completeText.append(attachmentString)
        let textAfterIcon = timeInterval > 0
                ? NSAttributedString(string: "  " + "\(changeTimeFormat(second: timeInterval))")
                : NSAttributedString(string: "  " + "\(changeTimeFormat(second: 0))")
        completeText.append(textAfterIcon)
        timeLabel.attributedText = completeText
        
        timeLabel.font = UIFont.preferredFont(for: UIFont.TextStyle.body, weight: UIFont.Weight.bold)
        timeLabel.textColor = .white
        timeLabel.layer.cornerRadius = 18
        timeLabel.layer.backgroundColor = timeInterval > 0
                ? UIColor(rgb: 0xADADAD).cgColor
                : UIColor(rgb: 0xFF3B30).cgColor
        
        func changeTimeFormat(second: Int) -> String {
            let hour = Int(second/3600)
            let minute = Int((second - (hour*3600))/60)
            var hourString = String(hour)
            var minuteString = String(minute)
            if hourString.count == 1 {
                hourString = "0" + hourString
            }
            if minuteString.count == 1 {
                minuteString = "0" + minuteString
            }
            return hourString + ":" + minuteString
        }
        return timeLabel
    }()
    
    lazy private var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = NSLayoutConstraint.Axis.horizontal
        stackView.distribution = UIStackView.Distribution.equalSpacing
        stackView.addArrangedSubview(self.timeLabel)
        timeLabelConstraints()
        stackView.addArrangedSubview(self.titleLabel)
        titleLabelConstraints()
        return stackView
    }()
    
    private var cancellables = Set<AnyCancellable>()
    
    func getCurrentUserAndPaper() {
        viewModel
            .currentUserSubject
            .receive(on: DispatchQueue.main)
            .sink{ [weak self] userProfile in
                if let userProfile = userProfile {
                    self?.currentUser = userProfile
                }
            }
            .store(in: &cancellables)
        
        viewModel
            .currentPaperPublisher
            .receive(on: DispatchQueue.main)
            .sink{ [weak self] paperModel in
                if let paperModel = paperModel {
                    self?.titleLabel.text = paperModel.title
                    self?.currentPaper = paperModel
                }
            }
            .store(in: &cancellables)
//        guard let paper = viewModel.currentPaper else {return}
//        getPaperShareLink(with: paper, route: .write)
//            .sink { (completion) in
//                switch completion {
//                case .finished: break
//                case .failure(let error): print(error)
//                }
//            } receiveValue: { [weak self] url in
//                self?.urlToShare = [url]
//            }
//            .store(in: &cancellables)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        self.splitViewController?.hide(.primary)
        self.navigationController?.navigationBar.tintColor = .systemGray
        getCurrentUserAndPaper()
        navigationItem.titleView = stackView
        setCustomNavBarButtons()
        self.cardsList = setCollectionView()
        view.addSubview(self.cardsList ?? UICollectionView())
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.splitViewController?.hide(.primary)
        cardsList?.reloadData()
        getCurrentUserAndPaper()
        currentPaper?.creator = currentUser
        applyPaperLink()
    }
    
    private func applyPaperLink() {
        guard let paper = viewModel.currentPaper else {return}
        getPaperShareLink(with: paper, route: .write)
            .sink { (completion) in
                switch completion {
                case .finished: break
                case .failure(let error): print(error)
                }
            } receiveValue: { [weak self] url in
                self?.urlToShare = [url] // 실제 페이퍼나 앱의 링크가 들어가는 곳
            }
            .store(in: &cancellables)
    }
    
    private func titleLabelConstraints() {
        titleLabel.snp.makeConstraints({ make in
            make.height.equalTo(36)
            make.leading.equalTo(timeLabel.snp.trailing).offset(10)
        })
    }
    
    private func timeLabelConstraints() {
        timeLabel.snp.makeConstraints({ make in
            make.width.equalTo(120)
            make.height.equalTo(36)
        })
    }
    
    func setCustomNavBarButtons() {
        let customBackBtnImage = UIImage(systemName: "chevron.backward")
        let customBackBtn = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 23))
        customBackBtn.setTitle("보관함", for: .normal)
        customBackBtn.setTitleColor(.systemGray, for: .normal)
        customBackBtn.setImage(customBackBtnImage, for: .normal)
        customBackBtn.addAction(UIAction(handler: {_ in self.moveToPaperStorageView()}), for: .touchUpInside)
        customBackBtn.addLeftPadding(5)
        
        let managePaperBtnImage = UIImage(systemName: "ellipsis.circle")!.resized(to: CGSize(width: 30, height: 30))
        let managePaperBtn = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        managePaperBtn.setImage(managePaperBtnImage, for: .normal)
        managePaperBtn.addAction(UIAction(handler: {_ in self.setPopOverView(managePaperBtn)}), for: .touchUpInside)
        
        let paperLinkBtnImage = UIImage(systemName: "square.and.arrow.up")!.resized(to: CGSize(width: 30, height: 30))
        paperLinkBtnImage.withTintColor(.systemBlue)
        let paperLinkBtn = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        paperLinkBtn.setImage(paperLinkBtnImage, for: .normal)
        paperLinkBtn.addAction(UIAction(handler: {_ in
            if self.viewModel.currentUser != nil {
                self.presentShareSheet(paperLinkBtn)
                print(self.viewModel.currentUser)
            } else {
                self.presentSignUpModal(paperLinkBtn)
                print(self.viewModel.currentUser)
            }
        }), for: .touchUpInside)
        
        let createCardBtnImage = UIImage(systemName: "plus.rectangle.fill")!.resized(to: CGSize(width: 40, height: 30))
        let createCardBtn = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        createCardBtn.setImage(createCardBtnImage, for: .normal)
        createCardBtn.addAction(UIAction(handler: {_ in self.moveToCardRootView()}), for: .touchUpInside)
        
        let firstBarButton = UIBarButtonItem(customView: customBackBtn)
        let secondBarButton = UIBarButtonItem(customView: managePaperBtn)
        let thirdBarButton = UIBarButtonItem(customView: paperLinkBtn)
        let fourthBarButton = UIBarButtonItem(customView: createCardBtn)
        
        let signInSetting: [UIBarButtonItem] = [fourthBarButton, thirdBarButton, secondBarButton]
        let signOutSetting: [UIBarButtonItem] = [fourthBarButton, thirdBarButton]
        
        navigationItem.rightBarButtonItems = currentUser?.email == currentPaper?.creator?.email ? signInSetting : signOutSetting
        navigationItem.leftBarButtonItem = firstBarButton
    }
    
    private func moveToPaperStorageView() {
        NotificationCenter.default.post(
            name: Notification.Name.viewChange,
            object: nil,
            userInfo: [NotificationViewKey.view: "페이퍼 보관함"]
        )
    }
    
    func moveToCardRootView() {
           var isLocalDB: Bool
           if viewModel.paperFrom == .fromLocal {
               isLocalDB = true
           } else {
               isLocalDB = false
           }
           
           self.navigationController?.pushViewController(CardRootViewController(viewModel: CardViewModel(), isLocalDB: isLocalDB), animated: true) // TODO:
       }
    
    func presentSignUpModal(_ sender: UIButton) {
        let signInVC = SignInViewController()
        
        let navVC = UINavigationController(rootViewController: signInVC)
        navVC.modalPresentationStyle = .formSheet //모달에 x버튼 넣기 위함
        present(navVC, animated: true)
        
        authManager
            .signedInSubject
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { receivedValue in
                if receivedValue == .signInSucceed {
                    navVC.dismiss(animated: true)
                }
            })
            .store(in: &cancellables)
    }
    
    func presentShareSheet(_ sender: UIButton) {
        let text = "dummy text. 여기에 소개 멘트가 들어갈 자리입니다. 페이퍼를 공유해보세요~~ 등등"
        //TODO : 카톡으로 공유하기
        let applicationActivities: [UIActivity]? = nil
        let activityViewController = UIActivityViewController(
            activityItems: self.urlToShare ?? [],
            applicationActivities: applicationActivities)
        
        activityViewController.excludedActivityTypes = [ UIActivity.ActivityType.airDrop, UIActivity.ActivityType.postToFacebook ]
        
        let popover = activityViewController.popoverPresentationController
        popover?.sourceView = sender
        self.present(activityViewController, animated: true)
    }
    
    func setPopOverView(_ sender: UIButton) {
        let attributedTitleString = NSAttributedString(string: "페이지 관리", attributes: [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15),
            NSAttributedString.Key.strokeWidth: -5 ])
        let attributedMessageString = NSAttributedString(string: "정보를 수정하거나 삭제할 수 있습니다.", attributes: [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15) ])
        
        let allertController = UIAlertController(title: "", message: "", preferredStyle: .actionSheet)
        
        allertController.addAction(UIAlertAction(title: "수정", style: .default,
                                                 handler: {_ in
            print("수정")
            let alert = UIAlertController(title: "페이퍼 제목 수정", message: "", preferredStyle: .alert)
            let edit = UIAlertAction(title: "수정", style: .default) { (edit) in
                if let changedPaperTitle = self.titleEmbedingTextField.text {
                    //self.viewModel.changePaperTitle(input: changedPaperTitle, from: .fromLocal)
                    print(changedPaperTitle)
                    //이거 아직 subscribe에 전달 안 해줘서 실시간으로 바뀌진 않음
                }
            }
            let cancel = UIAlertAction(title: "취소", style: .cancel)
            alert.addAction(cancel)
            alert.addAction(edit)
            alert.addTextField { (editTitleTextField) in
                editTitleTextField.text = self.viewModel.currentPaper?.title
            }
            alert.preferredAction = edit
            self.present(alert, animated: true, completion: nil)
        }))
        allertController.addAction(UIAlertAction(title: "마감", style: .default,
                                                 handler: {_ in
            print("마감")
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
            print("삭제")
            let alert = UIAlertController(title: "페이퍼 삭제", message: "페이퍼를 삭제하려면 페이퍼 제목을 하단에 입력해주세요.", preferredStyle: .alert)
            let delete = UIAlertAction(title: "삭제", style: .destructive) { _ in
                self.deletePaper()
            }
            let cancel = UIAlertAction(title: "취소", style: .cancel)
            alert.addAction(delete)
            alert.addAction(cancel)
            alert.preferredAction = delete
            alert.addTextField { (deleteTitleTextField) in
                self.titleEmbedingTextField = deleteTitleTextField
                deleteTitleTextField.placeholder = self.viewModel.currentPaper?.title
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
    
    func deletePaper() {
        let deleteVerifyText = self.titleEmbedingTextField.text
        if deleteVerifyText == self.viewModel.currentPaper?.title {
            if viewModel.isPaperLinkMade{
                viewModel.deletePaper(viewModel.currentPaper!.paperId, from: .fromServer)
            }
            else {
                viewModel.deletePaper(viewModel.currentPaper!.paperId, from: .fromLocal)
            }
            self.moveToPaperStorageView()
        } else {
            let alert = UIAlertController(title: "제목을 잘못 입력하셨습니다", message: nil, preferredStyle: .alert)
            let confirm = UIAlertAction(title: "확인", style: .default)
            alert.addAction(confirm)
            alert.preferredAction = confirm
            self.present(alert, animated: true, completion: nil)
        }
        
    }
    
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
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let myCell = collectionView.dequeueReusableCell(withReuseIdentifier: "MyCell", for: indexPath)
        myCell.backgroundColor = UIColor.blue
        myCell.layer.cornerRadius = 12
        myCell.layer.masksToBounds = true
        return myCell
    }
}
extension WrittenPaperViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("User tapped on item \(indexPath.row)")
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
    }
}
