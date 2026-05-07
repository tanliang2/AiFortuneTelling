//
//  AIAnalysisService.swift
//  AiFortuneTelling
//

import Foundation

protocol AIAnalysisServing {
    func submitBirthday(_ request: BirthdayFortuneRequest) async throws -> AnalysisTask
    func submitPalmFace(_ request: PalmFaceReadingRequest) async throws -> AnalysisTask
    func submitAuspiciousDate(_ request: AuspiciousDateRequest) async throws -> AnalysisTask
    func queryTask(id: String) async throws -> AnalysisTask
    func retryTask(id: String) async throws -> AnalysisTask
    func cancelTask(id: String) async throws
    func result(for id: String) async throws -> AnalysisResultPayload
    func deleteTask(id: String) async throws
}

struct AIServiceError: LocalizedError {
    let code: AnalysisErrorCode
    let detail: String?

    var errorDescription: String? {
        detail ?? code.message
    }
}

private struct StoredTask {
    var task: AnalysisTask
    var result: AnalysisResultPayload
    var queryCount: Int
}

final class MockAIAnalysisService: AIAnalysisServing {
    private var tasks: [String: StoredTask] = [:]

    func submitBirthday(_ request: BirthdayFortuneRequest) async throws -> AnalysisTask {
        try await shortDelay()
        let task = makeTask(kind: .birthday)
        let result = AnalysisResultPayload.birthday(makeBirthdayResult(request))
        tasks[task.id] = StoredTask(task: task, result: result, queryCount: 0)
        return task
    }

    func submitPalmFace(_ request: PalmFaceReadingRequest) async throws -> AnalysisTask {
        try await shortDelay()
        guard request.palmImageData.count > 1_000, request.faceImageData.count > 1_000 else {
            throw AIServiceError(code: .imageQualityRejected, detail: nil)
        }
        let task = makeTask(kind: .palmFace)
        let result = AnalysisResultPayload.palmFace(makePalmFaceResult())
        tasks[task.id] = StoredTask(task: task, result: result, queryCount: 0)
        return task
    }

    func submitAuspiciousDate(_ request: AuspiciousDateRequest) async throws -> AnalysisTask {
        try await shortDelay()
        let task = makeTask(kind: .auspiciousDate)
        let result = AnalysisResultPayload.auspiciousDate(makeAuspiciousDateResult(request))
        tasks[task.id] = StoredTask(task: task, result: result, queryCount: 0)
        return task
    }

    func queryTask(id: String) async throws -> AnalysisTask {
        try await shortDelay()
        guard var stored = tasks[id] else {
            throw AIServiceError(code: .serverFailed, detail: "未找到任务")
        }

        stored.queryCount += 1
        var task = stored.task
        task.updatedAt = Date()
        if stored.queryCount == 1 {
            task.status = .running
            task.progress = 0.55
        } else {
            task.status = .succeeded
            task.progress = 1
        }
        stored.task = task
        tasks[id] = stored
        return task
    }

    func retryTask(id: String) async throws -> AnalysisTask {
        guard var stored = tasks[id] else {
            throw AIServiceError(code: .serverFailed, detail: "未找到可重试任务")
        }
        stored.queryCount = 0
        stored.task.status = .pending
        stored.task.progress = 0.1
        stored.task.errorCode = nil
        stored.task.updatedAt = Date()
        tasks[id] = stored
        return stored.task
    }

    func cancelTask(id: String) async throws {
        guard var stored = tasks[id] else { return }
        stored.task.status = .cancelled
        stored.task.updatedAt = Date()
        tasks[id] = stored
    }

    func result(for id: String) async throws -> AnalysisResultPayload {
        guard let stored = tasks[id] else {
            throw AIServiceError(code: .serverFailed, detail: "未找到结果")
        }
        guard stored.task.schemaVersion == 1 else {
            throw AIServiceError(code: .unsupportedSchema, detail: nil)
        }
        return stored.result
    }

    func deleteTask(id: String) async throws {
        tasks.removeValue(forKey: id)
    }

