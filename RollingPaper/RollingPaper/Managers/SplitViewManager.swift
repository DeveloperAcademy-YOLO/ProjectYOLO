//
//  SplitViewManager.swift
//  RollingPaper
//
//  Created by 김동락 on 2022/10/20.
//

import UIKit
import Combine

class SplitViewManager {
    enum Input {
        case viewIsOpened
        case viewIsClosed
    }
    enum Output {
        case viewIsOpened
        case viewIsClosed
    }
    static let shared = SplitViewManager()
    private let output: PassthroughSubject<Output, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    
    // Input 시그널을 받으면 그에 따라 어떤 행동을 할지 정함
    func transform(input: AnyPublisher<Input, Never>) {
        input.sink(receiveValue: { [weak self] event in
            switch event {
            case .viewIsOpened:
                self?.output.send(.viewIsOpened)
            case .viewIsClosed:
                self?.output.send(.viewIsClosed)
            }
        })
        .store(in: &cancellables)
    }
    
    // Output을 받고싶다면 해당 리턴값을 구독하면됨
    func getOutput() -> AnyPublisher<Output, Never> {
        return output.eraseToAnyPublisher()
    }
}
