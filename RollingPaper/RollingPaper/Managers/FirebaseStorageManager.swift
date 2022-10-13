//
//  FirebaseStorageManager.swift
//  RollingPaper
//
//  Created by Junyeong Park on 2022/10/12.
//

import Foundation
import FirebaseStorage
import Combine

final class FirebaseStorageManager {
    enum CardContentType: String {
        case jpeg = "image/jpeg"
        case png = "image/png"
        case data = "data"
    }
    
    static func uploadData(dataId: String, data: Data, contentType: CardContentType, pathRoot: String, completion: @escaping (Result<URL?, Error>) -> Void) {
        let metadata = StorageMetadata()
        metadata.contentType = contentType.rawValue
        let reference = Storage.storage().reference().child("\(dataId)")
        reference.putData(data, metadata: metadata, completion: { _, error in
            if let error = error {
                print(error.localizedDescription)
                completion(.failure(error))
            } else {
                print("Storage data put Succeed")
                reference.downloadURL(completion: { url, error in
                    if let error = error {
                        print(error.localizedDescription)
                        completion(.failure(error))
                    } else {
                        completion(.success(url))
                    }
                })
            }
        })
    }
    
    static func downloadData(urlString: String, maxSize: Int64 = Int64(1 * 1024 * 1024), completion: @escaping (Result<Data?, Error>) -> Void) {
        let reference = Storage.storage().reference(forURL: urlString)
        reference.getData(maxSize: maxSize, completion: { data, error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(data))
            }
        })
    }
    
    static func downloadData(urlString: String, maxSize: Int64 = Int64(1 * 1024 * 1024)) -> AnyPublisher<Data?, Never> {
        let reference = Storage.storage().reference(forURL: urlString)
        return Future { promise in
            reference.getData(maxSize: maxSize) { data, error in
                if let error = error {
                    promise(.success(nil))
                } else {
                    promise(.success(data))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}
