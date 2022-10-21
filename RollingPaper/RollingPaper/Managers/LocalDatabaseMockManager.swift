//
//  LocalDatabaseMockManager.swift
//  RollingPaper
//
//  Created by Junyeong Park on 2022/10/08.
//

import Foundation
import Combine
import UIKit

final class LocalDatabaseMockManager: DatabaseManager {
    
    static let shared: DatabaseManager = LocalDatabaseMockManager()
    private var papersMockData = [PaperModel]()
    // 데이터베이스를 사용하지 않기 때문에 해당 로컬 변수에 페이퍼 변화 사항을 모두 기록
    private var cancellables = Set<AnyCancellable>()
    var papersSubject: CurrentValueSubject<[PaperPreviewModel], Never> = .init([])
    var paperSubject: CurrentValueSubject<PaperModel?, Never> = .init(nil)
    
    private init() {
        loadPapers()
    }
    
    /// 가데이터를 이니셜라이즈 단에서 로드
    private func downloadMockdata() -> [PaperPreviewModel] {
        let today = Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let soon = Calendar.current.date(byAdding: .second, value: 3, to: Date())!
        var paper1 = PaperModel(cards: [], date: today, endTime: tomorrow, title: "MockPaper1", templateString: TemplateEnum.halloween.rawValue)
        var paper2 = PaperModel(cards: [], date: today, endTime: soon, title: "MockPaper2", templateString: TemplateEnum.grid.rawValue)
        var card1 = CardModel(date: Date(), contentURLString: "")
        var card2 = CardModel(date: Date(), contentURLString: "")
        var card3 = CardModel(date: Date(), contentURLString: "")
        let card4 = CardModel(date: Date(), contentURLString: "")
        if
            let mockImage = UIImage(systemName: "person"),
            let mockData = mockImage.jpegData(compressionQuality: 0.8) {
            let uploadPublisher = LocalStorageManager.uploadData(dataId: card1.cardId, data: mockData, contentType: .jpeg, pathRoot: .card)
                .sink(receiveCompletion: { completion in
                    switch completion {
                    case .failure(let error): print(error.localizedDescription)
                    case .finished: print("Upload Image Successfully Done")
                    }
                }, receiveValue: { [weak self] photoURL in
                    if let photoURL = photoURL {
                        let photoURLString = photoURL.absoluteString
                        card1.contentURLString = photoURLString
                        card2.contentURLString = photoURLString
                        card3.contentURLString = photoURLString
                        paper1.cards.append(contentsOf: [card1, card2])
                        paper2.cards.append(contentsOf: [card3, card4])
                        self?.papersMockData.append(contentsOf: [paper1, paper2])
                    }
                })
            uploadPublisher.cancel()
        }
        var paperPreviews = [PaperPreviewModel]()
        for paper in papersMockData {
            let paperPreview = PaperPreviewModel(paperId: paper.paperId, date: paper.date, endTime: paper.endTime, title: paper.title, templateString: paper.templateString)
            paperPreviews.append(paperPreview)
        }
        return paperPreviews
    }
    
    /// 페이퍼 프리뷰 가데이터를 해당 데이터 퍼블리셔 내에 등록
    private func loadPapers() {
//        papersSubject.send(paperPreviews)
    }
    
    /// 로컬 페이퍼 데이터 추가 및 프리뷰 데이터 추가
    func addPaper(paper: PaperModel) {
        let paperPreview = PaperPreviewModel(paperId: paper.paperId, date: paper.date, endTime: paper.endTime, title: paper.title, templateString: paper.templateString)
        papersSubject.send(papersSubject.value + [paperPreview])
        papersMockData.append(paper)
    }
    
    /// 현재 페이퍼 유효할 때 해당 페이퍼에 카드 데이터 추가
    func addCard(paperId: String, card: CardModel) {
        // 현재 paperSubject에 카드 추가하기
        guard var currentPaper = paperSubject.value else { return }
        currentPaper.cards.append(card)
        paperSubject.send(currentPaper)
    }
    
    /// 현재 페이퍼 배열 데이터 내 페이퍼 삭제 및 페이퍼 프리뷰 배열 중 페이퍼 삭제
    func removePaper(paperId: String) {
        var currentPapers = papersSubject.value
        if let index = currentPapers.firstIndex(where: { $0.paperId == paperId }) {
            currentPapers.remove(at: index)
            papersMockData.removeAll(where: { $0.paperId == paperId })
            papersSubject.send(currentPapers)
        }
    }
    
    /// 현재 페이퍼 유효할 때 해당 페이퍼 내 카드 데이터 삭제
    func removeCard(paperId: String, card: CardModel) {
        guard var currentPaper = paperSubject.value else { return }
        if let index = currentPaper.cards.firstIndex(where: { $0.cardId == card.cardId }) {
            currentPaper.cards.remove(at: index)
            paperSubject.send(currentPaper)
        }
    }
    
    /// 현재 페이퍼 데이터가 페이퍼 배열 내 존재할 때 페이퍼 데이터 업데이트 및 프리뷰 이미지 다를 때 
    func updatePaper(paper: PaperModel) {
        if let index = papersMockData.firstIndex(where: { $0.paperId == paper.paperId }) {
            papersMockData[index] = paper
            var currentPapers = papersSubject.value
            if let previewIndex = currentPapers.firstIndex(where: { $0.paperId == paper.paperId }) {
                currentPapers[previewIndex].thumbnailURLString = paper.thumbnailURLString
            }
        }
    }
    
    /// 현재 페이퍼 유효할 때 페이퍼 내 카드 업데이트
    func updateCard(paperId: String, card: CardModel) {
        guard var currentPaper = paperSubject.value else { return }
        if let index = currentPaper.cards.firstIndex(where: { $0.cardId == card.cardId }) {
            currentPaper.cards.remove(at: index)
            paperSubject.send(currentPaper)
        }
    }
    
    /// 페이퍼 아이디를 통해 페이퍼 데이터 로드
    func fetchPaper(paperId: String) {
        if let index = papersMockData.firstIndex(where: {$0.paperId == paperId }) {
            let currentPaper = papersMockData[index]
            paperSubject.send(currentPaper)
        }
    }
    
    /// 뷰 모델에서 사용하는 현재 페이퍼에서 뒤로 가기 / 사용하지 않을 때 널 값을 통해 시그널
    func resetPaper() {
        paperSubject.send(nil)
    }
    
}
