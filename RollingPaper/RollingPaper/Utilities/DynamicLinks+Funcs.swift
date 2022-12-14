//
//  DynamicLinks+Funcs.swift
//  RollingPaper
//
//  Created by Junyeong Park on 2022/10/24.
//

import Foundation
import FirebaseDynamicLinks
import Combine

enum PaperShareRoute: String {
    case write
    case gift
}

func getPaperShareLink(creator: UserModel?, paperId: String, paperTitle: String, paperThumbnailURLString: String?, route: PaperShareRoute) -> AnyPublisher<URL, Error> {
    let prefix = "https://yolo.page.link"
    let fallbackURLString = "https://github.com/DeveloperAcademy-YOLO/ProjectYOLO"
    var components = URLComponents()
    components.scheme = "https"
    components.host = "www.example.com"
    let paperIDQueryItem = URLQueryItem(name: "paperId", value: paperId)
    let routeQueryItem = URLQueryItem(name: "route", value: route.rawValue)
    components.queryItems = [paperIDQueryItem, routeQueryItem]
    guard
        let linkParameter = components.url,
        let linkBuilder = DynamicLinkComponents(link: linkParameter, domainURIPrefix: prefix),
        let bundleID = Bundle.main.bundleIdentifier else {
        return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
    }
    let iOSparameters = DynamicLinkIOSParameters(bundleID: bundleID)
    iOSparameters.appStoreID = "6444035444"
    linkBuilder.iOSParameters = iOSparameters
    let socialMetaTagPaprams = DynamicLinkSocialMetaTagParameters()
    socialMetaTagPaprams.title = paperTitle
    if let thumnailURLString = paperThumbnailURLString {
        socialMetaTagPaprams.imageURL = URL(string: thumnailURLString)
    }
    let descriptionText: String
    if route == .write {
        descriptionText = "\(creator?.name ?? "YOLO")님과 함께 보드를 꾸며주세요!"
    } else {
        descriptionText = "\(creator?.name ?? "YOLO")님이 보낸 선물이 도착했습니다!"
    }
    socialMetaTagPaprams.descriptionText = descriptionText
    linkBuilder.socialMetaTagParameters = socialMetaTagPaprams
    guard
        let longDynamicLinkString = linkBuilder.url?.absoluteString,
        let resultURL = URL(string: longDynamicLinkString) else {
        return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
    }
    return Future({ promise in
        DynamicLinkComponents.shortenURL(resultURL, options: nil) { url, _, error in
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

func getPaperShareLink(with paper: PaperModel, route: PaperShareRoute) -> AnyPublisher<URL, Error> {
    return getPaperShareLink(creator: paper.creator, paperId: paper.paperId, paperTitle: paper.title, paperThumbnailURLString: paper.thumbnailURLString, route: route)
}
