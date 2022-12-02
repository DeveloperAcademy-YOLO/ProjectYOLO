//
//  PaperViewController.swift
//  RollingPaper
//
//  Created by Junyeong Park on 2022/12/02.
//

import UIKit
import Combine
import CombineCocoa

class PaperViewController: UIViewController {
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 20
        layout.minimumInteritemSpacing = 20
        layout.sectionInset = .init(top: 25, left: 20, bottom: 25, right: 20)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(PaperCollectionViewCell.self, forCellWithReuseIdentifier: PaperCollectionViewCell.identifier)
        collectionView.delegate = self
        collectionView.alwaysBounceVertical = true
        collectionView.showsVerticalScrollIndicator = false
        return collectionView
    }()
    private var cancellables = Set<AnyCancellable>()
    private let viewModel = PaperViewModel()
    private let input: PassthroughSubject<PaperViewModel.Input, Never> = .init()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUI()
        bind()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionView.frame = view.bounds
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        input.send(.viewDidDisappear)
    }
    
    private func setUI() {
        view.backgroundColor = .systemRed
        view.addSubview(collectionView)
        setNavigationBar()
    }
    
    private func setNavigationBar() {
        
    }
    
    private func bind() {
        let output = viewModel.transform(collectionView: collectionView, input: input.eraseToAnyPublisher())
        output
            .sink { [weak self] result in
                switch result {
                case .moveToStorage:
                    self?.navigationController?.popViewController(animated: true)
                case .link(url: let url):
                    break
                }
            }
            .store(in: &cancellables)
        viewModel.paper
            .combineLatest(viewModel.currentUser)
            .sink { [weak self] paper, user in
                guard let paper = paper else { return }
                if let user = user {
                    if paper.creator == user {
                        
                    } else {
                        
                    }
                } else {
                    
                }
            }
            .store(in: &cancellables)
    }
}

extension PaperViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("selected item")
    }
    
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemsAt indexPaths: [IndexPath], point: CGPoint) -> UIContextMenuConfiguration? {
        print("context menu did tap")
        return nil
    }
}

extension PaperViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (view.frame.width - 80) / 3
        let height = ((view.frame.width - 120) / 3) * 0.75
        return CGSize(width: width, height: height)
    }
}
