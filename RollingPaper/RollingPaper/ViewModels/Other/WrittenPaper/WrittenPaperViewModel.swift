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
    private let authManager: AuthManager = FirebaseAuthManager.shared
    private let currentUserSubject: CurrentValueSubject<UserModel?, Never> = .init(nil)
    private let output: PassthroughSubject<Output, Never> = .init()
    var currentUser: UserModel?
    
    var currentPaper: PaperModel!
    let currentPaperPublisher: CurrentValueSubject<PaperModel?, Never> = .init(nil)
    var paperFrom: DataSource?
    private var paperID: String = ""
    
    var isTitleChanged: Bool = false
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
    }
    
    enum Output {
        case cardDeleted
        case paperStopped
        case paperDeleted
        case paperTitleChanged
        case paperLinkMade
        case giftLinkMade
    }
    
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
    
    private func setCurrentPaper() {
        self.localDatabaseManager.paperSubject
            .sink(receiveValue: { [weak self] paper in
                if let paper = paper {
                    self?.currentPaper = paper
                    self?.paperFrom = .fromLocal
                    self?.currentPaperPublisher.send(paper)
                }
                else {
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
                }
            })
            .store(in: &cancellables)
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
                    self.deletePaper(self.currentPaper.paperId)
                    self.output.send(.paperDeleted)
                case .paperShareTapped:
                    self.makePaperShareLink()
                case .giftTapped:
                    self.makePaperGiftLink()
                case .moveToStorageTapped:
                    self.cleanPaperPublisher()
                }
            }
            .store(in: &cancellables)
        return output.eraseToAnyPublisher()
    }
    
    private func cleanPaperPublisher() {
        currentPaper = nil
        currentPaperPublisher.send(currentPaper)
    }

    private func changePaperTitle(input: String, from paperFrom: DataSource) {
        currentPaper?.title = input
        isTitleChanged = true
        guard let paper = currentPaper else { return }
        switch paperFrom {
        case .fromLocal:
            localDatabaseManager.updatePaper(paper: paper)
            currentPaperPublisher.send(paper)
        case .fromServer:
            serverDatabaseManager.updatePaper(paper: paper)
            currentPaperPublisher.send(paper)
        }
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
        currentPaper.endTime = currentPaper.date
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
        currentPaper = nil
        currentPaperPublisher.send(currentPaper)
    }
    
    private func makePaperShareLink() {
        getPaperShareLink(with: currentPaper, route: .write)
            .receive(on: DispatchQueue.main)
            .sink { (completion) in
                switch completion {
                    // 링크가 만들어지면 isPaperLinkMade 값을 바꿔줌
                case .finished: break
                case .failure(let error): print(error)
                }
            } receiveValue: { url in
                self.isPaperLinkMade = true
                self.currentPaper.linkUrl = url
                self.localDatabaseManager.updatePaper(paper: self.currentPaper)
                self.serverDatabaseManager.addPaper(paper: self.currentPaper)
                //링크 만드는 순간 로컬데이터 지워주는 타이밍 얘기해봐야해서 일단 로컬, 서버 둘 다 업뎃하도록 함
                self.currentPaperPublisher.send(self.currentPaper)
                self.output.send(.paperLinkMade)
            }
            .store(in: &cancellables)
    }
    
    private func makePaperGiftLink() {
        getPaperShareLink(with: currentPaper, route: .gift)
            .receive(on: DispatchQueue.main)
            .sink { (completion) in
                switch completion {
                    // 링크가 만들어지면 isPaperLinkMade 값을 바꿔줌
                case .finished: break
                case .failure(let error): print(error)
                }
            } receiveValue: { url in
                self.isPaperLinkMade = true
                self.currentPaper.linkUrl = url
                self.currentPaper.isGift = true
                self.localDatabaseManager.updatePaper(paper: self.currentPaper)
                self.serverDatabaseManager.addPaper(paper: self.currentPaper)
                //링크 만드는 순간 로컬데이터 지워주는 타이밍 얘기해봐야해서 일단 로컬, 서버 둘 다 업뎃하도록 함
                self.currentPaperPublisher.send(self.currentPaper)
                self.output.send(.giftLinkMade)
            }
            .store(in: &cancellables)
    }
}
