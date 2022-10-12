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
        case PapersPath = "rollingpaper_papers"
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
        loadPapers()
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
            .compactMap({ $0 })
            .sink(receiveValue: { [weak self] userProfile in
                self?.currentUserEmail = userProfile.email
            })
            .store(in: &cancellables)
    }
    
    func addPaper(paper: PaperModel) {
        
    }
    
    func addCard(paperId: String, card: CardModel) {
        
    }
    
    func removePaper(paper: PaperModel) {
        
    }
    
    func removeCard(paperId: String, card: CardModel) {
        
    }
    
    func updatePaper(paper: PaperModel) {
        
    }
    
    func updateCard(paperId: String, card: CardModel) {
        
    }
    
    func addPaperObserver(paperId: String) {
        // 특정 document (특정 페이퍼 데이터를 가지고 있는 파이어베이스 파이어스토어) 데이터 변경을 감지
    }
}
