//
//  LcalStorageManager.swift
//  RollingPaper
//
//  Created by Junyeong Park on 2022/10/14.
//

import Foundation
import Combine
import CombineCocoa

final class LocalStorageManager {
    
    static func uploadData(dataId: String, data: Data, contentType: DataContentType, pathRoot: DataPathRoot) -> AnyPublisher<URL?, Error> {
        return Future({ promise in
            if let documentDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                let folderDir = documentDir.appendingPathComponent("/\(pathRoot.rawValue)/\(contentType.rawValue)").absoluteURL
                let fileDir = folderDir.appendingPathComponent(dataId)
                do {
                    try data.write(to: fileDir, options: .atomic)
                    promise(.success(fileDir))
                } catch {
                    promise(.failure(error))
                }
            } else {
                promise(.failure(URLError(.badURL)))
            }
        })
        .eraseToAnyPublisher()
    }
    
    static func downloadData(urlString: String, maxSize: Int64 = Int64(1 * 1024 * 1024)) -> AnyPublisher<Data?, Error> {
        return Future({ promise in
            if
                let url = URL(string: urlString),
                let data = try? Data(contentsOf: url) {
                promise(.success(data))
            } else {
                promise(.failure(URLError(.badURL)))
            }
        })
        .eraseToAnyPublisher()
    }
}
