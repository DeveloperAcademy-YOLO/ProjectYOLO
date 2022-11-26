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
            .receive(on: DispatchQueue.global(qos: .background))
            .map(filterPaperPreviewModels)
            .sink(receiveValue: { [weak self] paperPreviews in
                guard let self = self else {return}
                self.papersFromLocal = paperPreviews
                self.localPaperIds.removeAll()
                for paper in self.papersFromLocal {
                    self.localPaperIds.insert(paper.paperId)
                }
                self.sortPapers()
                self.downloadLocalThumbnails(outputValue: .papersAreUpdatedInDatabase)
            })
            .store(in: &cancellables)
        
        serverDatabaseManager.papersSubject
            .receive(on: DispatchQueue.global(qos: .background))
            .map(filterPaperPreviewModels)
            .sink(receiveValue: { [weak self] paperPreviews in
                guard let self = self else {return}
                self.papersFromServer = paperPreviews
                self.serverPaperIds.removeAll()
                for paper in self.papersFromServer {
                    self.serverPaperIds.insert(paper.paperId)
                }
                self.sortPapers()
                self.downloadServerThumbnails(outputValue: .papersAreUpdatedInDatabase)
            })
            .store(in: &cancellables)
    }
    
    // url을 통해 로컬에 저장되어있는 썸네일 다운받아오기
    private func downloadLocalThumbnails(outputValue: Output) {
        var downloadCount = 0
        for paper in papersFromLocal {
            if thumbnails[paper.paperId] != nil { continue }
            if let thumbnailURLString = paper.thumbnailURLString {
                if let cachedImage = NSCacheManager.shared.getImage(name: thumbnailURLString) {
                    // 진입 경로1 - 캐시 데이터를 통한 다운로드
                    thumbnails[paper.paperId] = cachedImage
                    downloadCount += 1
                    // 모든 썸네일을 다운 받는게 완료되면 view controller에게 알려주기
                    if downloadCount == papersFromLocal.count {
                        self.output.send(outputValue)
                    }
                } else {
                    LocalStorageManager.downloadData(urlString: thumbnailURLString)
                        .receive(on: DispatchQueue.global(qos: .background))
                        .sink(receiveCompletion: { completion in
                            switch completion {
                            case .failure(let error):
                                print(error)
                                downloadCount += 1
                                // 모든 썸네일을 다운 받는게 완료되면 view controller에게 알려주기
                                if downloadCount == self.papersFromLocal.count {
                                    self.output.send(outputValue)
                                }
                            case .finished: break
                            }
                        }, receiveValue: { [weak self] data in
                            guard let self = self else {return}
                            if let data = data,
                               let image = UIImage(data: data) {
                                // 진입 경로2 - 파이어베이스에 접근해서 다운로드
                                self.thumbnails[paper.paperId] = image
                                NSCacheManager.shared.setImage(image: image, name: thumbnailURLString)
                            }
                            downloadCount += 1
                            // 모든 썸네일을 다운 받는게 완료되면 view controller에게 알려주기
                            if downloadCount == self.papersFromLocal.count {
                                self.output.send(outputValue)
                            }
                        })
                        .store(in: &cancellables)
                }
            } else {
                // 진입 경로3 - 썸네일 주소가 nil 일때 아무것도 안함
                downloadCount += 1
                // 모든 썸네일을 다운 받는게 완료되면 view controller에게 알려주기
                if downloadCount == papersFromLocal.count {
                    self.output.send(outputValue)
                }
            }
        }
        
        if papersFromLocal.isEmpty {
            output.send(outputValue)
        }
    }
    
    // url을 통해 서버에 저장되어있는 썸네일 다운받아오기
    private func downloadServerThumbnails(outputValue: Output) {
        var downloadCount = 0
        for paper in papersFromServer {
            if thumbnails[paper.paperId] != nil { continue }
            if let thumbnailURLString = paper.thumbnailURLString {
                if let cachedImage = NSCacheManager.shared.getImage(name: thumbnailURLString) {
                    // 진입 경로1 - 캐시 데이터를 통한 다운로드
                    thumbnails[paper.paperId] = cachedImage
                    downloadCount += 1
                    // 모든 썸네일을 다운 받는게 완료되면 view controller에게 알려주기
                    if downloadCount == papersFromServer.count {
                        self.output.send(outputValue)
                    }
                } else {
                    FirebaseStorageManager.downloadData(urlString: thumbnailURLString)
                        .receive(on: DispatchQueue.global(qos: .background))
                        .sink(receiveCompletion: { completion in
                            switch completion {
                            // 진입 경로2 - 캐시 데이터를 통한 다운로드
                            case .failure(let error):
                                print(error)
                                downloadCount += 1
                                // 모든 썸네일을 다운 받는게 완료되면 view controller에게 알려주기
                                if downloadCount == self.papersFromServer.count {
                                    self.output.send(outputValue)
                                }
                            case .finished: break
                            }
                        }, receiveValue: { [weak self] data in
                            guard let self = self else {return}
                            if let data = data,
                               let image = UIImage(data: data) {
                                // 진입 경로2 - 파이어베이스에 접근해서 다운로드
                                self.thumbnails[paper.paperId] = image
                                NSCacheManager.shared.setImage(image: image, name: thumbnailURLString)
                            }
                            downloadCount += 1
                            // 모든 썸네일을 다운 받는게 완료되면 view controller에게 알려주기
                            if downloadCount == self.papersFromServer.count {
                                self.output.send(outputValue)
                            }
                        })
                        .store(in: &cancellables)
                }
            } else {
                // 진입 경로3 - 썸네일 주소가 nil 일때 아무것도 안함
                downloadCount += 1
                // 모든 썸네일을 다운 받는게 완료되면 view controller에게 알려주기
                if downloadCount == papersFromServer.count {
                    self.output.send(outputValue)
                }
            }
        }
        
        if papersFromServer.isEmpty {
            output.send(outputValue)
        }
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
                    self.downloadLocalThumbnails(outputValue: .initPapers)
                    self.downloadServerThumbnails(outputValue: .initPapers)
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
