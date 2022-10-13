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
    
    private let databaseManager: DatabaseManager
    private let output: PassthroughSubject<Output, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    private var papers: [PaperPreviewModel]?
    var currentTime: Date = Date()
    
    // 현재 시간과 끝나는 시간 비교해서, 진행중인 페이퍼와 끝난 페이퍼 구분하기
    var openedPapers: [PaperPreviewModel] {
        guard let papers = papers else {return []}
        
        var opened = [PaperPreviewModel]()
        for paper in papers {
            let timeInterval = Int(paper.endTime.timeIntervalSince(currentTime))
            if timeInterval > 0 {
                opened.append(paper)
            }
        }
        return opened
    }
    var closedPapers: [PaperPreviewModel] {
        guard let papers = papers else {return []}
        
        var closed = [PaperPreviewModel]()
        for paper in papers {
            let timeInterval = Int(paper.endTime.timeIntervalSince(currentTime))
            if timeInterval <= 0 {
                closed.append(paper)
            }
        }
        return closed
    }
    
    init(databaseManager: DatabaseManager = LocalDatabaseMockManager.shared) {
        self.databaseManager = databaseManager
        bind()
    }
    
    func transform(input: AnyPublisher<Input, Never>) -> AnyPublisher<Output, Never> {
        input.sink(receiveValue: { [weak self] event in
            guard let self = self else {return}
            switch event {
            // 뷰가 나타났다는 시그널이 오면 초기화하라고 말하기
            case .viewDidAppear:
                self.output.send(.initPapers)
            // 뷰가 없어졌다는 시그널이 오면 bind 됐던거 다 끊어버림
            case .viewDidDisappear:
                for cancellable in self.cancellables {
                    cancellable.cancel()
                }
            }
        })
        .store(in: &cancellables)
        return output.eraseToAnyPublisher()
    }
    
    // 데이터베이스 메니저와 타이머 연동
    private func bind() {
        databaseManager.papersSubject
            .sink(receiveValue: { [weak self] paperPreviews in
                guard let self = self else {return}
                self.papers = paperPreviews
                self.output.send(.papersAreUpdatedInDatabase)
            })
            .store(in: &cancellables)
        
        Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink(receiveValue: { [weak self] date in
                guard let self = self else {return}
                self.currentTime = date
                self.output.send(.papersAreUpdatedByTimer)
            })
            .store(in: &cancellables)
    }
}
