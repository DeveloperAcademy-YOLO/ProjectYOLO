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
    
    private func fetchPaperPreview(paperId: String) {
        database
            .collection(Constants.paperPreviewsPath.rawValue)
            .document(paperId)
            .getDocument(completion: { [weak self] document, error in
                guard
                    let data = document?.data(),
                    let jsonData = try? JSONSerialization.data(withJSONObject: data, options: .fragmentsAllowed),
                    let paperPreview = try? JSONDecoder().decode(PaperPreviewModel.self, from: jsonData),
                    error == nil else { return }
                self?.papersSubject.send(self?.papersSubject.value ?? [] + [paperPreview])
            })
    }
    
    private func addPaperIdInFirebase(paperId: String) {
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
    
    func fetchPaper(paperId: String) {
        database
            .collection(Constants.papersPath.rawValue)
            .document(paperId)
            .getDocument(completion: { [weak self] document, error in
                guard
                    let data = document?.data(),
                    let jsonData = try? JSONSerialization.data(withJSONObject: data, options: .fragmentsAllowed),
                    let paper = try? JSONDecoder().decode(PaperModel.self, from: jsonData),
                    error == nil else {
                    self?.paperSubject.send(nil)
                    return
                }
                self?.paperSubject.send(paper)
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
    
    func addPaper(paper: PaperModel) {
        let paperPreview = PaperPreviewModel(paperId: paper.paperId, date: paper.date, endTime: paper.endTime, title: paper.title, templateString: paper.templateString, thumbnailURLString: paper.thumbnailURLString)
        guard
            let currentUserEmail = currentUserEmail,
            let paperData = try? JSONEncoder().encode(paper),
            let paperPreviewData = try? JSONEncoder().encode(paperPreview),
            let paperDict = (try? JSONSerialization.jsonObject(with: paperData, options: .fragmentsAllowed)).flatMap({ $0 as? [String: Any] }),
            let paperPreviewDict = (try? JSONSerialization.jsonObject(with: paperPreviewData, options: .fragmentsAllowed)).flatMap({ $0 as? [String: Any]}) else { return }
        database
            .collection(Constants.papersPath.rawValue)
            .document(paper.paperId)
            .setData(paperDict)
        database
            .collection(Constants.paperPreviewsPath.rawValue)
            .document(paper.paperId)
            .setData(paperPreviewDict)
        addPaperIdInFirebase(paperId: paper.paperId)
        papersSubject.send(papersSubject.value + [paperPreview])
    }
    
    func addCard(paperId: String, card: CardModel) {
        guard let currentUserEmail = currentUserEmail else { return }

    }
    
    func removePaper(paperId: String) {
        
    }
    
    func removeCard(paperId: String, card: CardModel) {
        guard let currentUserEmail = currentUserEmail else { return }

    }
    
    func updatePaper(paper: PaperModel) {
        guard let currentUserEmail = currentUserEmail else { return }

    }
    
    func updateCard(paperId: String, card: CardModel) {
        guard let currentUserEmail = currentUserEmail else { return }

    }
    
    func savePaper() {
        
    }
}
