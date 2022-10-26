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
    case present
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
    linkBuilder.iOSParameters = DynamicLinkIOSParameters(bundleID: bundleID)
    let socialMetaTagPaprams = DynamicLinkSocialMetaTagParameters()
    socialMetaTagPaprams.title = paperTitle
    if let thumnailURLString = paperThumbnailURLString {
        socialMetaTagPaprams.imageURL = URL(string: thumnailURLString)
    }
    socialMetaTagPaprams.descriptionText = "\(creator?.name ?? "YOLO")님과 함께 페이퍼를 만들어주세요!"
    linkBuilder.socialMetaTagParameters = socialMetaTagPaprams
    guard
        let longDynamicLinkString = linkBuilder.url?.absoluteString,
        let resultURL = URL(string: longDynamicLinkString + "&ofl=\(fallbackURLString)" + "&ifl=\(fallbackURLString)" + "&ipfl=\(fallbackURLString)" + "&ipbi=\(bundleID)" + "&efr=1") else {
        return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
    }
    
    print("long dynamic link: \(longDynamicLinkString)")
    print("result dynamic link: \(resultURL.absoluteString)")
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

//func getPaperShareLinkWithRestAPI(with paper: PaperModel, route: PaperShareRoute) -> AnyPublisher<URL, Error> {
//    let webAPIKey = "AIzaSyC98JEJnnMNA3mOzM37bIhc2AtvCD8xV6I"
//    let postURLString = "https://firebasedynamiclinks.googleapis.com/v1/shortLinks?key=\(webAPIKey)"
//    guard let postURL = URL(string: postURLString) else { return Fail(error: URLError(.badURL)).eraseToAnyPublisher() }
//    var postURLRequest = URLRequest(url: postURL)
//    postURLRequest.httpMethod = "POST"
//    postURLRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
//
//}
