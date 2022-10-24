//
//  URL+Extensions.swift
//  RollingPaper
//
//  Created by Junyeong Park on 2022/10/24.
//

import Foundation
import FirebaseDynamicLinks
import Combine

func getDynamicLink(with paper: PaperModel) -> AnyPublisher<URL, Error> {
    let prefix = "https://yolo.page.link"
    let paperId = paper.paperId
    let fallbackURLString = "https://github.com/DeveloperAcademy-YOLO/ProjectYOLO"
    var components = URLComponents()
    components.scheme = "https"
    components.host = "www.example.com"
    components.path = "/paperid"
    let paperIDQueryItem = URLQueryItem(name: "paperId", value: paperId)
    components.queryItems = [paperIDQueryItem]
    guard
        let linkParameter = components.url,
        let linkBuilder = DynamicLinkComponents(link: linkParameter, domainURIPrefix: prefix),
        let bundleID = Bundle.main.bundleIdentifier else {
        return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
    }
    linkBuilder.iOSParameters = DynamicLinkIOSParameters(bundleID: bundleID)
    let socialMetaTagPaprams = DynamicLinkSocialMetaTagParameters()
    socialMetaTagPaprams.title = paper.title
    if let thumnailURLString = paper.thumbnailURLString {
        socialMetaTagPaprams.imageURL = URL(string: thumnailURLString)
    }
    socialMetaTagPaprams.descriptionText = "\(paper.creator?.name ?? "YOLO")님과 함께 페이퍼를 만들어주세요!"
    guard
        let longDynamicLinkString = linkBuilder.url?.absoluteString,
        let resultURL = URL(string: longDynamicLinkString + "&ofl=\(fallbackURLString)") else {
        return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
    }
    
    return Future({ promise in
        DynamicLinkComponents.shortenURL(resultURL, options: nil) { url, warings, error in
            if let error = error {
                promise(.failure(error))
            } else if let url = url {
                promise(.success(url))
            } else {
                promise(.failure(URLError(.badURL)))
            }
        }
    })
    .eraseToAnyPublisher()
    
}
