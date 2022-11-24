//
//  GiftPaperViewController.swift
//  RollingPaper
//
//  Created by Junyeong Park on 2022/11/15.
//

import UIKit

class GiftPaperViewController: UIViewController {
    private let deviceWidth = UIScreen.main.bounds.size.width
    private let deviceHeight = UIScreen.main.bounds.size.height
    
    lazy var leftButton: UIBarButtonItem = {
        let customBackBtnImage = UIImage(systemName: "chevron.backward")?.withTintColor(UIColor(named: "customBlack") ?? UIColor(red: 100, green: 100, blue: 100), renderingMode: .alwaysOriginal)
        let customBackBtn = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 23))
        customBackBtn.setTitle("선물 상자", for: .normal)
        customBackBtn.titleLabel?.font = UIFont.systemFont(ofSize: 20)
        customBackBtn.setTitleColor(.black, for: .normal)
        customBackBtn.setImage(customBackBtnImage, for: .normal)
        customBackBtn.addLeftPadding(5)
        customBackBtn.addTarget(self, action: #selector(cancelBtnPressed(_:)), for: .touchUpInside)
        let button = UIBarButtonItem(customView: customBackBtn)
        return button
    }()
    
    lazy private var giftImage: UIImageView = {
        let giftImage = UIImageView()
        giftImage.image = UIImage(systemName: "giftcard.fill")?.resized(to: CGSize(width: 32, height: 22))
        giftImage.tintColor = .black
        giftImage.contentMode = .scaleAspectFit
        return giftImage
    }()
    
    lazy private var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.frame = CGRect(x: 0, y: 0, width: 400, height: 36)
        titleLabel.textAlignment = .center
   //     titleLabel.text = viewModel.currentPaperPublisher.value?.title
        titleLabel.text = "선물 받은 페이퍼"
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
        navigationItem.titleView = stackView
        stackViewConstraints()
        titleLabelConstraints()

        view.backgroundColor = .blue
        self.splitViewController?.hide(.primary)
        setCustomNavBarButtons()
        
        view.addSubview(cardsList)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.splitViewController?.hide(.primary)
       // cardsList.reloadData()
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
        return 100 // How many cells to display
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let myCell = collectionView.dequeueReusableCell(withReuseIdentifier: "MyCell", for: indexPath)
        myCell.backgroundColor = UIColor.blue
        myCell.layer.cornerRadius = 12
        myCell.layer.masksToBounds = true
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
