//
//  PaperModelFileManager.swift
//  RollingPaper
//
//  Created by Junyeong Park on 2022/10/05.
//

import Foundation
import Combine
import UIKit

final class PaperModelFileManager: DatabaseManager {
    
    static let shared: DatabaseManager = PaperModelFileManager()
    
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

    private func loadPaperPreviews() {
        guard let previewDir = getPreviewDirectoryPath() else { return }
        do {
            let previewContents = try FileManager.default.contentsOfDirectory(at: previewDir, includingPropertiesForKeys: nil, options: [])
            let previews = previewContents
                .compactMap({ try? Data(contentsOf: $0 )})
                .compactMap({ try? JSONDecoder().decode(PaperPreviewModel.self, from: $0)})
            papersSubject.send(previews)
        } catch {
            print(error.localizedDescription)
        }
    }
    
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
    
    func addCard(paperId: String, card: CardModel) {
        guard var currentPaper = paperSubject.value else { return }
        currentPaper.cards.append(card)
        paperSubject.send(currentPaper)
    }
    
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
    
    func removeCard(paperId: String, card: CardModel) {
        guard var currentPaper = paperSubject.value else { return }
        currentPaper.cards.removeAll(where: {$0.cardId == card.cardId })
        paperSubject.send(currentPaper)
    }
    
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
    
    func updateCard(paperId: String, card: CardModel) {
        guard var currentPaper = paperSubject.value else { return }
        if let index = currentPaper.cards.firstIndex(where: { $0.cardId == card.cardId }) {
            currentPaper.cards[index] = card
            paperSubject.send(currentPaper)
        }
    }
    
    func savePaper() {
        guard let currentPaper = paperSubject.value else { return }
        let paperId = currentPaper.paperId
        let currentPapers = papersSubject.value
        if currentPapers.firstIndex(where: {$0.paperId == paperId }) != nil {
            updatePaper(paper: currentPaper)
        } else {
            addPaper(paper: currentPaper)
        }
        paperSubject.send(nil)
    }
    
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
    
    func resetPaper() {
        paperSubject.send(nil)
    }
}
