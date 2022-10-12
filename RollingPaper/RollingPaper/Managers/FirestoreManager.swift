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
        case userPaperPath = "user_papers"
        case papersPath = "rollingpaper_papers"
    }
    
    static let shared: DatabaseManager = FirestoreManager()
    var cardsSubject: CurrentValueSubject<[CardModel], Never> = .init([])
    var papersSubject: CurrentValueSubject<[PaperModel], Never> = .init([])
    private let database = Firestore.firestore()
    private let authManager: AuthManager
    private var cancellables = Set<AnyCancellable>()
    private var currentUserEmail: String?
    
    private init(authManager: AuthManager = FirebaseAuthManager.shared) {
        self.authManager = authManager
        bind()
    }
    
    private func loadPapers() {
        guard let currentUserEmail = currentUserEmail else { return }
        database
            .collection(Constants.usersCollectionPath.rawValue)
            .document(currentUserEmail)
            .collection(Constants.userPaperPath.rawValue)
            .getDocuments(completion: { [weak self] querySnapshot, error in
                guard let self = self else { return }
                guard
                    let documents = querySnapshot?.documents,
                    error == nil else { return }
                let papers = documents
                    .map({ $0.data() })
                    .compactMap({ try? JSONSerialization.data(withJSONObject: $0, options: [.fragmentsAllowed])})
                    .compactMap({ try? JSONDecoder().decode(PaperModel.self, from: $0)})
                self.papersSubject.send(papers)
            })
    }
    
    private func bind() {
        authManager
            .userProfileSubject
            .sink(receiveValue: { [weak self] userProfile in
                self?.currentUserEmail = userProfile?.email
                self?.loadPapers()
            })
            .store(in: &cancellables)
    }
    
    func addPaper(paper: PaperModel) {
        guard
            let currentUserEmail = currentUserEmail,
            let paperData = try? JSONEncoder().encode(paper),
            let paperDict = (try? JSONSerialization.jsonObject(with: paperData, options: .allowFragments)).flatMap({ $0 as? [String:Any] }) else { return }
        database
            .collection(Constants.papersPath.rawValue)
            .document(paper.paperId)
            .setData(paperDict)
        database
            .collection(Constants.usersCollectionPath.rawValue)
            .document(currentUserEmail)
            .collection(Constants.userPaperPath.rawValue)
            .document(paper.paperId)
            .setData(paperDict)
    }
    
    func addCard(paperId: String, card: CardModel) {
        guard let currentUserEmail = currentUserEmail else { return }

    }
    
    func removePaper(paper: PaperModel) {
        guard let currentUserEmail = currentUserEmail else { return }

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
    
    func addPaperObserver(paperId: String) {
        guard let currentUserEmail = currentUserEmail else { return }
        // 특정 document (특정 페이퍼 데이터를 가지고 있는 파이어베이스 파이어스토어) 데이터 변경을 감지
    }
}
