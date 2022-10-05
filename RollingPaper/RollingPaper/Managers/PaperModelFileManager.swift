//
//  PaperModelFileManager.swift
//  RollingPaper
//
//  Created by Junyeong Park on 2022/10/05.
//

import Foundation
import Combine
import UIKit

final class PaperModelFileManager: LocalDatabaseManager {
    var papersSubject: PassthroughSubject<[PaperModel], Error> = .init()
    private let folderName = "downloaded_papers"
    init() {
        createFolderIfNeeded()
        loadPapers()
    }
    
    private func createFolderIfNeeded() {
        guard let url = getFolderPath() else { return }
        if !FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
                print("Created Folder")
            } catch {
                print("Error Created Folder")
                print(error.localizedDescription)
            }
        }
    }
    
    private func getFolderPath() -> URL? {
        return FileManager
            .default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent(folderName)
    }
    
    private func loadPapers() {
        guard
            let url = getFolderPath(),
            FileManager.default.fileExists(atPath: url.path) else {
            return
        }
        do {
            let data = try Data(contentsOf: url)
            let papers = try JSONDecoder().decode([PaperModel].self, from: data)
            self.papersSubject.send(papers)
        } catch {
            self.papersSubject.send(completion: .failure(error))
        }
    }
}
