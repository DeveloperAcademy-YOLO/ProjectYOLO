//
//  MagnifiedCardViewController.swift
//  RollingPaper
//
//  Created by SeungHwanKim on 2022/10/26.
//

import Foundation
import UIKit
import SnapKit
import Combine

class MagnifiedCardViewController: UIViewController {
    private var viewModel: WrittenPaperViewModel = WrittenPaperViewModel()
    private var cancellables = Set<AnyCancellable>()
    //상위 뷰 에서 접근해야하는 변수
    var selectedCardIndex: Int = 0
    private var deviceWidth = UIScreen.main.bounds.size.width
    private var deviceHeight = UIScreen.main.bounds.size.height
    private lazy var closeBtn: UIButton = UIButton()
    lazy private var cardsCollectionView: UICollectionView = {
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 80, left: 155, bottom: 80, right: 155 )
        layout.itemSize = CGSize(width: (deviceHeight - 160)*(4/3), height: deviceHeight - 160)
        layout.minimumLineSpacing = 60
        layout.scrollDirection = .horizontal
        
        cardsCollectionView = UICollectionView(frame: CGRect(x: 0, y: 80, width: deviceWidth, height: deviceHeight-160), collectionViewLayout: layout)
        cardsCollectionView.showsHorizontalScrollIndicator = false
        cardsCollectionView.decelerationRate = .fast
        cardsCollectionView.isPagingEnabled = false
        cardsCollectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "MyCell")
        cardsCollectionView.dataSource = self
        cardsCollectionView.delegate = self
        cardsCollectionView.scrollToItem(at: [0, selectedCardIndex], at: .centeredHorizontally, animated: true)
        
        return cardsCollectionView
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.isOpaque = false
        view.backgroundColor = .clear
        view.addSubview(closeBtn)
        view.addSubview(cardsCollectionView)
        setCloseBtn()
    }
    
    @objc func closeAction() {
        dismiss(animated: true)
    }
}

extension MagnifiedCardViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.currentPaper?.cards.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let myCell = collectionView.dequeueReusableCell(withReuseIdentifier: "MyCell", for: indexPath)
        myCell.layer.cornerRadius = 60
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



extension MagnifiedCardViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        guard let layout = self.cardsCollectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }
        
        // 페이징의 단위가 되는 너비를 결정
        let cellWidthIncludingSpacing = layout.itemSize.width + layout.minimumLineSpacing
        
        // 이동한 x좌표 값과 item의 크기를 비교 후 페이징 값 설정
        let estimatedIndex = scrollView.contentOffset.x / cellWidthIncludingSpacing
        let index: Int
        
        // 움직이는 방향대로 카드가 넘어가도록 결정
        if velocity.x > 0 {
            index = Int(ceil(estimatedIndex))
        } else if velocity.x < 0 {
            index = Int(floor(estimatedIndex))
        } else {
            index = Int(round(estimatedIndex))
        }
        // 위 코드를 통해 페이징 될 좌표 값을 targetContentOffset에 대입
        targetContentOffset.pointee = CGPoint(x: CGFloat(index) * cellWidthIncludingSpacing, y: 0)
    }
}

extension MagnifiedCardViewController {
    func setCloseBtn() {
        closeBtn.addTarget(self, action: #selector(closeAction), for: UIControl.Event.touchUpInside)
        closeBtn.snp.makeConstraints { make in
            make.top.equalTo(self.view)
            make.width.equalTo(deviceWidth)
            make.height.equalTo(deviceHeight)
        }
    }
    
    
}
