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
    var cancellables = Set<AnyCancellable>()
    private let authManager: AuthManager = FirebaseAuthManager.shared
    private let currentUserSubject: CurrentValueSubject<UserModel?, Never> = .init(nil)
    private let output: PassthroughSubject<Output, Never> = .init()
    private var images = [String: UIImage]()
    var currentUser: UserModel?
    
    let currentPaperPublisher: CurrentValueSubject<PaperModel?, Never> = .init(nil)
    var paperFrom: DataSource?
    private var paperID: String = ""
    
    var isPaperLinkMade: Bool = false
    var isSameCurrentUserAndCreator: Bool = false
    
    private var isPaperStopped: Bool?
    
    private var cards: [CardModel] = []
    
    enum DataSource {
        case fromLocal
        case fromServer
    }
    
    enum Input {
        case changePaperTitleTapped(changedTitle: String, from: DataSource)
        case stopPaperTapped
        case deletePaperTapped
        case paperShareTapped
        case giftTapped
        case moveToStorageTapped
        case fetchingPaper
    }
    
    enum Output {
        case cardDeleted
        case paperStopped
        case paperDeleted
        case paperTitleChanged
        case paperLinkMade(url: URL)
        case giftLinkMade(url: URL)
    }
    
    init() {
        setCurrentUser()
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
    
    private func setCurrentPaper() {
        print("setCurrentPaper")
        localDatabaseManager.paperSubject
            .combineLatest(serverDatabaseManager.paperSubject)
            .sink { [weak self] localPaper, serverPaper in
                if let serverPaper = serverPaper {
                    print("aaa serverPaper changed: \(serverPaper.cards.count)")
                    self?.paperFrom = .fromServer
                    self?.currentPaperPublisher.send(serverPaper)
                    self?.downloadServerCards()
                } else if let localPaper = localPaper {
                    self?.paperFrom = .fromLocal
                    self?.currentPaperPublisher.send(localPaper)
                    self?.downloadLocalCards()
                } else {
                    self?.images.removeAll()
                    self?.currentPaperPublisher.send(nil)
                }

            }
            .store(in: &cancellables)
    }
        
    // url을 통해 로컬에 저장되어있는 썸네일 다운받아오기
    private func downloadLocalCards() {
        var downloadCount = 0
        guard let paper = currentPaperPublisher.value else { return }
        for card in paper.cards {
            let urlString = card.contentURLString
            if images[urlString] != nil {
                continue
            }
            
            if let cachedImage = NSCacheManager.shared.getImage(name: urlString) {
                    // 진입 경로1 - 캐시 데이터를 통한 다운로드
                images[card.cardId] = cachedImage
                downloadCount += 1
                // 모든 썸네일을 다운 받는게 완료되면 view controller에게 알려주기
                if downloadCount == paper.cards.count {
                    // 완료 신호
                }
            } else {
                LocalStorageManager.downloadData(urlString: urlString)
                    .receive(on: DispatchQueue.global(qos: .background))
                    .sink(receiveCompletion: { completion in
                        switch completion {
                        case .failure(let error):
                            print(error)
                            downloadCount += 1
                            // 모든 썸네일을 다운 받는게 완료되면 view controller에게 알려주기
                            if downloadCount == paper.cards.count {
                                // 완료 신호
                            }
                        case .finished: break
                        }
                    }, receiveValue: { [weak self] data in
                        guard let self = self else {return}
                        if let data = data,
                           let image = UIImage(data: data) {
                            // 진입 경로2 - 파이어베이스에 접근해서 다운로드
                            self.images[card.cardId] = image
                            NSCacheManager.shared.setImage(image: image, name: urlString)
                        }
                        downloadCount += 1
                        // 모든 썸네일을 다운 받는게 완료되면 view controller에게 알려주기
                        if downloadCount == paper.cards.count {
                            // 완료 신호
                        }
                    })
                    .store(in: &cancellables)
            }
        }
    }
    
    private func downloadServerCards() {
        var downloadCount = 0
        guard let paper = currentPaperPublisher.value else { return }
        for card in paper.cards {
            let urlString = card.contentURLString
            if images[urlString] != nil {
                continue
            }
            
            if let cachedImage = NSCacheManager.shared.getImage(name: urlString) {
                    // 진입 경로1 - 캐시 데이터를 통한 다운로드
                images[card.cardId] = cachedImage
                downloadCount += 1
                // 모든 썸네일을 다운 받는게 완료되면 view controller에게 알려주기
                if downloadCount == paper.cards.count {
                    // 완료 신호
                }
            } else {
                FirebaseStorageManager.downloadData(urlString: urlString)
                    .receive(on: DispatchQueue.global(qos: .background))
                    .sink(receiveCompletion: { completion in
                        switch completion {
                        case .failure(let error):
                            print(error)
                            downloadCount += 1
                            // 모든 썸네일을 다운 받는게 완료되면 view controller에게 알려주기
                            if downloadCount == paper.cards.count {
                                // 완료 신호
                            }
                        case .finished: break
                        }
                    }, receiveValue: { [weak self] data in
                        guard let self = self else {return}
                        if let data = data,
                           let image = UIImage(data: data) {
                            // 진입 경로2 - 파이어베이스에 접근해서 다운로드
                            self.images[card.cardId] = image
                            NSCacheManager.shared.setImage(image: image, name: urlString)
                        }
                        downloadCount += 1
                        // 모든 썸네일을 다운 받는게 완료되면 view controller에게 알려주기
                        if downloadCount == paper.cards.count {
                            // 완료 신호
                        }
                    })
                    .store(in: &cancellables)
            }
        }
    }
    
    
    func transform(inputFromVC: AnyPublisher<Input, Never>) -> AnyPublisher<Output, Never> {
        inputFromVC
            .sink{ [weak self] receivedValue in
                guard let self = self else { return }
                switch receivedValue {
                case .changePaperTitleTapped(changedTitle: let changedTitle, from: .fromServer):
                    self.changePaperTitle(input: changedTitle, from: .fromServer)
                    self.output.send(.paperTitleChanged)
                case .changePaperTitleTapped(changedTitle: let changedTitle, from: .fromLocal):
                    self.changePaperTitle(input: changedTitle, from: .fromLocal)
                    self.output.send(.paperTitleChanged)
                case .stopPaperTapped:
                    self.stopPaper()
                case .deletePaperTapped:
                    self.deletePaper(self.currentPaperPublisher.value?.paperId ?? "")
                    self.output.send(.paperDeleted)
                case .paperShareTapped:
                    self.makePaperShareLink()
                case .giftTapped:
                    self.makePaperGiftLink()
                case .moveToStorageTapped:
                    self.cleanPaperPublisher()
                case .fetchingPaper:
                    self.setCurrentPaper()
                }
            }
            .store(in: &cancellables)
        return output.eraseToAnyPublisher()
    }
    
    private func cleanPaperPublisher() {
        //링크를 공유 받고 아무 조작을 하지 않고 보관함으로 가더라도 공유받은 사람의 로컬에 쌓이도록하기 위함
        guard let paper = currentPaperPublisher.value else { return }
        if paper.linkUrl != nil {
            serverDatabaseManager.updatePaper(paper: paper)
            localDatabaseManager.updatePaper(paper: paper)
        }
        currentPaperPublisher.value = nil
        localDatabaseManager.resetPaper()
        serverDatabaseManager.resetPaper()
        cancellables.removeAll()
    }

    private func changePaperTitle(input: String, from paperFrom: DataSource) {
        guard var paper = currentPaperPublisher.value else { return }
        paper.title = input
        switch paperFrom {
        case .fromLocal:
            localDatabaseManager.updatePaper(paper: paper)
        case .fromServer:
            serverDatabaseManager.updatePaper(paper: paper)
        }
        currentPaperPublisher.send(paper)
    }
    
    func deleteCard(_ card: CardModel, from paperFrom: DataSource) {
        switch paperFrom {
        case .fromLocal:
            localDatabaseManager.removeCard(paperId: paperID, card: card)
        case .fromServer:
            serverDatabaseManager.removeCard(paperId: paperID, card: card)
        }
    }
    
    private func stopPaper() {
        guard let time = currentPaperPublisher.value?.date else {return}
        currentPaperPublisher.value?.endTime = time
        guard let currentPaper = currentPaperPublisher.value else {return}
        if self.isPaperLinkMade { //링크가 만들어진 것이 맞다면 서버에도 페이퍼가 저장되어있으므로
            serverDatabaseManager.updatePaper(paper: currentPaper)
            localDatabaseManager.updatePaper(paper: currentPaper)
        } else {
            localDatabaseManager.updatePaper(paper: currentPaper)
        }
        currentPaperPublisher.send(currentPaper)
        self.output.send(.paperStopped)
    }
    
    private func deletePaper(_ paperID: String) {
        if self.isPaperLinkMade { //링크가 만들어진 것이 맞다면 서버에도 페이퍼가 저장되어있으므로
            localDatabaseManager.removePaper(paperId: paperID)
            localDatabaseManager.resetPaper()
            serverDatabaseManager.removePaper(paperId: paperID)
            serverDatabaseManager.resetPaper()
        } else {
            localDatabaseManager.removePaper(paperId: paperID)
            localDatabaseManager.resetPaper()
        }
        currentPaperPublisher.send(nil)
    }
    
    private func makePaperShareLink() {
        if let url = currentPaperPublisher.value?.linkUrl {
            output.send(.paperLinkMade(url: url))
            return
        }
        guard
            let currentPaper = currentPaperPublisher.value,
            paperFrom == .fromLocal else { return }
        var paperSubscription: AnyCancellable?
        paperSubscription = getServerSidePaper(paper: currentPaper)
            .sink { serverPaper in
                var linkSubscription: AnyCancellable?
                var serverPaper = serverPaper
                if let thumbnailURLSgtring = serverPaper.cards.randomElement()?.contentURLString {
                    serverPaper.thumbnailURLString = thumbnailURLSgtring
                }
                linkSubscription = getPaperShareLink(with: serverPaper, route: .write)
                    .sink { completion in
                    } receiveValue: { [weak self] url in
                        self?.isPaperLinkMade = true
                        self?.localDatabaseManager.resetPaper()
                        serverPaper.linkUrl = url
                        self?.serverDatabaseManager.addPaper(paper: serverPaper)
                        self?.serverDatabaseManager.fetchPaper(paperId: serverPaper.paperId)
                        self?.currentPaperPublisher.send(serverPaper)
                        self?.paperFrom = .fromServer
                        self?.output.send(.paperLinkMade(url: url))
                        print("aaa makePaperShareLink made")
                        linkSubscription?.cancel()
                    }
                paperSubscription?.cancel()
            }
    }
    
    private func makePaperGiftLink() {
        guard let currentPaper = currentPaperPublisher.value else { return }
        
        if paperFrom == .fromServer {
            serverToGift()
        } else {
            var paperSubscription: AnyCancellable?
            paperSubscription = getServerSidePaper(paper: currentPaper)
                .sink { [weak self] serverPaper in
                    self?.localDatabaseManager.resetPaper()
                    self?.serverDatabaseManager.addPaper(paper: serverPaper)
                    self?.currentPaperPublisher.send(serverPaper)
                    self?.paperFrom = .fromServer
                    self?.serverToGift()
                    paperSubscription?.cancel()
                }
        }
    }
    
    private func serverToGift() {
        guard
            paperFrom == .fromServer,
            let currentPaper = currentPaperPublisher.value else {return }
        var convertSubscription: AnyCancellable?
        convertSubscription = serverDatabaseManager.convertPaperToGift(paper: currentPaper)
            .sink { completion in
                switch completion {
                case .failure(let error): print(error.localizedDescription)
                case .finished: break
                }
            } receiveValue: { [weak self] giftPaper in
                var shareSubscription: AnyCancellable?
                shareSubscription = getPaperShareLink(with: giftPaper, route: .gift)
                    .sink { completion in
                        switch completion {
                        case .failure(let error): print(error.localizedDescription)
                        case .finished: break
                        }
                    } receiveValue: { url in
                        self?.output.send(.giftLinkMade(url: url))
                        shareSubscription?.cancel()
                    }
                convertSubscription?.cancel()
            }
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
    
    // card -> image data -> server saved url + card return
    private func setServerSideCard(card: CardModel) -> AnyPublisher<CardModel, Error> {
        var card = card
        return Future { [weak self] promise in
            if
                let image = self?.images[card.cardId],
                let data = image.jpegData(compressionQuality: 0.8) {
                var uploadSubscription: AnyCancellable?
                uploadSubscription = FirebaseStorageManager.uploadData(dataId: card.cardId, data: data, contentType: .jpeg, pathRoot: .card)
                    .sink { completion in
                        switch completion {
                        case .failure(let error):
                            promise(.failure(error))
                            uploadSubscription?.cancel()
                        case .finished: break
                        }
                    } receiveValue: { url in
                        card.contentURLString = url?.absoluteString ?? ""
                        promise(.success(card))
                    }
            } else {
                promise(.failure(URLError(.badURL)))
            }
        }
        .eraseToAnyPublisher()
    }
}
