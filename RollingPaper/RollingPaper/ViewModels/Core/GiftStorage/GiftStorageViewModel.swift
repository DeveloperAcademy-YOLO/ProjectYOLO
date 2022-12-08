//
//  GiftStorageViewModel.swift
//  RollingPaper
//
//  Created by 김동락 on 2022/11/15.
//

import Combine
import UIKit

class GiftStorageViewModel {
    private let output: PassthroughSubject<Output, Never> = .init()
    private let localDatabaseManager: DatabaseManager
    private let serverDatabaseManager: DatabaseManager
    private var cancellables = Set<AnyCancellable>()
    private var papersFromLocal = [PaperPreviewModel]()
    private var papersFromServer = [PaperPreviewModel]()
    
    var papersByYear = [String: [PaperPreviewModel]]()
    var years = [String]()
    var serverPaperIds = Set<String>()
    var localPaperIds = Set<String>()
    var thumbnails = [String: UIImage?]()
    
    enum Input {
        case viewDidAppear
        case paperSelected(paperId: String)
    }
    enum Output {
        case initPapers
        case papersAreUpdatedInDatabase
    }
    
    init(localDatabaseManager: DatabaseManager = LocalDatabaseFileManager.shared, serverDatabaseManager: DatabaseManager = FirestoreManager.shared) {
        self.localDatabaseManager = localDatabaseManager
        self.serverDatabaseManager = serverDatabaseManager
        bindDatabaseManager()
    }
    
    private func filterPaperPreviewModels(paperPreviews: [PaperPreviewModel]) -> [PaperPreviewModel] {
        let filtered = paperPreviews.filter({$0.isGift})
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
                
                var localPaperIdsTemp = Set<String>()
                var serverPaperIdsTemp = Set<String>()
                
                for paper in self.papersFromLocal {
                    localPaperIdsTemp.insert(paper.paperId)
                }
                for paper in self.papersFromServer {
                    serverPaperIdsTemp.insert(paper.paperId)
                }
                
                self.localPaperIds = localPaperIdsTemp
                self.serverPaperIds = serverPaperIdsTemp
                self.sortPapers()
            })
            .store(in: &cancellables)
    }
    
    // 페이퍼 날짜별로 정렬하기
    private func sortPapers() {
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
        
        var papers = papersLocalOnly + papersFromServer
        papers.sort(by: {return $1.date < $0.date})
        
        var papersByYearTemp = [String: [PaperPreviewModel]]()
        var yearsTemp = [String]()
        
        
        for paper in papers {
            let year = getYear(date: paper.date)
            if papersByYearTemp[year] == nil {
                papersByYearTemp[year] = [paper]
                yearsTemp.append(year)
            } else {
                papersByYearTemp[year]?.append(paper)
            }
        }
        yearsTemp = yearsTemp.sorted().reversed()
        
        papersByYear = papersByYearTemp
        years = yearsTemp
    }
    
    // Date 타입에서 연도 얻기
    private func getYear(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy"
        return dateFormatter.string(from: date)
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
                    self.sortPapers()
                    self.output.send(.initPapers)
                // 특정 페이퍼가 선택되면 로컬/서버 인지 구분하고 fetchpaper 실행
                case .paperSelected(let paperId):
                    if self.serverPaperIds.contains(paperId) {
                        self.serverDatabaseManager.fetchPaper(paperId: paperId)
                    } else {
                        self.localDatabaseManager.fetchPaper(paperId: paperId)
                    }
                }
            })
            .store(in: &cancellables)
        return output.eraseToAnyPublisher()
    }
}
