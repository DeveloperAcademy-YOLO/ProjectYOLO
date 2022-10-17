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
    }
    enum Output {
        case initPapers
        case papersAreUpdatedInDatabase
        case papersAreUpdatedByTimer
    }
    
    private let timerInterval: Double = 60
    private let databaseManager: DatabaseManager
    private let output: PassthroughSubject<Output, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    private var timer: AnyCancellable?
    private var papers = [PaperPreviewModel]()
    private var thumbnails = [UIImage?]()
    private var openedIndex = [Int]()
    private var closedIndex = [Int]()
    
    var currentTime: Date = Date()
        
    // 현재 시간과 끝나는 시간 비교해서, 진행중인 것인지 종료된것인지에 따라 구별된 페이퍼 리스트와 썸네일 리스트
    var openedPaperThumbnails: [UIImage?] {
        var opened = [UIImage?]()
        for index in openedIndex {
            opened.append(thumbnails[index])
        }
        return opened
    }
    var closedPaperThumbnails: [UIImage?] {
        var closed = [UIImage?]()
        for index in closedIndex {
            closed.append(thumbnails[index])
        }
        return closed
    }
    var openedPapers: [PaperPreviewModel] {
        var opened = [PaperPreviewModel]()
        for index in openedIndex {
            opened.append(papers[index])
        }
        return opened
    }
    var closedPapers: [PaperPreviewModel] {
        var closed = [PaperPreviewModel]()
        for index in closedIndex {
            closed.append(papers[index])
        }
        return closed
    }
    
    init(databaseManager: DatabaseManager = LocalDatabaseMockManager.shared) {
        self.databaseManager = databaseManager
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
                self.downloadThumbnails(outputValue: .initPapers)
            // 뷰가 없어졌다는 시그널이 오면 타이머 bind 끊어버림
            case .viewDidDisappear:
                self.timer?.cancel()
            }
        })
        .store(in: &cancellables)
        return output.eraseToAnyPublisher()
    }
    
    // 데이터베이스 메니저 연동
    private func bindDatabaseManager() {
        databaseManager.papersSubject
            .sink(receiveValue: { [weak self] paperPreviews in
                guard let self = self else {return}
                self.papers = paperPreviews
                self.downloadThumbnails(outputValue: .papersAreUpdatedInDatabase)
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
        openedIndex.removeAll()
        closedIndex.removeAll()
        
        for (index, paper) in papers.enumerated() {
            let timeInterval = Int(paper.endTime.timeIntervalSince(currentTime))
            if timeInterval > 0 {
                openedIndex.append(index)
            } else {
                closedIndex.append(index)
            }
        }
    }
    
    // url을 통해 썸네일 다운받아오기
    private func downloadThumbnails(outputValue: Output) {
        thumbnails = [UIImage?](repeating: nil, count: papers.count)

        for (idx, paper) in papers.enumerated() {
            if let thumbnailURLString = paper.thumbnailURLString {
                FirebaseStorageManager.downloadData(urlString: thumbnailURLString)
                    .sink(receiveCompletion: { [weak self] completion in
                        guard let self = self else {return}
                        switch completion {
                        case .failure(let error):
                            print("error in download paper thumbnail: \(error)")
                            self.thumbnails[idx] = paper.template.thumbnail
                        case .finished: break
                        }
                    }, receiveValue: { [weak self] data in
                        guard let self = self else {return}
                        if let data = data {
                            self.thumbnails[idx] = UIImage(data: data)
                        } else {
                            self.thumbnails[idx] = paper.template.thumbnail
                        }
                        
                        // 모든 썸네일을 다운 받는게 완료되면 view controller에게 알려주기 (진입 경로1)
                        if !self.thumbnails.contains(nil) {
                            self.classifyPapers()
                            self.output.send(outputValue)
                        }
                    })
                    .store(in: &cancellables)
            } else {
                thumbnails[idx] = paper.template.thumbnail
                
                // 모든 썸네일을 다운 받는게 완료되면 view controller에게 알려주기 (진입 경로2)
                if !thumbnails.contains(nil) {
                    classifyPapers()
                    output.send(outputValue)
                }
            }
        }
    }
}
