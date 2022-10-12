//
//  CardRootViewModel.swift
//  RollingPaper
//
//  Created by Yosep on 2022/10/12.
//

import UIKit
import Combine

class CardRootViewModel {
    var cardBackgroundImg = UIImage(named: "Rectangle")
    
    enum Input {
        case viewDidAppear
        case setCardBackgroundImg(background: UIImage) //CardBackgroundViewController 으로부터 backgroundImgGet
    }
    
    enum Output {
        case getRecentCardBackgroundImgSuccess(background: UIImage)
        case getRecentCardBackgroundImgFail
    }
    
    private let output: PassthroughSubject<Output, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    
    func transform(input: AnyPublisher<Input, Never>) -> AnyPublisher<Output, Never> {
        input.sink { [weak self] event in
            guard let self = self else {return}
            switch event {
            case.viewDidAppear:
                self.getRecentCardBackgroundImg()
            case.setCardBackgroundImg(let background):
                self.setCardBackgroundImg(background: background)
                self.getRecentCardBackgroundImg()
            }
        }
        .store(in: &cancellables)
        return output.eraseToAnyPublisher()
    }

    
    private func setCardBackgroundImg(background: UIImage) {
        guard let png = background.jpegData(compressionQuality: 0.85)
        else { return }// png로 바꿔서 넣어 버린다.
        UserDefaults.standard.set(png, forKey: "cardBackgroundImg")
    }
    
    private func getRecentCardBackgroundImg() {
        if let recentBackgroundImg = UserDefaults.standard.value(forKey: "cardBackgroundImg") as? UIImage,
           let backImg = UIImage(rawValue: recentBackgroundImg) {
            output.send(.getRecentCardBackgroundImgSuccess(background: backImg))
        } else {
            output.send(.getRecentCardBackgroundImgFail)
        }
    }
}
