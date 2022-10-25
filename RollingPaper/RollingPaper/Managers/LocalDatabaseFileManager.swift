//
//  PaperModelFileManager.swift
//  RollingPaper
//
//  Created by Junyeong Park on 2022/10/05.
//

import Foundation
import Combine
import UIKit

final class LocalDatabaseFileManager: DatabaseManager {
    
    static let shared: DatabaseManager = LocalDatabaseFileManager()
    
    var papersSubject: CurrentValueSubject<[PaperPreviewModel], Never> = .init([])
    var paperSubject: CurrentValueSubject<PaperModel?, Never> = .init(nil)
    private let folderName = "/downloaded_papers"
    private let previewFolderName = "/downloaded_previews"
    private init() {
        createFolderIfNeeded()
        loadPaperPreviews()
    }
    
    private func getDocumentDirectoryPath() -> URL? {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    }
    
    private func getPaperDirectoryPath() -> URL? {
        guard let documentDir = getDocumentDirectoryPath() else { return nil }
        return documentDir.appendingPathComponent(folderName).absoluteURL
    }
    
    private func getPreviewDirectoryPath() -> URL? {
        guard let documentDir = getDocumentDirectoryPath() else { return nil }
        return documentDir.appendingPathComponent(previewFolderName).absoluteURL
    }
    
    private func getFilePath(paper: PaperModel) -> URL? {
        guard let paperDir = getPaperDirectoryPath() else { return nil}
        return paperDir.appendingPathComponent(paper.paperId + ".json")
    }
    
    private func getFilePath(paperId: String) -> URL? {
        guard let paperDir = getPaperDirectoryPath() else { return nil }
        return paperDir.appendingPathComponent(paperId + ".json")
    }
    
    private func getPreviewFilePath(paperId: String) -> URL? {
        guard let previewDir = getPreviewDirectoryPath() else { return nil }
        return previewDir.appendingPathComponent(paperId + ".json")
    }
    
    // 페이퍼 프리뷰, 페이퍼 모델 별 디렉토리 및 파일 접근 URL 리턴 함수
    
    /// 데이터 존재 디렉토리 생성
    private func createFolderIfNeeded() {
        guard
            let paperDirectory = getPaperDirectoryPath(),
            let previewDirectory = getPreviewDirectoryPath() else { return }
        if !FileManager.default.fileExists(atPath: paperDirectory.relativePath) {
            do {
                try FileManager.default.createDirectory(atPath: paperDirectory.relativePath, withIntermediateDirectories: true, attributes: nil)
                print("Created Folder")
            } catch {
                print("Error Creating Folder")
                print(error.localizedDescription)
            }
        }
        if !FileManager.default.fileExists(atPath: previewDirectory.relativePath) {
            do {
                try FileManager.default.createDirectory(atPath: previewDirectory.relativePath, withIntermediateDirectories: true, attributes: nil)
                print("Created Preview Folder")
            } catch {
                print("Error Creating Preview Folder")
                print(error.localizedDescription)
            }
        }
    }

    /// 이니셜라이즈 단에서 저장된 페이퍼 프리뷰 데이터 모두 로드
    private func loadPaperPreviews() {
        guard let previewDir = getPreviewDirectoryPath() else { return }
        do {
            let previewContents = try FileManager.default.contentsOfDirectory(at: previewDir, includingPropertiesForKeys: nil, options: [])
            let previews = previewContents
                .compactMap({ try? Data(contentsOf: $0 )})
                .compactMap({ try? JSONDecoder().decode(PaperPreviewModel.self, from: $0)})
            papersSubject.send(previews)
            print("Paper Preview First Loaded Successfully")
        } catch {
            print(error.localizedDescription)
        }
    }
    
    
    /// 페이퍼 데이터 추가, 페이퍼 프리뷰 데이터 추가, 페이퍼 프리뷰를 현재 로컬 데이터 퍼블리셔에 데이터 추가
    func addPaper(paper: PaperModel) {
        guard
            let fileDir = getFilePath(paper: paper),
            let previewFileDir = getPreviewFilePath(paperId: paper.paperId) else { return }
        let paperPreview = PaperPreviewModel(paperId: paper.paperId, date: paper.date, endTime: paper.endTime, title: paper.title, templateString: paper.templateString, thumbnailURLString: paper.thumbnailURLString)
        do {
            let paperData = try JSONEncoder().encode(paper)
            let paperPreviewData = try JSONEncoder().encode(paperPreview)
            try paperData.write(to: fileDir, options: .atomic)
            try paperPreviewData.write(to: previewFileDir, options: .atomic)
            papersSubject.send(papersSubject.value + [paperPreview])
        } catch {
            print(error.localizedDescription)
        }
    }
    
