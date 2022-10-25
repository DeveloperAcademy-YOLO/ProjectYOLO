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
    private var timeRemaing: Date?
    
    var isPaperLinkMade: Bool = false
    private var paperLinkForShare: String?
    
    private var currentUserType: String?
    
    private var isPaperStopped: Bool?
    private var isPaperDeleted: Bool?
    
    private var cards: [CardModel] = []
    

    init(localDatabaseManager: DatabaseManager = LocalDatabaseFileManager.shared, serverDatabaseManager: DatabaseManager = FirestoreManager.shared) {
        self.localDatabaseManager = localDatabaseManager
        self.serverDatabaseManager = serverDatabaseManager
        print("WrittenViewModel Init")
        print(localDatabaseManager.paperSubject.value)

    init() {
        setCurrentUser()

        setCurrentPaper()
    }
    
    func setCurrentUser() {
        authManager
            .userProfileSubject
            .receive(on: DispatchQueue.global(qos: .background))
            .sink{ [weak self] userProfile in
                guard let self = self else { return }
                self.currentUser = userProfile
            }
            .store(in: &cancellables)
    }
    
    func setCurrentPaper() {
        self.localDatabaseManager.paperSubject
            .sink(receiveValue: { [weak self] paper in
                if let paper = paper {
                   // print("Local Paper: \(paper)")
                    print("Local Paper Cell count: \(paper.cards.count)")
                    self?.currentPaper = paper
                    self?.currentPaper?.creator = self?.currentUser
                    self?.currentPaperPublisher.send(self?.currentPaper)
                    self?.paperFrom = DataSource.fromLocal
                }
                else {
                    print("로컬 비었음")
                }
            })
            .store(in: &cancellables)
        
        self.serverDatabaseManager.paperSubject
            .sink(receiveValue: { [weak self] paper in
                if let paper = paper {
                    print("Server Paper")
                    self?.currentPaper = paper
                    self?.paperFrom = DataSource.fromServer
                } else {
                    print("서버 비었음")
                }
            })
            .store(in: &cancellables)
    }
    
    func changePaperTitle(input: String, from paperFrom: DataSource) {
        currentPaper?.title = input
//        switch paperFrom {
//        case .fromLocal:
//            localDatabaseManager.updatePaper(paper: self.currentPaper ?? <#default value#>)
//        case .fromServer:
//            serverDatabaseManager.updatePaper(paper: self?.currentPaper)
        //TODO: 페이퍼 업뎃 때 페이퍼 아이디 받기 논의
//        }
    }
    
    func getRemainingTime(_ paperID: String) {}
    
    func callEveryCards() {
        
    }
    
    func addCard() {} // 이건 요셉 뷰에서 추가해야하는 내용
    
    func deleteCard() {}
    
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
        case .fromServer:
            serverDatabaseManager.removePaper(paperId: paperID)
        }
    }
    
    func makePaperLinkForShare() {}
    
}
