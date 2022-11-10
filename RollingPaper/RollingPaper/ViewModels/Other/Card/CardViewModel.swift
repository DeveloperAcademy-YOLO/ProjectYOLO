//
//  CardViewModel.swift
//  RollingPaper
//
//  Created by Yosep on 2022/10/12.
//

import UIKit
import Combine

class CardViewModel {
    
    let localDatabaseManager: DatabaseManager
    let serverDatabaseManager: DatabaseManager
    private var backString: String = "setting"
    private let output: PassthroughSubject<Output, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    
    init(localDatabaseManager: DatabaseManager = LocalDatabaseFileManager.shared, serverDatabaseManager: DatabaseManager = FirestoreManager.shared) {
        self.localDatabaseManager = localDatabaseManager
        self.serverDatabaseManager = serverDatabaseManager
    }
    
    enum Input {
        case viewDidLoad
        case resultShown
        case setCardBackgroundImg(background: String) //CardBackgroundViewController 으로부터 backgroundImg Set
        case setCardResultImg(result: UIImage) //CardPencilKitViewController 으로부터 mergedImage Set
        case resultSend(isLocalDB: Bool)
    }
    
    enum Output {
        case getRecentCardBackgroundImgSuccess(background: String?)
        case getRecentCardBackgroundImgFail
        case getRecentCardResultImgSuccess(result: UIImage?)
        case getRecentCardResultImgFail
    }
    
    func transform(input: AnyPublisher<Input, Never>) -> AnyPublisher<Output, Never> {
        input.sink(receiveValue: { [weak self] event in
            guard let self = self else {return}
            switch event {
            case.viewDidLoad:
                self.getRecentCardBackgroundImg()
                self.getRecentCardResultImg()
            case.setCardBackgroundImg(let background):
                self.setCardBackgroundImg(background: background)
                self.getRecentCardBackgroundImg()
            case.setCardResultImg(let result):
                self.setCardResultImg(result: result)
                self.getRecentCardResultImg()
            case.resultShown:
                self.getRecentCardResultImg()
            case.resultSend(let isLocalDB):
                print("resultSend Good!!!!!!!")
                self.createCard(isLocalDB: isLocalDB)
            }
        })
        .store(in: &cancellables)
        return output.eraseToAnyPublisher()
    }
    
    private func setCardBackgroundImg(background: String) {
        backString = background
    }
    
    private func getRecentCardBackgroundImg() {
        if backString != "setting" {
            output.send(.getRecentCardBackgroundImgSuccess(background: backString))
        } else {
            output.send(.getRecentCardBackgroundImgFail)
        }
    }
    
    private func setCardResultImg(result: UIImage) {
        guard let result = result.jpegData(compressionQuality: 1)
        else { return }
        UserDefaults.standard.set(result, forKey: "cardResultImg")
    }
    
    private func createCard(isLocalDB: Bool) {
        print("WrittenPaperViewController에서 보냄 \(isLocalDB)")
        guard let recentResultImg = UserDefaults.standard.data(forKey: "cardResultImg")
        else { return }
        
        let currentTime = Date()
        var currentCardURL: String = ""
        var resultCardModel: CardModel = CardModel(date: currentTime, contentURLString: currentCardURL)
        
        print("currentCardURL 넣기 전 CardModel \(resultCardModel)")
        print("resultCardModel.cardId\(resultCardModel.cardId)")
        if isLocalDB {
            LocalStorageManager.uploadData(dataId: resultCardModel.cardId, data: recentResultImg, contentType: .jpeg, pathRoot: .card)
                .sink { completion in
                    switch completion {
                    case .finished: break
                    case .failure(let error):
                        print(error.localizedDescription)
                    }
                } receiveValue: { [weak self] cardURL in
                    guard
                        let currentCardURL = cardURL?.absoluteString,
                        let recentImage = UIImage(data: recentResultImg) else { return }
                    NSCacheManager.shared.setImage(image: recentImage, name: currentCardURL)
                     resultCardModel = CardModel(date: currentTime, contentURLString: currentCardURL)
                   
                    if let currentPaper = self?.localDatabaseManager.paperSubject.value {
                        self?.localDatabaseManager.addCard(paperId: currentPaper.paperId, card: resultCardModel)
                    }
                }
                .store(in: &cancellables)
            print("currentCardURL 넣은후 CardModel \(resultCardModel)")
        } else {
            FirebaseStorageManager.uploadData(dataId: "\(currentTime)", data: recentResultImg, contentType: .jpeg, pathRoot: .card)
                .sink { completion in
                    switch completion {
                    case .finished: break
                    case .failure(let error):
                        print(error.localizedDescription)
                    }
                } receiveValue: { [weak self] cardURL in
                    guard let currentCardURL = cardURL?.absoluteString else { return }
                    resultCardModel = CardModel(date: currentTime, contentURLString: currentCardURL)
                  
                    if let currentPaper = self?.serverDatabaseManager.paperSubject.value {
                        self?.serverDatabaseManager.addCard(paperId: currentPaper.paperId, card: resultCardModel)
                    }
                }
            print("currentCardURL 넣은후 CardModel \(resultCardModel)")
        }
    }
    
    private func getRecentCardResultImg() {
        if let recentResultImg = UserDefaults.standard.data(forKey: "cardResultImg") {
            let resultImg = UIImage(data: recentResultImg)
            output.send(.getRecentCardResultImgSuccess(result: resultImg))
        } else {
            output.send(.getRecentCardResultImgFail)
        }
    }
}
