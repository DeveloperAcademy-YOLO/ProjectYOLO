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
    
    private let localDatabaseManager: DatabaseManager
    private let serverDatabaseManager: DatabaseManager
//    private var currentPaper: PaperModel
//
    private var cancellables = Set<AnyCancellable>()
//
    var currentPaper: PaperModel?
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
    
    init(localDatabaseManager: DatabaseManager = LocalDatabaseMockManager.shared, serverDatabaseManager: DatabaseManager = FirestoreManager.shared) {
        self.localDatabaseManager = localDatabaseManager
        self.serverDatabaseManager = serverDatabaseManager
        setCurrentPaper()
    }
    
    func setCurrentPaper() {
        self.localDatabaseManager.paperSubject
            .sink(receiveValue: { [weak self] paper in
                if let paper = paper {
                    print("Local Paper")
                    self?.currentPaper = paper
                    
                }
                else {
                    print("로컬 비었음")
                }
            })
            .store(in: &cancellables) // 이 줄 있으면 여러번 호출됨, 계속 저장만 해서 그런가 봄
        
        self.serverDatabaseManager.paperSubject
            .sink(receiveValue: { [weak self] paper in
                if let paper = paper {
                    print("Server Paper")
                    self?.currentPaper = paper
                } else {
                    print("서버 비었음")
                }
            })
            .store(in: &cancellables)
    }
    
    func changePaperTitle() {}
    
    func setRemainingTime() {}
    
    func addCard() {} // 이건 요셉 뷰에서 추가해야하는 내용
    
    func deleteCard() {}
    
    func showCardDetail() {}
    
    func stopPaper() {}
    
    func deletePaper() {}

}
