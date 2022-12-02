//
//  NetworkingManager.swift
//  RollingPaper
//
//  Created by Junyeong Park on 2022/12/02.
//

import Foundation
import Combine

class NetworkingManager {
    enum NetworkingError: LocalizedError {
        case badURLResponse(url: URL)
        case unknown
        var errorDescription: String? {
            switch self {
            case .badURLResponse(url: let url): return "[🔥] Bad Response from URL: \(url.absoluteString)"
            case .unknown: return "[⚠️] Unknown error occured"
            }
        }
    }
    
    static func handleURLResponse(output: URLSession.DataTaskPublisher.Output, url: URL) throws -> Data {
        guard
            let response = output.response as? HTTPURLResponse,
            response.statusCode >= 200 && response.statusCode < 300 else
        { throw NetworkingError.badURLResponse(url: url) }
        return output.data
    }
    
    static func download(with url: URL) -> AnyPublisher<Data, Error> {
        return URLSession
            .shared
            .dataTaskPublisher(for: url)
            .tryMap({try handleURLResponse(output: $0, url: url)})
            .retry(3)
            .eraseToAnyPublisher()
    }
    static func handleCompletion(completion: Subscribers.Completion<Error>) {
        switch completion {
        case .failure(let error):
            print(error.localizedDescription)
        case .finished: break
        }
    }
}
