//
//  GiftPaperViewModel.swift
//  RollingPaper
//
//  Created by Yosep on 2022/11/25.
//

import Foundation
import UIKit
import Combine

class GiftPaperViewModel {
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
    private var cards: [CardModel] = []
    
    enum DataSource {
        case fromLocal
        case fromServer
    }
    
    enum Input {
          case moveToStorageTapped
    }
    
    enum Output {
        case cardDeleted
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
                case .moveToStorageTapped:
                    self.cleanPaperPublisher()
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
        currentPaper = nil
        currentPaperPublisher.send(currentPaper)
        localDatabaseManager.resetPaper()
        serverDatabaseManager.resetPaper()
    }
    
    func deleteCard(_ card: CardModel, from paperFrom: DataSource) {
        switch paperFrom {
        case .fromLocal:
            localDatabaseManager.removeCard(paperId: paperID, card: card)
        case .fromServer:
            serverDatabaseManager.removeCard(paperId: paperID, card: card)
        }
    }
}
