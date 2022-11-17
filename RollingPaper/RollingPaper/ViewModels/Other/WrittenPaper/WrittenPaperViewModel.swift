//
//  WrittenPaperViewModel.swift
//  RollingPaper
//
//  Created by SeungHwanKim on 2022/10/20.
//

import Foundation
import UIKit
import Combine

class WrittenPaperViewModel {
    
    let localDatabaseManager: DatabaseManager = LocalDatabaseFileManager.shared
    let serverDatabaseManager: DatabaseManager = FirestoreManager.shared
    private var cancellables = Set<AnyCancellable>()
    let authManager: AuthManager = FirebaseAuthManager.shared
    let currentUserSubject: CurrentValueSubject<UserModel?, Never> = .init(nil)
    var currentUser: UserModel?
    
    enum DataSource {
        case fromLocal
        case fromServer
    }
    
    var currentPaper: PaperModel?
    let currentPaperPublisher: CurrentValueSubject<PaperModel?, Never> = .init(nil)
    var paperFrom: DataSource?
    private var paperID: String = ""
    private var paperTemplate: TemplateModel?
    private var paperTitle: String?
    var isTitleChanged: Bool = false
    private var timeRemaing: Date?
    
    var isPaperLinkMade: Bool = false
    var isSameCurrentUserAndCreator: Bool = false
    private var paperLinkForShare: String?
    
    private var isPaperStopped: Bool?
    
    private var cards: [CardModel] = []
    
    init() {
        setCurrentUser()
        setCurrentPaper()
    }
    
    func setCurrentUser() {
        authManager
            .userProfileSubject
            .receive(on: DispatchQueue.global(qos: .background))
            .sink { [weak self] userProfile in
                guard let self = self else { return }
                self.currentUser = userProfile
            }
            .store(in: &cancellables)
    }
    
    func setCurrentPaper() {
        self.localDatabaseManager.paperSubject
            .sink(receiveValue: { [weak self] paper in
                if let paper = paper {
                    self?.currentPaper = paper
                    self?.paperFrom = .fromLocal
                    self?.currentPaperPublisher.send(paper)
                }
                else {
                    self?.currentPaperPublisher.send(nil)
                    print("로컬 비었음")
                }
            })
            .store(in: &cancellables)
        
        self.serverDatabaseManager.paperSubject
            .sink(receiveValue: { [weak self] paper in
                if let paper = paper {
                    self?.currentPaper = paper
                    self?.paperFrom = .fromServer
                    self?.currentPaperPublisher.send(paper)
                } else {
                    print("서버 비었음")
                    self?.currentPaperPublisher.send(nil)
                }
            })
            .store(in: &cancellables)
    }
    
    func changePaperTitle(input: String, from paperFrom: DataSource) {
        currentPaper?.title = input
        isTitleChanged = true
        guard let paper = currentPaper else { return }
        switch paperFrom {
        case .fromLocal:
            print("from local: \(paper.title)")
            localDatabaseManager.updatePaper(paper: paper)
            currentPaperPublisher.send(paper)
        case .fromServer:
            serverDatabaseManager.updatePaper(paper: paper)
            currentPaperPublisher.send(paper)
        }
    }
    
    func getRemainingTime(_ paperID: String) {}
    
    func deleteCard(_ card: CardModel, from paperFrom: DataSource) {
        switch paperFrom {
        case .fromLocal:
            localDatabaseManager.removeCard(paperId: paperID, card: card)
        case .fromServer:
            serverDatabaseManager.removeCard(paperId: paperID, card: card)
        }
    }
    
    func showCardDetail() {}
    
    func stopPaper(_ paperID: String, from paperFrom: DataSource) {
        //        switch paperFrom {
        //        case .fromLocal: break
        //
        //        case .fromServer:
        //            <#code#>
        //        }
    }
    
    func deletePaper(_ paperID: String, from paperFrom: DataSource) {
        switch paperFrom {
        case .fromLocal:
            localDatabaseManager.removePaper(paperId: paperID)
            localDatabaseManager.resetPaper()
        case .fromServer:
            serverDatabaseManager.removePaper(paperId: paperID)
            serverDatabaseManager.resetPaper()
        }
        currentPaper = nil
    }
    
