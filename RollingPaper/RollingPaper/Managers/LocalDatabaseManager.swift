//
//  LocalDatabaseManager.swift
//  RollingPaper
//
//  Created by Junyeong Park on 2022/10/05.
//

import Foundation
import Combine

protocol LocalDatabaseManager {
    var papersSubject: PassthroughSubject<[PaperModel], Error> {get set}
    func setData(value: [PaperModel]) -> AnyPublisher<Bool, Never>
}
