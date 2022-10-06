//
//  LocalDatabaseManager.swift
//  RollingPaper
//
//  Created by Junyeong Park on 2022/10/05.
//

import Foundation
import Combine

protocol LocalDatabaseManager {
    static var shared: LocalDatabaseManager { get }
    var papersSubject: CurrentValueSubject<[PaperModel], Error> { get set }
}
