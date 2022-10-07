//
//  PaperModelFileManager.swift
//  RollingPaper
//
//  Created by Junyeong Park on 2022/10/05.
//

import Foundation
import Combine
import UIKit

final class PaperModelFileManager: LocalDatabaseManager {
    static let shared: LocalDatabaseManager = PaperModelFileManager()
    
    var papersSubject: CurrentValueSubject<[PaperModel], Never> = .init([])
    private let folderName = "/downloaded_papers"
    private init() {
        createFolderIfNeeded()
        loadPapers()
    }
    
    private func getDocumentDirectoryPath() -> URL? {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    }
    
    private func getPaperDirectoryPath() -> URL? {
        guard let documentDir = getDocumentDirectoryPath() else { return nil }
        return documentDir.appendingPathComponent(folderName).absoluteURL
    }
    
    private func getFilePath(paper: PaperModel) -> URL? {
        guard let paperDir = getPaperDirectoryPath() else { return nil}
        return paperDir.appendingPathComponent(paper.paperId + ".json")
    }
    
    private func getFilePath(paperId: String) -> URL? {
        guard let paperDir = getPaperDirectoryPath() else { return nil }
        return paperDir.appendingPathComponent(paperId + ".json")
    }
    
    private func createFolderIfNeeded() {
        guard let paperDirectory = getPaperDirectoryPath() else { return }
        if !FileManager.default.fileExists(atPath: paperDirectory.relativePath) {
            do {
                try FileManager.default.createDirectory(atPath: paperDirectory.relativePath, withIntermediateDirectories: true, attributes: nil)
                print("Created Folder")
            } catch {
                print("Error Creating Folder")
                print(error.localizedDescription)
            }
        }
    }
    
    private func loadPapers() {
        guard let paperDir = getPaperDirectoryPath() else { return }
        do {
            let paperContents = try FileManager.default.contentsOfDirectory(at: paperDir, includingPropertiesForKeys: nil, options: [])
            let papers = try paperContents.map({ url in
                let paperData = try Data(contentsOf: url)
                let paper = try JSONDecoder().decode(PaperModel.self, from: paperData)
                return paper
            })
            papersSubject.send(papers)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func addPaper(paper: PaperModel) {
        guard let fileDir = getFilePath(paper: paper) else { return }
        do {
            let paperData = try JSONEncoder().encode(paper)
            try paperData.write(to: fileDir, options: .atomic)
            let currentPapers = papersSubject.value
            papersSubject.send(currentPapers + [paper])
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func addCard(paperId: String, card: CardModel) {
        guard let fileDir = getFilePath(paperId: paperId) else { return }
        do {
            var currentPapers = papersSubject.value
            if let index = currentPapers.firstIndex(where: { $0.paperId == paperId }) {
                var paper = currentPapers[index]
                paper.cards.append(card)
                currentPapers[index] = paper
                papersSubject.send(currentPapers)
                let paperData = try JSONEncoder().encode(paper)
                try paperData.write(to: fileDir)
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func removePaper(paper: PaperModel) {
        guard let fileDir = getFilePath(paper: paper) else { return }
        do {
            try FileManager.default.removeItem(at: fileDir)
            var currentPapers = papersSubject.value
            if let index = currentPapers.firstIndex(where: { $0.paperId == paper.paperId }) {
                currentPapers.remove(at: index)
                papersSubject.send(currentPapers)
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func removeCard(paperId: String, card: CardModel) {
        guard let fileDir = getFilePath(paperId: paperId) else { return }
        do {
            var currentPapers = papersSubject.value
            if let index = currentPapers.firstIndex(where: {$0.paperId == paperId}) {
                var paper = currentPapers[index]
                if let cardIndex = paper.cards.firstIndex(where: {$0.cardId == card.cardId}) {
                    paper.cards.remove(at: cardIndex)
                    currentPapers[index] = paper
                    papersSubject.send(currentPapers)
                    let paperData = try JSONEncoder().encode(paper)
                    try paperData.write(to: fileDir, options: .atomic)
                }
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func updatePaper(paper: PaperModel) {
        guard let fileDir = getFilePath(paper: paper) else { return }
        do {
            var currentPapers = papersSubject.value
            if let index = currentPapers.firstIndex(where: { $0.paperId == paper.paperId }) {
                currentPapers[index] = paper
                papersSubject.send(currentPapers)
            }
            let paperData = try JSONEncoder().encode(paper)
            try paperData.write(to: fileDir, options: .atomic)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func updateCard(paperId: String, card: CardModel) {
        guard let fileDir = getFilePath(paperId: paperId) else { return }
        do {
            var currentPapers = papersSubject.value
            if let index = currentPapers.firstIndex(where: { $0.paperId == paperId }) {
                var paper = currentPapers[index]
                if let cardIndex = paper.cards.firstIndex(where: { $0.cardId == card.cardId }) {
                    paper.cards[cardIndex] = card
                    currentPapers[index] = paper
                    papersSubject.send(currentPapers)
                    let paperData = try JSONEncoder().encode(paper)
                    try paperData.write(to: fileDir, options: .atomic)
                }
            }
        } catch {
            print(error.localizedDescription)
        }
    }
}

