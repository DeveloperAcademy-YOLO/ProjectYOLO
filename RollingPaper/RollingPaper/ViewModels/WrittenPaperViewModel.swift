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
    
    let localDatabaseManager: DatabaseManager
    let serverDatabaseManager: DatabaseManager
    private var cancellables = Set<AnyCancellable>()
    
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

    private var isPaperLinkMade: Bool?
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
        setCurrentPaper()
    }
    
    func setCurrentPaper() {
        self.localDatabaseManager.paperSubject
            .sink(receiveValue: { [weak self] paper in
                if let paper = paper {
                   // print("Local Paper: \(paper)")
                    print("Local Paper Cell count: \(paper.cards.count)")
                    self?.currentPaper = paper
                    self?.currentPaperPublisher.send(paper)
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
    
    func changePaperTitle(input: String) {
        currentPaper?.title = input
//        switch self.paperFrom {
//        case .fromLocal:
//            localDatabaseManager.updatePaper(paper: currentPaper)
//        case .fromServer:
//            serverDatabaseManager.updatePaper(paper: currentPaper)
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