    func makePaperLinkToShare(input: URL) {
        currentPaper?.linkUrl = input
        isPaperLinkMade = true
        guard let paper = currentPaper else { return }
        localDatabaseManager.removePaper(paperId: paperID)
        
        var paperSubscription: AnyCancellable?
        paperSubscription = getServerSidePaper(paper: paper)
            .sink(receiveValue: { [weak self] paper in
                self?.serverDatabaseManager.addPaper(paper: paper)
                self?.currentPaperPublisher.send(paper)
                paperSubscription?.cancel()
            })
        
        //링크 만드는 순간 로컬데이터 지워주는 타이밍 얘기해봐야해서 일단 로컬, 서버 둘 다 업뎃하도록 함
    }
    
    private func getServerSidePaper(paper: PaperModel) -> AnyPublisher<PaperModel, Never> {
        // 각 카드의 현재 이미지를 서버에 저장한 뒤 해당 URL 주소를 새롭게 변경한 페이퍼 모델을 리턴
        let temp = paper.cards
        var newCard = [CardModel]()
        var paper = paper
        let tempCardPublisher: CurrentValueSubject<[CardModel], Never> = .init([])
        
        let arrayPublisher = paper
            .cards
            .map { card in
                var cardSubscription: AnyCancellable?
                cardSubscription = setServerSideCard(card: card)
                    .sink(receiveCompletion: { completion in
                        switch completion {
                        case .failure(let error):
                            print(error.localizedDescription)
                            cardSubscription?.cancel()
                        case .finished: break
                        }
                    }, receiveValue: { card in
                        let currentCards = tempCardPublisher.value
                        let newCards = currentCards + [card]
                        tempCardPublisher.send(newCards)
                        cardSubscription?.cancel()
                    })
            }
        return Future { promise in
            tempCardPublisher
                .sink { cardModels  in
                    print("aaa tempCardPublisher: \(cardModels.count)")
                    if cardModels.count == paper.cards.count {
                        paper.cards = cardModels
                        promise(.success(paper))
                    }
                }
                .store(in: &self.cancellables)
        }
        .eraseToAnyPublisher()
    }
    
    private func getImageFromURLString(from urlString: String) -> AnyPublisher<Data?, Error> {
        return Future { promise in
            if
                let image = NSCacheManager.shared.getImage(name: urlString),
                let data = image.jpegData(compressionQuality: 1.0) {
                print("aaa getImageFromURLString from cache")
                promise(.success(data))
            } else {
                var imageSubscription: AnyCancellable?
                imageSubscription = LocalStorageManager
                    .downloadData(urlString: urlString)
                    .sink(receiveCompletion: { completion in
                        switch completion {
                        case .failure(let error): print(error.localizedDescription)
                            promise(.success(nil))
                            imageSubscription?.cancel()
                        case .finished: break
                        }
                    }, receiveValue: { data in
                        promise(.success(data))
                        imageSubscription?.cancel()
                    })
            }
        }
        .eraseToAnyPublisher()
    }
    
    // card -> image data -> server saved url + card return
    private func setServerSideCard(card: CardModel) -> AnyPublisher<CardModel, Error> {
        var imageSubscription: AnyCancellable?
        var card = card
        
        return Future { promise in
            imageSubscription = self.getImageFromURLString(from: card.contentURLString)
                .sink(receiveCompletion: { completion in
                    switch completion {
                    case .failure(let error):
                        print(error.localizedDescription)
                        imageSubscription?.cancel()
                        promise(.failure(error))
                    case .finished: break
                    }
                }, receiveValue: { data in
                    guard let data = data else { return }
                    var uploadSubscription: AnyCancellable?
                    uploadSubscription = FirebaseStorageManager
                        .uploadData(dataId: card.cardId, data: data, contentType: .jpeg, pathRoot: .card)
                        .sink(receiveCompletion: { completion in
                            switch completion {
                            case .finished: break
                            case .failure(let error): print(error.localizedDescription)
                                uploadSubscription?.cancel()
                                promise(.failure(error))
                            }
                        }, receiveValue: { url in
                            guard let urlString = url?.absoluteString else { return }
                            print("aaa setServerSideCard")
                            card.contentURLString = urlString
                            promise(.success(card))
                            uploadSubscription?.cancel()
                        })
                    imageSubscription?.cancel()
                })
        }
        .eraseToAnyPublisher()
    }
}
