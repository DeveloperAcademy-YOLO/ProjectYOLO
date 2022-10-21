//
//  CardResultViewModel.swift
//  RollingPaper
//
//  Created by Yosep on 2022/10/22.
//
import UIKit
import Combine

class CardResultViewModel {
    private var setCardResult: UIImage = UIImage()
    private let databaseManager: DatabaseManager
    
    init(databaseManager: DatabaseManager = LocalDatabaseFileManager.shared) {
        self.databaseManager = databaseManager
    }
    enum Input {
        case setCardResultImg(result: UIImage)
        case resultSend
    }
    private var cancellables = Set<AnyCancellable>()
    
    
    func transform(input: AnyPublisher<Input, Never>) {
        input
            .receive(on: DispatchQueue.global(qos: .background))
            .sink(receiveValue: { [weak self] event in
                guard let self = self else {return}
                switch event {
                case .setCardResultImg(let result):
                    self.setCardResult(result: result)
                case .resultSend:
                 print("ee")
                }
            })
            .store(in: &cancellables)
    }
    private func setCardResult(result: UIImage) {
        self.setCardResult = result
    }
}
    
