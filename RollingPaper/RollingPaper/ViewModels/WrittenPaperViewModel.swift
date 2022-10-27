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
                    print("로컬 비었음")
                }
            })
            .store(in: &cancellables)
        
        self.serverDatabaseManager.paperSubject
            .sink(receiveValue: { [weak self] paper in
                if let paper = paper {
                    self?.currentPaper = paper
                    self?.paperFrom = .fromServer
                } else {
                    print("서버 비었음")
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
        localDatabaseManager.updatePaper(paper: paper)
        serverDatabaseManager.updatePaper(paper: paper)
        //링크 만드는 순간 로컬데이터 지워주는 타이밍 얘기해봐야해서 일단 로컬, 서버 둘 다 업뎃하도록 함
        currentPaperPublisher.send(paper)
    }
}
