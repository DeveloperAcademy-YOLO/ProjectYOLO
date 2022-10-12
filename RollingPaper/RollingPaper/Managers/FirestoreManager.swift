//
//  DatabaseManager.swift
//  RollingPaper
//
//  Created by Junyeong Park on 2022/10/04.
//

import Foundation
import FirebaseFirestore
import Combine
import CombineCocoa

final class FirestoreManager: DatabaseManager {
    
    enum Constants: String {
        case usersCollectionPath = "rollingpaper_users"
        case papersPath = "rollingpaper_papers"
        case paperPreviewsPath = "rollingpaper_paperPreviews"
    }
    
    static let shared: DatabaseManager = FirestoreManager()
    var papersSubject: CurrentValueSubject<[PaperPreviewModel], Never> = .init([])
    var paperSubject: CurrentValueSubject<PaperModel?, Never> = .init(nil)
    private let database = Firestore.firestore()
    private let authManager: AuthManager
    private var cancellables = Set<AnyCancellable>()
    private var currentUserEmail: String?
    
    private init(authManager: AuthManager = FirebaseAuthManager.shared) {
        self.authManager = authManager
        bind()
    }
    
    func fetchPaper(paperId: String) {
        database
            .collection(Constants.papersPath.rawValue)
            .document(paperId)
            .getDocument(completion: { [weak self] document, error in
                guard
                    let data = document?.data(),
                    let paper = self?.getPaper(from: data),
                    error == nil else {
                    self?.loadPaperPreviews()
                    // 페이퍼 아이디에 대한 페이퍼가 존재하지 않을 때 현재 프리뷰 업데이트
                    self?.paperSubject.send(nil)
                    return
                }
                self?.paperSubject.send(paper)
            })
    }
    
    func addPaper(paper: PaperModel) {
        let paperPreview = PaperPreviewModel(paperId: paper.paperId, date: paper.date, endTime: paper.endTime, title: paper.title, templateString: paper.templateString, thumbnailURLString: paper.thumbnailURLString)
        guard
            currentUserEmail != nil,
            let paperDict = getPaperDict(with: paper) else { return }
        database
            .collection(Constants.papersPath.rawValue)
            .document(paper.paperId)
            .setData(paperDict) { [weak self] error in
                if let error = error {
                    print(error.localizedDescription)
                } else {
                    print("Paper added in Firebase Successfully")
                    self?.setPaperPreview(paperPreview: paperPreview)
                    self?.addUsersPaperId(paperId: paper.paperId)
                    self?.papersSubject.send(self?.papersSubject.value ?? [] + [paperPreview])
                }
            }
    }
    
    func addCard(paperId: String, card: CardModel) {
        guard var currentPaper = paperSubject.value else { return }
        currentPaper.cards.append(card)
        guard let paperDict = getPaperDict(with: currentPaper) else { return }
        database
            .collection(Constants.papersPath.rawValue)
            .document(paperId)
            .setData(paperDict) { [weak self] error in
                if let error = error {
                    print(error.localizedDescription)
                } else {
                    self?.paperSubject.send(currentPaper)
                    print("Card added in Firebase Succesfully")
                }
            }
    }
    
    func removePaper(paperId: String) {
        database
            .collection(Constants.papersPath.rawValue)
            .document(paperId)
            .delete(completion: { [weak self] error in
                if let error = error {
                    print(error.localizedDescription)
                } else {
                    self?.removePaperPreview(paperId: paperId)
                    self?.removeUsersPaperId(paperId: paperId)
                    print("Paper Removed in Firebase Successfully")
                }
            })
    }
    
    func removeCard(paperId: String, card: CardModel) {
        database
            .collection(Constants.papersPath.rawValue)
            .document(paperId)
            .getDocument(completion: { [weak self] document, error in
                guard
                    error == nil,
                    let data = document?.data(),
                    var paper = self?.getPaper(from: data) else {
                    print("Fetch Paper Failed")
                    return
                }
                paper.cards.removeAll(where: {$0.cardId == card.cardId })
                self?.updatePaper(paper: paper)
            })
    }
    
    func updatePaper(paper: PaperModel) {
        guard let paperDict = getPaperDict(with: paper) else { return }
        let paperPreview = PaperPreviewModel(paperId: paper.paperId, date: paper.date, endTime: paper.endTime, title: paper.title, templateString: paper.templateString, thumbnailURLString: paper.thumbnailURLString)
        database
            .collection(Constants.papersPath.rawValue)
            .document(paper.paperId)
            .setData(paperDict) { [weak self] error in
                if let error = error {
                    print(error.localizedDescription)
                } else {
                    print("Paper Updated in Firebase Successfully")
                    self?.setPaperPreview(paperPreview: paperPreview)
                }
            }
    }
    
    func updateCard(paperId: String, card: CardModel) {
        guard var currentPaper = paperSubject.value else { return }
        if let index = currentPaper.cards.firstIndex(where: { $0.cardId == card.cardId }) {
            currentPaper.cards[index] = card
            updatePaper(paper: currentPaper)
        }
    }
    
