//
//  TemplateEnum.swift
//  RollingPaper
//
//  Created by Junyeong Park on 2022/10/05.
//

import Foundation

enum TemplateEnum: String, CaseIterable {
    case beige
    case halloween
    case wedding
    case christmas
    case beach
    case nature
    case retro
    case bear
    
    var template: TemplateModel {
        switch self {
        case .beige:
            return TemplateModel(templateString: "beige", templateTitle: "베이지", templateDescription: "베이지색으로 구성된 테마", colorHexes: [], stickerNames: ["Beige_maple", "Beige_cat", "Beige_dog2", "Beige_dog", "Beige_basket", "Beige_duck", "Beige_gingerbread", "Beige_old_paper", "Beige_ball"], backgroundImageNames: ["Pattern_beige1", "Pattern_beige2", "Pattern_beige3", "Pattern_beige4"])
        case .halloween:
            return TemplateModel(templateString: "halloween", templateTitle: "할로윈", templateDescription: "달콤하고도 으스스한 스티커와 카드로 이뤄진 테마", colorHexes: [], stickerNames: ["Halloween_Pumpkin", "Halloween_Candy", "Halloween_Bat", "Halloween_Ghost", "Halloween_StickCandy", "Halloween_Pumpkin2", "Halloween_Pot_Green", "Halloween_Pot_Purple", "Halloween_Pot_Red", "Halloween_Hat", "Halloween_choco", "Halloween_Pumpkin_Green", "Halloween_Pumpkin_Orange", "Halloween_Pumpkin_Pale", "Halloween_Ghost2", "Halloween_Ghost_with_legs", "Halloween_Bone", "Halloween_house", "Halloween_hat2", "Halloween_hand", "Halloween_cat", "Halloween_bat2"], backgroundImageNames: ["Rectangle_white", "Pattern_Bone", "Pattern_Pumpkin", "Pattern_Skull"])
        case .wedding:
            return TemplateModel(templateString: "wedding", templateTitle: "웨딩", templateDescription: "소중한 사람의 결혼을 축하해요.", colorHexes: [], stickerNames: ["wedding_bridegroom", "wedding_brird", "wedding_couple", "wedding_coupleCutepng", "wedding_flowers", "wedding_heartSticker", "wedding_Ringflower1", "wedding_Ringflower2", "wedding_Ringheart", "wedding_wedding car"], backgroundImageNames: ["Rectangle_white", "Pattern_wedding1", "Pattern_wedding2", "Pattern_wedding3"])
        case .christmas:
            return TemplateModel(templateString: "christmas", templateTitle: "크리스마스", templateDescription: "흰눈이 내리는 크리스마스", colorHexes: [], stickerNames: ["Christmas_Bell", "Christmas_Cookie", "Christmas_Decoration", "Christmas_Decoration2", "Christmas_Hat", "Christmas_Penguin1", "Christmas_Penguin2", "Christmas_Reindeer", "Christmas_Reindeer2", "Christmas_Santa", "Christmas_Santa2", "Christmas_Santa3", "Christmas_Santa4", "Christmas_Snowman"], backgroundImageNames: ["Pattern_Decoration", "Pattern_MoonChristmas", "Pattern_RedChristmas", "Pattern_WhiteChristmas"])
        case .beach:
            return TemplateModel(templateString: "beach", templateTitle: "해변", templateDescription: "시원한 해변가로 떠나요", colorHexes: [], stickerNames: ["Beach_ball", "Beach_bucket", "Beach_lemonade", "Beach_palmtree", "Beach_parasole", "Beach_seat", "Beach_shell1", "Beach_shell2", "Beach_yacht"], backgroundImageNames: ["Pattern_beach1", "Pattern_beach2", "Pattern_beach3", "Pattern_beach4"])
        case .nature:
            return TemplateModel(templateString: "nature", templateTitle: "자연", templateDescription: "초록초록 자연의 상쾌함", colorHexes: [], stickerNames: ["Nature_Sticker1", "Nature_Sticker2", "Nature_Sticker3", "Nature_Sticker4", "Nature_Sticker5", "Nature_Sticker6", "Nature_Sticker7", "Nature_Sticker8", "Nature_Sticker9"], backgroundImageNames: ["Pattern_nature1", "Pattern_nature2", "Pattern_nature3", "Pattern_nature4"])
        case .retro:
            return TemplateModel(templateString: "retro", templateTitle: "레트로", templateDescription: "레트로 감성을 느껴보세요.", colorHexes: [], stickerNames: ["Retro_Retro1", "Retro_Retro2", "Retro_Retro3", "Retro_Retro4", "Retro_Retro5", "Retro_Retro6", "Retro_Retro7", "Retro_Retro8", "Retro_Retro9", "Retro_Retro10", "Retro_Retro11"], backgroundImageNames: ["Pattern_Retro1", "Pattern_Retro2", "Pattern_Retro3", "Pattern_Retro4"])
        case .bear:
            return TemplateModel(templateString: "bear", templateTitle: "곰돌이", templateDescription: "앙증맞는 곰돌이 스티커가 들어있어요.", colorHexes: [], stickerNames: ["Bear_Sticker12", "Bear_Sticker11", "Bear_Sticker10", "Bear_Sticker4", "Bear_Sticker5", "Bear_Sticker6", "Bear_Sticker7", "Bear_Sticker8", "Bear_Sticker9", "Bear_Sticker3", "Bear_Sticker2", "Bear_Sticker1"], backgroundImageNames: ["Rectangle_white", "Pattern_bear1", "Pattern_bear2", "Pattern_bear3"])
        }
    }
}
