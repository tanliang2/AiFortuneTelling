//
//  AnalysisModels.swift
//  AiFortuneTelling
//

import Foundation

enum AnalysisKind: String, Codable, CaseIterable, Identifiable, Hashable {
    case birthday
    case palmFace
    case auspiciousDate

    var id: String { rawValue }

    var title: String {
        switch self {
        case .birthday:
            return "生日命理"
        case .palmFace:
            return "掌纹面相"
        case .auspiciousDate:
            return "黄道吉日"
        }
    }

    var iconName: String {
        switch self {
        case .birthday:
            return "calendar.badge.clock"
        case .palmFace:
            return "camera.viewfinder"
        case .auspiciousDate:
            return "sparkles"
        }
    }
}

enum AnalysisTaskStatus: String, Codable, Hashable {
    case pending
    case running
    case succeeded
    case failed
    case cancelled

    var title: String {
        switch self {
        case .pending:
            return "等待提交"
        case .running:
            return "生成中"
        case .succeeded:
            return "已完成"
        case .failed:
            return "生成失败"
        case .cancelled:
            return "已取消"
        }
    }
}

enum AnalysisErrorCode: String, Codable, Hashable {
    case networkUnavailable
    case timeout
    case serverFailed
    case invalidInput
    case imageQualityRejected
    case unsupportedSchema
    case serviceUnavailable

    var message: String {
        switch self {
        case .networkUnavailable:
            return "网络不可用，请检查连接后重试"
        case .timeout:
            return "任务耗时较长，请稍后重试"
        case .serverFailed:
            return "服务端生成失败，请稍后重试"
        case .invalidInput:
            return "输入信息不完整或格式不正确"
        case .imageQualityRejected:
            return "图片质量不足，请重新拍摄清晰正面照片"
        case .unsupportedSchema:
            return "当前版本暂不支持该结果结构"
        case .serviceUnavailable:
            return "真实服务暂未配置，当前仅支持 mock 流程"
        }
    }

    var isRecoverable: Bool {
        switch self {
        case .networkUnavailable, .timeout, .serverFailed:
            return true
        case .invalidInput, .imageQualityRejected, .unsupportedSchema, .serviceUnavailable:
            return false
        }
    }
}

struct AnalysisTask: Identifiable, Codable, Hashable {
    let id: String
    let kind: AnalysisKind
    var status: AnalysisTaskStatus
    var progress: Double
    var schemaVersion: Int
    var errorCode: AnalysisErrorCode?
    var diagnosticMessage: String?
    var createdAt: Date
    var updatedAt: Date
}

struct BirthdayFortuneRequest: Codable, Hashable {
    var name: String
    var gender: String
    var birthday: Date
    var birthTime: Date
    var region: String
}

struct BirthdayFortuneResult: Codable, Hashable {
    var constellation: String
    var eightCharacters: String
    var fiveElements: String
    var personality: String
    var career: String
    var relationship: String
    var health: String
    var disclaimer: String

    var summary: String {
        "\(constellation)｜\(fiveElements)"
    }
}

struct PalmFaceReadingRequest: Hashable {
    var palmImageData: Data
    var faceImageData: Data
}

struct PalmFaceReadingResult: Codable, Hashable {
    var palmFeatures: [String]
    var faceFeatures: [String]
    var advice: String
    var riskNotice: String
    var disclaimer: String

    var summary: String {
        "掌纹 \(palmFeatures.count) 项，面相 \(faceFeatures.count) 项"
    }
}

struct AuspiciousDateRequest: Codable, Hashable {
    var eventType: String
    var startDate: Date
    var endDate: Date
    var birthday: Date?
}

struct DateRecommendation: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var date: Date
    var rank: Int
    var suitable: [String]
    var avoid: [String]
    var reason: String
    var notes: String
}

struct AuspiciousDateResult: Codable, Hashable {
    var eventType: String
    var primary: DateRecommendation?
    var alternatives: [DateRecommendation]
    var noSuitableReason: String?
    var disclaimer: String

    var summary: String {
        if let primary {
            return "\(eventType)｜首选 \(primary.date.formatted(date: .numeric, time: .omitted))"
        }
        return noSuitableReason ?? "暂无合适日期"
    }
}

enum AnalysisResultPayload: Codable, Hashable {
    case birthday(BirthdayFortuneResult)
    case palmFace(PalmFaceReadingResult)
    case auspiciousDate(AuspiciousDateResult)
}

struct HistoryRecord: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var kind: AnalysisKind
    var createdAt: Date
    var inputSummary: String
    var resultSummary: String
    var taskID: String
    var result: AnalysisResultPayload
}