    private func makeTask(kind: AnalysisKind) -> AnalysisTask {
        AnalysisTask(
            id: UUID().uuidString,
            kind: kind,
            status: .pending,
            progress: 0.1,
            schemaVersion: 1,
            errorCode: nil,
            diagnosticMessage: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    private func shortDelay() async throws {
        try await Task.sleep(nanoseconds: 250_000_000)
    }

    private func makeBirthdayResult(_ request: BirthdayFortuneRequest) -> BirthdayFortuneResult {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: request.birthday)
        let element = ["木", "火", "土", "金", "水"][month % 5]
        return BirthdayFortuneResult(
            constellation: constellation(for: request.birthday),
            eightCharacters: "甲辰年 乙未月 丙子日 丁酉时",
            fiveElements: "\(element)势较旺，适合以稳定节奏推进长期目标",
            personality: "\(request.name.isEmpty ? "你" : request.name)偏向观察细节、重视承诺，适合在明确规则下发挥判断力。",
            career: "近期事业重点在资源整合与节奏管理，避免同时开启过多方向。",
            relationship: "感情上适合直接表达边界与期待，减少反复试探造成的误会。",
            health: "建议保持规律作息与轻量运动，本内容不构成医学建议。",
            disclaimer: "以上结果由服务端大模型生成，仅供娱乐参考。"
        )
    }

    private func makePalmFaceResult() -> PalmFaceReadingResult {
        PalmFaceReadingResult(
            palmFeatures: ["生命线清晰，代表行动力较稳定", "智慧线较直，偏理性决策", "感情线末端上扬，表达方式较温和"],
            faceFeatures: ["额部饱满，适合规划型事务", "眉眼间距舒展，沟通耐心较好", "下庭轮廓稳定，重视长期安全感"],
            advice: "近期适合聚焦一个核心目标，把复杂选择拆成可执行清单。",
            riskNotice: "图片只用于本次上传分析，删除历史时会同步请求删除服务端任务数据。",
            disclaimer: "掌纹面相结果为娱乐参考，不用于身份识别、医疗判断或重大决策。"
        )
    }

    private func makeAuspiciousDateResult(_ request: AuspiciousDateRequest) -> AuspiciousDateResult {
        let calendar = Calendar.current
        let totalDays = max(0, calendar.dateComponents([.day], from: request.startDate, to: request.endDate).day ?? 0)
        guard totalDays >= 2 else {
            return AuspiciousDateResult(
                eventType: request.eventType,
                primary: nil,
                alternatives: [],
                noSuitableReason: "候选范围太短，建议至少提供 3 天以上用于筛选。",
                disclaimer: "黄道吉日由服务端大模型生成，仅供娱乐参考。"
            )
        }

        let first = calendar.date(byAdding: .day, value: min(2, totalDays), to: request.startDate) ?? request.startDate
        let second = calendar.date(byAdding: .day, value: min(5, totalDays), to: request.startDate) ?? request.endDate
        let third = calendar.date(byAdding: .day, value: min(8, totalDays), to: request.startDate) ?? request.endDate
        let primary = DateRecommendation(
            date: first,
            rank: 1,
            suitable: [request.eventType, "签约", "沟通安排"],
            avoid: ["仓促变更计划", "临时加码预算"],
            reason: "该日节奏平稳，适合把重要事项放在上午推进。",
            notes: "建议提前确认参与人时间，并预留缓冲。"
        )
        let alternatives = [
            DateRecommendation(date: second, rank: 2, suitable: ["准备材料", "拜访沟通"], avoid: ["夜间决策"], reason: "适合作为备选执行日。", notes: "适合先完成确认清单。"),
            DateRecommendation(date: third, rank: 3, suitable: ["复盘", "补充手续"], avoid: ["情绪化沟通"], reason: "适合收尾和复核。", notes: "关键文件建议二次确认。")
        ]
        return AuspiciousDateResult(
            eventType: request.eventType,
            primary: primary,
            alternatives: alternatives.filter { $0.date <= request.endDate },
            noSuitableReason: nil,
            disclaimer: "吉日推荐不构成法律、金融、医疗或投资建议。"
        )
    }

    private func constellation(for date: Date) -> String {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        switch (month, day) {
        case (3, 21...31), (4, 1...19): return "白羊座"
        case (4, 20...30), (5, 1...20): return "金牛座"
        case (5, 21...31), (6, 1...21): return "双子座"
        case (6, 22...30), (7, 1...22): return "巨蟹座"
        case (7, 23...31), (8, 1...22): return "狮子座"
        case (8, 23...31), (9, 1...22): return "处女座"
        case (9, 23...30), (10, 1...23): return "天秤座"
        case (10, 24...31), (11, 1...22): return "天蝎座"
        case (11, 23...30), (12, 1...21): return "射手座"
        case (12, 22...31), (1, 1...19): return "摩羯座"
        case (1, 20...31), (2, 1...18): return "水瓶座"
        default: return "双鱼座"
        }
    }
}

final class NetworkAIAnalysisService: AIAnalysisServing {
    private let endpoint: URL?
    private let authTokenProvider: () async -> String?

    init(endpoint: URL? = nil, authTokenProvider: @escaping () async -> String? = { nil }) {
        self.endpoint = endpoint
        self.authTokenProvider = authTokenProvider
    }

    func submitBirthday(_ request: BirthdayFortuneRequest) async throws -> AnalysisTask {
        try await unavailable()
    }

    func submitPalmFace(_ request: PalmFaceReadingRequest) async throws -> AnalysisTask {
        try await unavailable()
    }

    func submitAuspiciousDate(_ request: AuspiciousDateRequest) async throws -> AnalysisTask {
        try await unavailable()
    }

    func queryTask(id: String) async throws -> AnalysisTask {
        try await unavailable()
    }

    func retryTask(id: String) async throws -> AnalysisTask {
        try await unavailable()
    }

    func cancelTask(id: String) async throws {
        _ = endpoint
        _ = await authTokenProvider()
        throw AIServiceError(code: .serviceUnavailable, detail: "真实服务端域名、鉴权和上传协议尚未配置")
    }

    func result(for id: String) async throws -> AnalysisResultPayload {
        try await unavailable()
    }

    func deleteTask(id: String) async throws {
        _ = endpoint
        _ = await authTokenProvider()
    }

    private func unavailable<T>() async throws -> T {
        _ = endpoint
        _ = await authTokenProvider()
        throw AIServiceError(code: .serviceUnavailable, detail: "真实服务端域名、鉴权和上传协议尚未配置")
    }
}