    func savePaper() {
        
    }
}

extension FirestoreManager {
    private func fetchPaperPreview(paperId: String) {
        database
            .collection(Constants.paperPreviewsPath.rawValue)
            .document(paperId)
            .getDocument(completion: { [weak self] document, error in
                guard
                    let data = document?.data(),
                    let paperPreview = self?.getPaperPreview(from: data),
                    error == nil else { return }
                self?.papersSubject.send(self?.papersSubject.value ?? [] + [paperPreview])
            })
    }
    
    private func removePaperPreview(paperId: String) {
        database
            .collection(Constants.paperPreviewsPath.rawValue)
            .document(paperId)
            .delete(completion: { [weak self] error in
                if let error = error {
                    print(error.localizedDescription)
                } else {
                    print("PaperPreview Successfully Removed")
                }
            })
    }
    
    private func setPaperPreview(paperPreview: PaperPreviewModel) {
        guard let paperPreviewDict = getPaperPreviewDict(with: paperPreview) else { return }
        database
            .collection(Constants.paperPreviewsPath.rawValue)
            .document(paperPreview.paperId)
            .setData(paperPreviewDict) { error in
                if let error = error {
                    print(error.localizedDescription)
                } else {
                    print("PaperPreview Successfully Set")
                }
            }
    }
    
    private func addUsersPaperId(paperId: String) {
        guard let currentUserEmail = currentUserEmail else { return }
        database
            .collection(Constants.usersCollectionPath.rawValue)
            .document(currentUserEmail)
            .getDocument(completion: { [weak self] snapshot, error in
                guard
                    error == nil,
                    var dictionary = snapshot?.data() as? [String: [String]],
                    var paperIds = dictionary["paperIds"] else { return }
                paperIds.append(paperId)
                dictionary["paperIds"] = paperIds
                self?.database
                    .collection(Constants.usersCollectionPath.rawValue)
                    .document(currentUserEmail)
                    .setData(dictionary)
            })
    }
    
    private func removeUsersPaperId(paperId: String) {
        guard let currentUserEmail = currentUserEmail else { return }
        database
            .collection(Constants.usersCollectionPath.rawValue)
            .document(currentUserEmail)
            .getDocument(completion: { [weak self] snapshot, error in
                guard
                    error == nil,
                    var dictionary = snapshot?.data() as? [String: [String]],
                    var paperIds = dictionary["paperIds"] else { return }
                paperIds.removeAll(where: {$0 == paperId })
                dictionary["paperIds"] = paperIds
                self?.database
                    .collection(Constants.usersCollectionPath.rawValue)
                    .document(currentUserEmail)
                    .setData(dictionary)
            })
    }
    
    private func loadPaperPreviews() {
        guard let currentUserEmail = currentUserEmail else { return }
        database
            .collection(Constants.usersCollectionPath.rawValue)
            .document(currentUserEmail)
            .getDocument(completion: { [weak self] snapshot, error in
                guard
                    error == nil,
                    let dictionary = snapshot?.data() as? [String: [String]],
                    let paperIds = dictionary["paperIds"] else { return }
                paperIds.forEach({ paperId in
                    self?.fetchPaperPreview(paperId: paperId)
                })
            })
    }
    
    private func bind() {
        authManager
            .userProfileSubject
            .sink(receiveValue: { [weak self] userProfile in
                self?.currentUserEmail = userProfile?.email
                self?.loadPaperPreviews()
            })
            .store(in: &cancellables)
    }
    
    private func getPaperDict(with paper: PaperModel) -> [String: Any]? {
        guard
            let paperData = try? JSONEncoder().encode(paper),
            let paperDict = (try? JSONSerialization.jsonObject(with: paperData, options: .fragmentsAllowed)).flatMap({ $0 as? [String: Any] }) else {
            return nil
        }
        return paperDict
    }
    
    private func getPaperPreviewDict(with paperPreview: PaperPreviewModel) -> [String: Any]? {
        guard
            let paperPreviewData = try? JSONEncoder().encode(paperPreview),
            let paperPreviewDict = (try? JSONSerialization.jsonObject(with: paperPreviewData, options: .fragmentsAllowed)).flatMap({ $0 as? [String: Any] }) else {
            return nil
        }
        return paperPreviewDict
    }
    
    private func getPaper(from paperDict: [String: Any]) -> PaperModel? {
        guard
            let jsonData = try? JSONSerialization.data(withJSONObject: paperDict, options: .fragmentsAllowed),
            let paper = try? JSONDecoder().decode(PaperModel.self, from: jsonData) else {
            return nil
        }
        return paper
    }
    
    private func getPaperPreview(from paperPreviewDict: [String: Any]) -> PaperPreviewModel? {
        guard
            let jsonData = try? JSONSerialization.data(withJSONObject: paperPreviewDict, options: .fragmentsAllowed),
            let paperPreview = try? JSONDecoder().decode(PaperPreviewModel.self, from: jsonData) else {
            return nil
        }
        return paperPreview
    }
    
}
