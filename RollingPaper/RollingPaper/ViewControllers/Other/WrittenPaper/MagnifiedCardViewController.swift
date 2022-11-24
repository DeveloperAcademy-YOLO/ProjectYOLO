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
    private lazy var closeBtn1: UIButton = UIButton()
    private lazy var closeBtn2: UIButton = UIButton()
    lazy private var cardsCollectionView: UICollectionView = {
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 80, left: 155, bottom: 80, right: 155 )
        layout.itemSize = CGSize(width: (deviceHeight - 160)*(4/3), height: deviceHeight - 160)
        layout.minimumLineSpacing = 60
        layout.scrollDirection = .horizontal
        
        cardsCollectionView = UICollectionView(frame: CGRect(x: 0, y: 0, width: deviceWidth, height: deviceHeight), collectionViewLayout: layout)
        cardsCollectionView.showsHorizontalScrollIndicator = false
        cardsCollectionView.backgroundColor = .clear
        cardsCollectionView.decelerationRate = .fast
        cardsCollectionView.isPagingEnabled = false
        cardsCollectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "MyCell")
        cardsCollectionView.dataSource = self
        cardsCollectionView.delegate = self
        cardsCollectionView.scrollToItem(at: [0, selectedCardIndex], at: .centeredHorizontally, animated: true)
        
        return cardsCollectionView
    }()
    
    var backgroundViewController: BlurredViewController!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.isOpaque = false
        view.backgroundColor = .clear
        bind()
        view.addSubview(cardsCollectionView)
        view.addSubview(closeBtn1)
        view.addSubview(closeBtn2)
        setCloseBtn()
        view.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handleDismiss)))
    }
    
    private func bind() {
        closeBtn1
            .tapPublisher
            .sink{ [weak self] in
                self?.dismiss(animated: true)
                self?.backgroundViewController.dismiss(animated: true)
            }
            .store(in: &cancellables)
        
        closeBtn2
            .tapPublisher
            .sink{ [weak self] in
                self?.dismiss(animated: true)
                self?.backgroundViewController.dismiss(animated: true)
            }
            .store(in: &cancellables)
    }
    
    private var viewTranslation = CGPoint(x: 0, y: 0)
    
    @objc func handleDismiss(sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .changed:
            viewTranslation = sender.translation(in: view)
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                self.view.transform = CGAffineTransform(translationX: 0, y: self.viewTranslation.y)
            })
        case .ended:
            if viewTranslation.y < 200 {
                UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                    self.view.transform = .identity
                })
            } else {
                dismiss(animated: true) {
                    self.backgroundViewController.dismiss(animated: true)
                }
            }
        default:
            break
        }
    }
    
    @objc func closeAction() {
        dismiss(animated: true) {
            self.backgroundViewController.dismiss(animated: true)
        }
    }
}

extension MagnifiedCardViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.currentPaperPublisher.value?.cards.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let myCell = collectionView.dequeueReusableCell(withReuseIdentifier: "MyCell", for: indexPath)
        
        myCell.contentView.layer.cornerRadius = 60
        myCell.contentView.layer.borderColor = UIColor.clear.cgColor
        myCell.contentView.layer.masksToBounds = true;
        
        myCell.layer.shadowColor = UIColor.black.cgColor
        myCell.layer.shadowOffset = CGSize(width: 0,height: 2.0)
        myCell.layer.shadowRadius = 60.0
        myCell.layer.shadowOpacity = 0.5
        myCell.layer.masksToBounds = false;
        myCell.layer.shadowPath = UIBezierPath(roundedRect:myCell.bounds, cornerRadius:myCell.contentView.layer.cornerRadius).cgPath
        
        guard let currentPaper = viewModel.currentPaperPublisher.value else { return myCell }
        let card = currentPaper.cards[indexPath.row]
        
        if let image = NSCacheManager.shared.getImage(name: card.contentURLString) {
            let imageView = UIImageView(image: image)
            imageView.layer.cornerRadius = 60
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
        closeBtn1.snp.makeConstraints { make in
            make.top.equalTo(0)
            make.width.equalTo(deviceWidth)
            make.height.equalTo(80)
        }
        
        closeBtn2.snp.makeConstraints { make in
            make.top.equalTo(deviceHeight-80)
            make.width.equalTo(deviceWidth)
            make.height.equalTo(80)
        }
    }
    
    
}
