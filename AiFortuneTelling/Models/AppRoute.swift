//
//  AppRoute.swift
//  AiFortuneTelling
//

import Foundation

enum AppRoute: Hashable {
    case birthday
    case palmFace
    case auspiciousDate
    case result(String)
    case history
    case historyDetail(UUID)
    case settings
}
