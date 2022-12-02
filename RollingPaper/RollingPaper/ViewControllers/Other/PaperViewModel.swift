//
//  PaperViewModel.swift
//  RollingPaper
//
//  Created by Junyeong Park on 2022/12/02.
//

import UIKit
import Combine

class PaperViewModel {
    enum PaperSource {
        case fromServer
        case fromLocal
    }
    
    enum Input {
        case changeTitle(title: String)
        case changeTime(time: Date)
        case deletePaperDidTap
        case moveDidTap
        case refreshDidTap
        case shareDidTap
        case giftDidTap
    }
    
    enum Output {
        case moveToStorage
        case link(url: URL)
    }
    
    let paper: CurrentValueSubject<PaperModel?, Never> = .init(nil)
    let currentUser: CurrentValueSubject<UserModel?, Never> = .init(nil)
    private let serverManager = FirestoreManager.shared
    private let localManager = LocalDatabaseFileManager.shared
    private let authManager = FirebaseAuthManager.shared
    private var cancellables = Set<AnyCancellable>()
    private var paperSource: PaperSource?
    private var dataSource: PaperCollectionViewDataSource?
    private var snapshot: NSDiffableDataSourceSnapshot<Section, CardModel>?
    private let output: PassthroughSubject<Output, Never> = .init()
    
    private func bind() {
        localManager.paperSubject
            .combineLatest(serverManager.paperSubject)
            .sink { [weak self] localPaper, serverPaper in
                if let serverPaper = serverPaper {
                    self?.paper.send(serverPaper)
                    self?.paperSource = .fromServer
                    self?.updateDataSource(cards: serverPaper.cards)
                } else if let localPaper = localPaper {
                    print("bbb localPaper: \(localPaper)")
                    self?.paper.send(localPaper)
                    self?.paperSource = .fromLocal
                    self?.updateDataSource(cards: localPaper.cards)
                } else {
                    self?.paper.send(nil)
                    self?.paperSource = nil
                }
            }
            .store(in: &cancellables)
        authManager
            .userProfileSubject
            .sink { [weak self] user in
                self?.currentUser.send(user)
            }
            .store(in: &cancellables)
    }
    
    private func updateDataSource(cards: [CardModel]) {
        guard let dataSource = dataSource else {
            print("bbb dataSource return")
            return
        }
        snapshot = .init()
        guard var snapshot = snapshot else { return }
        snapshot.deleteAllItems()
        snapshot.appendSections(Section.allCases)
        snapshot.appendItems(cards)
        dataSource.apply(snapshot, animatingDifferences: true)
    }
    
    func transform(collectionView: UICollectionView, input: AnyPublisher<Input, Never>) -> AnyPublisher<Output, Never> {
        dataSource = PaperCollectionViewDataSource(collectionView: collectionView, cellProvider: { [weak self] collectionView, indexPath, model in
            guard
                let paperSource = self?.paperSource,
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PaperCollectionViewCell.identifier, for: indexPath) as? PaperCollectionViewCell else {
                return nil
            }
            cell.configure(with: model, paperSource: paperSource)
            return cell
        })
        input
            .sink { [weak self] result in
                switch result {
                case .changeTitle(title: let title): self?.handleChangeTitle(title: title)
                case .changeTime(time: let time): self?.handleChangeTime(time: time)
                case .deletePaperDidTap:
                    self?.handleDeletePaper()
                    self?.output.send(.moveToStorage)
                case .moveDidTap:
                    self?.handleUpdatePaper()
                    self?.output.send(.moveToStorage)
                case .refreshDidTap: self?.handleRefreshPaper()
                case .shareDidTap: break
                case .giftDidTap: break
                }
            }
            .store(in: &cancellables)
        bind()
        
        return output.eraseToAnyPublisher()
    }
    
    private func handleChangeTitle(title: String) {
        guard
            var paper = paper.value,
            let dataSource = paperSource else { return }
        paper.title = title
        switch dataSource {
        case .fromLocal: localManager.updatePaper(paper: paper)
        case .fromServer: serverManager.updatePaper(paper: paper)
        }
    }
    
    private func handleChangeTime(time: Date) {
        guard
            var paper = paper.value,
            let dataSource = paperSource else { return }
        paper.endTime = time
        switch dataSource {
        case .fromLocal: localManager.updatePaper(paper: paper)
        case .fromServer: serverManager.updatePaper(paper: paper)
        }
    }
    
    private func handleDeletePaper() {
        guard
            let paper = paper.value,
            let dataSource = paperSource else { return }
        switch dataSource {
        case .fromLocal: localManager.removePaper(paperId: paper.paperId)
        case .fromServer: serverManager.removePaper(paperId: paper.paperId)
        }
    }
    
    private func handleRefreshPaper() {
        guard
            let paper = paper.value,
            let dataSource = paperSource else { return }
        switch dataSource {
        case .fromLocal: localManager.fetchPaper(paperId: paper.paperId)
        case .fromServer: serverManager.fetchPaper(paperId: paper.paperId)
        }
    }
    
    private func handleResetPaper() {
        guard let dataSource = paperSource else { return }
        switch dataSource {
        case .fromLocal: localManager.resetPaper()
        case .fromServer: serverManager.resetPaper()
        }
    }
    
    private func handleUpdatePaper() {
        guard
            let paper = paper.value,
            let dataSource = paperSource else { return }
        switch dataSource {
        case .fromLocal: localManager.updatePaper(paper: paper)
        case .fromServer: serverManager.updatePaper(paper: paper)
        }
    }
}