    /// 현재 페이퍼 유효할 때 해당 페이퍼에 카드 작성
    func addCard(paperId: String, card: CardModel) {
        guard var currentPaper = paperSubject.value else { return }
        currentPaper.cards.append(card)
        paperSubject.send(currentPaper)
    }
    
    /// 페이퍼 데이터 삭제, 페이퍼 프리뷰 데이터 삭제, 페이퍼 프리뷰를 현재 로컬 데이터 퍼블리셔에서 삭제한 데이터 반영
    func removePaper(paperId: String) {
        guard
            let fileDir = getFilePath(paperId: paperId),
            let previewFileDir = getPreviewFilePath(paperId: paperId) else { return }
        do {
            var currentPapers = papersSubject.value
            try FileManager.default.removeItem(at: fileDir)
            try FileManager.default.removeItem(at: previewFileDir)
            if let index = currentPapers.firstIndex(where: { $0.paperId == paperId }) {
                currentPapers.remove(at: index)
                papersSubject.send(currentPapers)
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    /// 현재 페이퍼 유효할 때 페이퍼 내 카드 삭제, 해당 결과 페이퍼를 데이터 퍼블리셔에 반영
    func removeCard(paperId: String, card: CardModel) {
        guard var currentPaper = paperSubject.value else { return }
        currentPaper.cards.removeAll(where: {$0.cardId == card.cardId })
        paperSubject.send(currentPaper)
    }
    
    /// 페이퍼 디렉토리에 페이퍼 덮어씌우기, 페이퍼 프리뷰 데이터 업데이트, 로컬 데이터 퍼블리셔 내 데이터 업데이트한 결과 반영, 제목 변경 반영
    func updatePaper(paper: PaperModel) {
        guard
            let fileDir = getFilePath(paper: paper),
            let previewFileDir = getPreviewFilePath(paperId: paper.paperId) else { return }
        do {
            var currentPapers = papersSubject.value
            let paperData = try JSONEncoder().encode(paper)
            try paperData.write(to: fileDir, options: .atomic)
            if let index = currentPapers.firstIndex(where: {$0.paperId == paper.paperId }) {
                var currentPaper = currentPapers[index]
                if currentPaper.title != paper.title {
                    currentPaper.title = paper.title
                    currentPapers[index] = currentPaper
                    let paperPreviewData = try JSONEncoder().encode(currentPaper)
                    try paperPreviewData.write(to: previewFileDir, options: .atomic)
                    papersSubject.send(currentPapers)
                }
                if currentPaper.thumbnailURLString != paper.thumbnailURLString {
                    currentPaper.thumbnailURLString = paper.thumbnailURLString
                    currentPapers[index] = currentPaper
                    let paperPreviewData = try JSONEncoder().encode(currentPaper)
                    try paperPreviewData.write(to: previewFileDir, options: .atomic)
                    papersSubject.send(currentPapers)
                }
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    /// 현재 페이퍼 유효할 때 카드 업데이트 및 로컬 데이터 퍼블리셔 반영
    func updateCard(paperId: String, card: CardModel) {
        guard var currentPaper = paperSubject.value else { return }
        if let index = currentPaper.cards.firstIndex(where: { $0.cardId == card.cardId }) {
            currentPaper.cards[index] = card
            paperSubject.send(currentPaper)
        }
    }
    
    /// 페이퍼 아이디를 바탕으로 저장된 페이퍼 로드, 로컬 데이터 퍼블리셔 업데이트
    func fetchPaper(paperId: String) {
        guard let fileDir = getFilePath(paperId: paperId) else { return }
        do {
            let paperData = try Data(contentsOf: fileDir)
            let paper = try JSONDecoder().decode(PaperModel.self, from: paperData)
            paperSubject.send(paper)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    /// 현재 로드된 페이퍼를 초기화
    func resetPaper() {
        paperSubject.send(nil)
    }
}
