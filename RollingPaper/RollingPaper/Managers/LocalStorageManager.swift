//
//  LcalStorageManager.swift
//  RollingPaper
//
//  Created by Junyeong Park on 2022/10/14.
//

import Combine
import UIKit

/// 데이터 파일 매니저 업로드 후 URL 정보 리턴 및 URL 문자열을 통해 해당 데이터 리턴 static 함수 추가
final class LocalStorageManager {
    
    static func uploadData(dataId: String, data: Data, contentType: DataContentType, pathRoot: DataPathRoot) -> URL? {
        guard let documentDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        let folderDir = documentDir.appendingPathComponent("/\(pathRoot.rawValue)/\(contentType.rawValue)").absoluteURL
        if !FileManager.default.fileExists(atPath: folderDir.relativePath) {
            do {
                try FileManager.default.createDirectory(atPath: folderDir.relativePath, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print(error.localizedDescription)
                return nil
            }
        }
        let fileDir = folderDir.appendingPathComponent(dataId)
        do {
            try data.write(to: fileDir, options: .atomic)
            return fileDir
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
    
    static func uploadData(dataId: String, data: Data, contentType: DataContentType, pathRoot: DataPathRoot) -> AnyPublisher<URL?, Error> {
        return Future({ promise in
            if let documentDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                let folderDir = documentDir.appendingPathComponent("/\(pathRoot.rawValue)/\(contentType.rawValue)").absoluteURL
                if !FileManager.default.fileExists(atPath: folderDir.relativePath) {
                    do {
                        try FileManager.default.createDirectory(atPath: folderDir.relativePath, withIntermediateDirectories: true, attributes: nil)
                    } catch {
                        promise(.failure(error))
                    }
                }
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
    
    static func downloadData(urlString: String) -> AnyPublisher<Data?, Error> {
        return Future({ promise in
            DispatchQueue.global(qos: .background).async {
                if
                    let url = URL(string: urlString),
                    let data = try? Data(contentsOf: url) {
                    promise(.success(data))
                } else {
                    promise(.failure(URLError(.badURL)))
                }
            }
        })
        .eraseToAnyPublisher()
    }
    
    static func donwloadData(urlString: String) -> UIImage? {
        guard
            let url = URL(string: urlString),
            let image = UIImage(contentsOfFile: url.path) else { return nil }
        return image
    }
}
