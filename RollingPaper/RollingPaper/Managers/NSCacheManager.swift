//
//  NSCacheManager.swift
//  RollingPaper
//
//  Created by Junyeong Park on 2022/10/17.
//

import Foundation
import UIKit

final class NSCacheManager {
    static let shared = NSCacheManager()
    private init() {}
    
    private var imageCache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 100
        cache.totalCostLimit = 1024 * 1024 * 1024
        return cache
    }()
    
    private var viewCache: NSCache<NSString, UIView> = {
        let cache = NSCache<NSString, UIView>()
        cache.countLimit = 100
        cache.totalCostLimit = 1024 * 1024 * 1024
        return cache
    }()
    
    // 최초 set / 수정 모두 동일한 set 사용
    // setImage: thumbnailURLString에 따른 해당 이미지 리턴
    func setImage(image: UIImage, name: String) {
        imageCache.setObject(image, forKey: name as NSString)
    }
    
    // setView: cardId에 따른 해당 데이터 (UIView) 리턴
    func setView(view: UIView, name: String) {
        viewCache.setObject(view, forKey: name as NSString)
    }
    
    func getImage(name: String) -> UIImage? {
        guard let image = imageCache.object(forKey: name as NSString) else { return nil }
        return image
    }
    
    func getView(name: String) -> UIView? {
        guard let view = viewCache.object(forKey: name as NSString) else { return nil }
        return view
    }
    
    func remove(name: String) {
        imageCache.removeObject(forKey: name as NSString)
        viewCache.removeObject(forKey: name as NSString)
    }
}
