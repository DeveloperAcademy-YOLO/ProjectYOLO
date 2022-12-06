//
//  PaperStorageViewModel.swift
//  RollingPaper
//
//  Created by 김동락 on 2022/10/12.
//

import Combine
import UIKit

class PaperStorageViewModel {
    let timeFlowManager = TimeFlowManager()
    private let timerInput: PassthroughSubject<TimeFlowManager.Input, Never> = .init()
    private let output: PassthroughSubject<Output, Never> = .init()
    private let localDatabaseManager: DatabaseManager
    private let serverDatabaseManager: DatabaseManager
    private var isPaperClosed: Bool = false
    private var cancellables = Set<AnyCancellable>()
    private var papersFromLocal = [PaperPreviewModel]()
    private var papersFromServer = [PaperPreviewModel]()
    private var papers = [PaperPreviewModel]()
    
    var serverPaperIds = Set<String>()
    var localPaperIds = Set<String>()
    var openedPaperIds = Set<String>()
    var closedPaperIds = Set<String>()
    var openedPapers = [PaperPreviewModel]()
    var closedPapers = [PaperPreviewModel]()
    
    enum Input {
        case viewDidAppear
        case viewDidDisappear
        case paperSelected(paperId: String)
        case paperDeleted(paperId: String)
    }
    enum Output {
        case initPapers
        case papersAreUpdatedInDatabase
        case reloadData
    }
    
    init(localDatabaseManager: DatabaseManager = LocalDatabaseFileManager.shared, serverDatabaseManager: DatabaseManager = FirestoreManager.shared) {
        self.localDatabaseManager = localDatabaseManager
        self.serverDatabaseManager = serverDatabaseManager
        bindTimer()
        bindDatabaseManager()
    }
    
    // 타이머 연동시키기
    private func bindTimer() {
        let timerOutput = timeFlowManager.transform(input: timerInput.eraseToAnyPublisher())
        timerOutput
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] event in
                guard let self = self else {return}
                switch event {
                // 시간이 업데이트됨에 따라서 페이퍼 분류 및 UI 업데이트 하도록 시그널 보내기
                case .timeIsUpdated:
                    self.classifyPapers()
                    if self.isPaperClosed {
                        self.output.send(.reloadData)
                    }
                }
            })
            .store(in: &cancellables)
    }
    
    private func filterPaperPreviewModels(paperPreviews: [PaperPreviewModel]) -> [PaperPreviewModel] {
        let filtered = paperPreviews.filter({!$0.isGift})
        return filtered
    }
    
    // 데이터베이스 메니저 연동
    private func bindDatabaseManager() {
        localDatabaseManager.papersSubject
            .map(filterPaperPreviewModels)
            .combineLatest(serverDatabaseManager.papersSubject.map(filterPaperPreviewModels))
            .receive(on: DispatchQueue.global(qos: .background))
            .sink(receiveValue: { [weak self] localPapers, serverPapers in
                guard let self = self else {return}
                self.papersFromLocal = localPapers
                self.papersFromServer = serverPapers
                
                var localIds = Set<String>()
                var serverIds = Set<String>()
                
                for paper in self.papersFromLocal {
                    localIds.insert(paper.paperId)
                }
                for paper in self.papersFromServer {
                    serverIds.insert(paper.paperId)
                }
                
                self.localPaperIds = localIds
                self.serverPaperIds = serverIds
                self.classifyPapers()
                self.output.send(.reloadData)
            })
            .store(in: &cancellables)
    }
    
    // 서버와 로컬에 있는 페이퍼들 합쳐서, 열린 페이퍼와 닫힌 페이퍼로 구분하기
    private func classifyPapers() {
        // 로컬과 서버에 동일한 페이퍼가 있으면 로컬에서는 빼버림
        var papersLocalOnly = [PaperPreviewModel]()
        var isDuplicated: Bool
        for paperFromLocal in papersFromLocal {
            isDuplicated = false
            for paperFromServer in papersFromServer where paperFromLocal.paperId == paperFromServer.paperId {
                isDuplicated = true
                break
            }
            if !isDuplicated {
                papersLocalOnly.append(paperFromLocal)
            }
        }
        // 만든 시간 순서대로 정렬
        papers = papersLocalOnly + papersFromServer
        papers.sort(by: {return $1.date < $0.date})
        
        // 열린 페이퍼와 닫힌 페이퍼 구분
        var opened = [PaperPreviewModel]()
        var closed = [PaperPreviewModel]()
        var openedIds = Set<String>()
        var closedIds = Set<String>()
        
        for paper in papers {
            let timeInterval = Int(paper.endTime.timeIntervalSince(Date()))
            if timeInterval > 0 {
                openedIds.insert(paper.paperId)
                opened.append(paper)
            } else {
                closedIds.insert(paper.paperId)
                closed.append(paper)
            }
        }

        isPaperClosed = closedIds.count > closedPaperIds.count ? true : false
        
        openedPaperIds = openedIds
        closedPaperIds = closedIds
        openedPapers = opened
        closedPapers = closed
    }
    
    // view controller에서 시그널을 받으면 그에 따라 어떤 행동을 할지 정함
    func transform(input: AnyPublisher<Input, Never>) -> AnyPublisher<Output, Never> {
        input
            .receive(on: DispatchQueue.global(qos: .background))
            .sink(receiveValue: { [weak self] event in
                guard let self = self else {return}
                switch event {
                // 뷰가 나타났다는 시그널이 오면 타이머 bind 시키고 썸네일 새로 다운받기
                case .viewDidAppear:
                    self.timerInput.send(.viewDidAppear)
                    self.classifyPapers()
                    self.output.send(.initPapers)
                // 뷰가 사라졌다는 시그널이 오면 타이머한테 알려줘서 타이머 해제시키기
                case .viewDidDisappear:
                    self.timerInput.send(.viewDidDisappear)
                // 특정 페이퍼가 선택되면 로컬/서버 인지 구분하고 fetchpaper 실행
                case .paperSelected(let paperId):
                    if self.serverPaperIds.contains(paperId) {
                        self.serverDatabaseManager.fetchPaper(paperId: paperId)
                    } else {
                        self.localDatabaseManager.fetchPaper(paperId: paperId)
                    }
                case .paperDeleted(paperId: let paperId):
                    if self.serverPaperIds.contains(paperId) {
                        self.serverDatabaseManager.removePaper(paperId: paperId)
                    } else {
                        self.localDatabaseManager.removePaper(paperId: paperId)
                    }
                }
            })
            .store(in: &cancellables)
        return output.eraseToAnyPublisher()
    }
}
