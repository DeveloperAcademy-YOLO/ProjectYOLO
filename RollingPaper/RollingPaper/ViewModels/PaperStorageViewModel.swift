//
//  PaperStorageViewModel.swift
//  RollingPaper
//
//  Created by 김동락 on 2022/10/12.
//

import UIKit
import Combine

class PaperStorageViewModel {
    enum Input {
        case viewDidAppear
        case viewDidDisappear
        case paperSelected(paperId: String)
    }
    enum Output {
        case initPapers
        case papersAreUpdatedInDatabase
        case papersAreUpdatedByTimer
    }
    enum Location {
        case local
        case server
    }
    var currentTime: Date = Date()
    var serverPaperIds = Set<String>()
    var localPaperIds = Set<String>()
    var openedPaperIds = Set<String>()
    var closedPaperIds = Set<String>()
    var thumbnails = [String: UIImage?]()
    
    private let timerInterval: Double = 60
    private let localDatabaseManager: DatabaseManager
    private let serverDatabaseManager: DatabaseManager
    private let output: PassthroughSubject<Output, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    private var timer: AnyCancellable?
    private var papersFromLocal = [PaperPreviewModel]()
    private var papersFromServer = [PaperPreviewModel]()
    private var papers: [PaperPreviewModel] {
        // local과 server에 동일한 페이퍼가 있으면 로컬에서는 빼버림
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
        var totalPapers = papersLocalOnly + papersFromServer
        totalPapers.sort(by: {return $0.date < $1.date})
        
        return totalPapers
    }
    // 현재 시간과 끝나는 시간 비교해서, 진행중인 것인지 종료된것인지에 따라 구별된 페이퍼 리스트
    var openedPapers: [PaperPreviewModel] {
        var opened = [PaperPreviewModel]()
        for paper in papers {
            if openedPaperIds.contains(paper.paperId) {
                opened.append(paper)
            }
        }
        return opened
    }
    var closedPapers: [PaperPreviewModel] {
        var closed = [PaperPreviewModel]()
        for paper in papers {
            if closedPaperIds.contains(paper.paperId) {
                closed.append(paper)
            }
        }
        return closed
    }
    
    init(localDatabaseManager: DatabaseManager = LocalDatabaseMockManager.shared, serverDatabaseManager: DatabaseManager = FirestoreManager.shared) {
        self.localDatabaseManager = localDatabaseManager
        self.serverDatabaseManager = serverDatabaseManager
        bindDatabaseManager()
    }
    
    // view controller에서 시그널을 받으면 그에 따라 어떤 행동을 할지 정함
    func transform(input: AnyPublisher<Input, Never>) -> AnyPublisher<Output, Never> {
        input.sink(receiveValue: { [weak self] event in
            guard let self = self else {return}
            switch event {
            // 뷰가 나타났다는 시그널이 오면 타이머 bind 시키고 썸네일 새로 다운받기
            case .viewDidAppear:
                self.bindTimer()
                self.updateCurrentTime()
                self.downloadLocalThumbnails(outputValue: .initPapers)
                self.downloadServerThumbnails(outputValue: .initPapers)
            // 뷰가 없어졌다는 시그널이 오면 타이머 bind 끊어버림
            case .viewDidDisappear:
                self.timer?.cancel()
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
    
    // 데이터베이스 메니저 연동
    private func bindDatabaseManager() {
        localDatabaseManager.papersSubject
            .sink(receiveValue: { [weak self] paperPreviews in
                guard let self = self else {return}
                self.papersFromLocal = paperPreviews
                self.localPaperIds.removeAll()
                for paper in self.papersFromLocal {
                    self.localPaperIds.insert(paper.paperId)
                }
                self.downloadLocalThumbnails(outputValue: .papersAreUpdatedInDatabase)
            })
            .store(in: &cancellables)
        
        serverDatabaseManager.papersSubject
            .sink(receiveValue: { [weak self] paperPreviews in
                guard let self = self else {return}
                self.papersFromServer = paperPreviews
                self.serverPaperIds.removeAll()
                for paper in self.papersFromServer {
                    self.serverPaperIds.insert(paper.paperId)
                }
                self.downloadServerThumbnails(outputValue: .papersAreUpdatedInDatabase)
            })
            .store(in: &cancellables)
    }
    
    // 타이머 연동
    private func bindTimer() {
        timer = Timer.publish(every: timerInterval, on: .main, in: .common)
            .autoconnect()
            .sink(receiveValue: { [weak self] date in
                guard let self = self else {return}
                self.updateCurrentTime(date: date)
                self.classifyPapers()
                self.output.send(.papersAreUpdatedByTimer)
            })
    }
    
    // 현재 시간 업데이트하기
    private func updateCurrentTime(date: Date = Date()) {
        self.currentTime = date
    }
    
    // 페이퍼가 진행중인지, 종료된건지 분류하기
    private func classifyPapers() {
        openedPaperIds.removeAll()
        closedPaperIds.removeAll()

        for paper in papers {
            let timeInterval = Int(paper.endTime.timeIntervalSince(currentTime))
            if timeInterval > 0 {
                openedPaperIds.insert(paper.paperId)
            } else {
                closedPaperIds.insert(paper.paperId)
            }
        }
    }
    
    
    // url을 통해 로컬에 저장되어있는 썸네일 다운받아오기
    private func downloadLocalThumbnails(outputValue: Output) {
        var downloadCount = 0
        for paper in papersFromLocal {
            if let thumbnailURLString = paper.thumbnailURLString {
                if let cachedImage = NSCacheManager.shared.getImage(name: thumbnailURLString) {
                    // 진입 경로1 - 캐시 데이터를 통한 다운로드
                    thumbnails[paper.paperId] = cachedImage
                    downloadCount += 1
                    // 모든 썸네일을 다운 받는게 완료되면 view controller에게 알려주기
                    if downloadCount == papersFromLocal.count {
                        self.classifyPapers()
                        self.output.send(outputValue)
                    }
                } else {
                    LocalStorageManager.downloadData(urlString: thumbnailURLString)
                        .sink(receiveCompletion: { completion in
                            switch completion {
                            case .failure(let error):
                                print("error in download local paper thumbnail: \(error)")
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
                                self.classifyPapers()
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
                    self.classifyPapers()
                    self.output.send(outputValue)
                }
            }
        }
    }
    
    
    
    // url을 통해 서버에 저장되어있는 썸네일 다운받아오기
    private func downloadServerThumbnails(outputValue: Output) {
        var downloadCount = 0
        for paper in papersFromServer {
            if let thumbnailURLString = paper.thumbnailURLString {
                if let cachedImage = NSCacheManager.shared.getImage(name: thumbnailURLString) {
                    // 진입 경로1 - 캐시 데이터를 통한 다운로드
                    thumbnails[paper.paperId] = cachedImage
                    downloadCount += 1
                    // 모든 썸네일을 다운 받는게 완료되면 view controller에게 알려주기
                    if downloadCount == papersFromServer.count {
                        self.classifyPapers()
                        self.output.send(outputValue)
                    }
                } else {
                    FirebaseStorageManager.downloadData(urlString: thumbnailURLString)
                        .sink(receiveCompletion: { completion in
                            switch completion {
                            case .failure(let error):
                                print("error in download server paper thumbnail: \(error)")
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
                                self.classifyPapers()
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
                    self.classifyPapers()
                    self.output.send(outputValue)
                }
            }
        }
    }
}
