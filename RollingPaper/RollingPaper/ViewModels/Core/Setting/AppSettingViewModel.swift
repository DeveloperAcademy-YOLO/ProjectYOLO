//
//  AppSettingViewModel.swift
//  RollingPaper
//
//  Created by Kelly Chui on 2022/11/12.
//

import Foundation
import FirebaseAuth
import Combine

class AppSettingViewModel {
    enum Section {
        case section1
        case section2
    }
    
    let sectionData1 = [
        AppSettingSectionModel(title: "색상 테마", detailView: UIView()),
        AppSettingSectionModel(title: "알림", detailView: UIView())
    ]
    
    let sectionData2 = [
        AppSettingSectionModel(title: "고객 지원", detailView: UIView()),
        AppSettingSectionModel(title: "정보", detailView: UIView())
    ]
    
}
