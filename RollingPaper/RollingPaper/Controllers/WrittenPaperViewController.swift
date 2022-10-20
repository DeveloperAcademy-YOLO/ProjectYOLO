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
    lazy private var viewModel: WrittenPaperViewModel = WrittenPaperViewModel()
    private var cardsList: UICollectionView?
    
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
        let timeLabel = BasePaddingLabel()
        //   timeLabel.frame = CGRect(x: 0, y: 0, width: 120, height: 36)
        timeLabel.textAlignment = .center
        
        let imageAttachment = NSTextAttachment()
        imageAttachment.image = UIImage(systemName: "timer")?.withTintColor(.white)
        imageAttachment.bounds = CGRect(x: 0, y: -5, width: 20, height: 20)
        let attachmentString = NSAttributedString(attachment: imageAttachment)
        let completeText = NSMutableAttributedString(string: "")
        completeText.append(attachmentString)
        let textAfterIcon = NSAttributedString(string: "  " + "99:99")
        completeText.append(textAfterIcon)
        timeLabel.attributedText = completeText
        
        timeLabel.font = UIFont.preferredFont(for: UIFont.TextStyle.body, weight: UIFont.Weight.bold)
        timeLabel.textColor = .white
        timeLabel.layer.cornerRadius = 18
        timeLabel.layer.backgroundColor = UIColor.systemGray4.cgColor
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        self.splitViewController?.hide(.primary)
        self.navigationController?.navigationBar.tintColor = .systemGray
        
        navigationItem.titleView = stackView
        setCustomNavBarButtons()
        self.cardsList = setCollectionView()
        view.addSubview(self.cardsList ?? UICollectionView())
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.splitViewController?.hide(.primary)
        cardsList?.reloadData()
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
        
        let paperLinkBtnImage = UIImage(systemName: "square.and.arrow.up")!.resized(to: CGSize(width: 30, height: 30))
        paperLinkBtnImage.withTintColor(.systemBlue)
        let paperLinkBtn = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        paperLinkBtn.setImage(paperLinkBtnImage, for: .normal)
        paperLinkBtn.addAction(UIAction(handler: {_ in self.presentSignUpModal(paperLinkBtn)}), for: .touchUpInside)
        
        let createCardBtnImage = UIImage(systemName: "plus.rectangle.fill")!.resized(to: CGSize(width: 40, height: 30))
        let createCardBtn = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        createCardBtn.setImage(createCardBtnImage, for: .normal)
        createCardBtn.addAction(UIAction(handler: {_ in self.moveToCardRootView()}), for: .touchUpInside)
        
        let managePaperBtnImage = UIImage(systemName: "ellipsis.circle")!.resized(to: CGSize(width: 30, height: 30))
        let managePaperBtn = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        managePaperBtn.setImage(managePaperBtnImage, for: .normal)
        managePaperBtn.addAction(UIAction(handler: {_ in self.setPopOverView(managePaperBtn)}), for: .touchUpInside)
        
        let firstBarButton = UIBarButtonItem(customView: customBackBtn)
        let secondBarButton = UIBarButtonItem(customView: managePaperBtn)
        let thirdBarButton = UIBarButtonItem(customView: paperLinkBtn)
        let fourthBarButton = UIBarButtonItem(customView: createCardBtn)
        
        navigationItem.rightBarButtonItems = [fourthBarButton, thirdBarButton, secondBarButton]
        navigationItem.leftBarButtonItem = firstBarButton
    }
    
    func moveToPaperStorageView() {
        if
            let currentVC = self.navigationController?.viewControllers.filter({ $0 is PaperTemplateSelectViewController }).first,
            let splitVC = currentVC.parent?.parent as? SplitViewController {
            splitVC.didSelectCategory(CategoryModel(name: "페이퍼 보관함", icon: "folder"))
        } else if
            let currentVC = self.navigationController?.viewControllers.filter({ $0 is PaperStorageViewController }).first,
            let splitVC = currentVC.parent?.parent as? SplitViewController {
            splitVC.didSelectCategory(CategoryModel(name: "페이퍼 보관함", icon: "folder"))}
    }
    
    func moveToCardRootView() {
        self.navigationController?.pushViewController(CardRootViewController(viewModel: CardViewModel()), animated: true)
    }
    
    func presentSignUpModal(_ sender: UIButton) {
        let signUpVC = SignUpViewController()
        signUpVC.modalPresentationStyle = UIModalPresentationStyle.formSheet
        self.present(signUpVC, animated: true)
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
            let edit = UIAlertAction(title: "수정", style: .default) { (edit) in  }
            let cancel = UIAlertAction(title: "취소", style: .cancel) { (cancel) in }
            alert.addAction(cancel)
            alert.addAction(edit)
            alert.addTextField{ (editTitleTextField) in
                editTitleTextField.text = "dummy text"
            }
            self.present(alert, animated: true, completion: nil)
        }))
        allertController.addAction(UIAlertAction(title: "마감", style: .default,
                                                 handler: {_ in
            print("마감")
            let alert = UIAlertController(title: "페이퍼 마감", message: "마감하면 더이상 메세지 카드를 남길 수 없습니다. 마감하시겠어요?", preferredStyle: .alert)
            let stop = UIAlertAction(title: "마감", style: .default) { (stop) in  }
            let cancel = UIAlertAction(title: "취소", style: .cancel) { (cancel) in }
            alert.addAction(cancel)
            alert.addAction(stop)
            self.present(alert, animated: true, completion: nil)
        }))
        allertController.addAction(UIAlertAction(title: "삭제", style: .destructive,
                                                 handler: {_ in
            print("삭제")
            let alert = UIAlertController(title: "페이퍼 삭제", message: "페이퍼를 삭제하려면 페이퍼 제목을 하단에 입력해주세요.", preferredStyle: .alert)
            let delete = UIAlertAction(title: "삭제", style: .destructive) { (delete) in  }
            let cancel = UIAlertAction(title: "취소", style: .cancel) { (cancel) in }
            alert.addAction(delete)
            alert.addAction(cancel)
            alert.addTextField{ (editTitleTextField) in
                editTitleTextField.placeholder = "재현이의 생일을 축하하며"
            }
            self.present(alert, animated: true, completion: nil)
        }))
        
        allertController.setValue(attributedTitleString, forKey: "attributedTitle")
        allertController.setValue(attributedMessageString, forKey: "attributedMessage")
        
        let popover = allertController.popoverPresentationController
        popover?.sourceView = sender
        popover?.backgroundColor = UIColor.white
        present(allertController, animated: true)
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
        return 9 // How many cells to display
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
