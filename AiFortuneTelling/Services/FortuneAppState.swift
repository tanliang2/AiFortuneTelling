//
//  FortuneAppState.swift
//  AiFortuneTelling
//

import Combine
import Foundation

@MainActor
final class FortuneAppState: ObservableObject {
    @Published var taskStates: [String: AnalysisTask] = [:]
    @Published var results: [String: AnalysisResultPayload] = [:]
    @Published var latestError: AIServiceError?

    let historyStore = HistoryStore()
    private let service: AIAnalysisServing

    init(service: AIAnalysisServing? = nil) {
        self.service = service ?? MockAIAnalysisService()
    }

    func submitBirthday(_ request: BirthdayFortuneRequest) async -> String? {
        do {
            latestError = nil
            let task = try await service.submitBirthday(request)
            taskStates[task.id] = task
            let result = try await awaitSucceededResult(taskID: task.id)
            saveHistory(taskID: task.id, kind: .birthday, inputSummary: birthdaySummary(request), result: result)
            return task.id
        } catch {
            latestError = normalize(error)
            return nil
        }
    }

    func submitPalmFace(_ request: PalmFaceReadingRequest) async -> String? {
        do {
            latestError = nil
            let task = try await service.submitPalmFace(request)
            taskStates[task.id] = task
            let result = try await awaitSucceededResult(taskID: task.id)
            saveHistory(taskID: task.id, kind: .palmFace, inputSummary: "掌纹与面相图片各 1 张", result: result)
            return task.id
        } catch {
            latestError = normalize(error)
            return nil
        }
    }

    func submitAuspiciousDate(_ request: AuspiciousDateRequest) async -> String? {
        do {
            latestError = nil
            let task = try await service.submitAuspiciousDate(request)
            taskStates[task.id] = task
            let result = try await awaitSucceededResult(taskID: task.id)
            saveHistory(taskID: task.id, kind: .auspiciousDate, inputSummary: auspiciousSummary(request), result: result)
            return task.id
        } catch {
            latestError = normalize(error)
            return nil
        }
    }

    func retry(taskID: String) async {
        do {
            latestError = nil
            let task = try await service.retryTask(id: taskID)
            taskStates[taskID] = task
            let result = try await awaitSucceededResult(taskID: taskID)
            results[taskID] = result
        } catch {
            latestError = normalize(error)
        }
    }

    func cancel(taskID: String) async {
        do {
            try await service.cancelTask(id: taskID)
            if var task = taskStates[taskID] {
                task.status = .cancelled
                taskStates[taskID] = task
            }
        } catch {
            latestError = normalize(error)
        }
    }

    func deleteHistory(_ record: HistoryRecord) async {
        _ = historyStore.delete(id: record.id)
        do {
            try await service.deleteTask(id: record.taskID)
        } catch {
            latestError = normalize(error)
        }
    }

    func clearHistory() async {
        let removed = historyStore.clearAll()
        for record in removed {
            try? await service.deleteTask(id: record.taskID)
        }
    }

    private func awaitSucceededResult(taskID: String) async throws -> AnalysisResultPayload {
        for _ in 0..<4 {
            let task = try await service.queryTask(id: taskID)
            taskStates[taskID] = task
            switch task.status {
            case .succeeded:
                let result = try await service.result(for: taskID)
                results[taskID] = result
                return result
            case .failed:
                throw AIServiceError(code: task.errorCode ?? .serverFailed, detail: task.diagnosticMessage)
            case .cancelled:
                throw AIServiceError(code: .serverFailed, detail: "任务已取消")
            case .pending, .running:
                continue
            }
        }
        throw AIServiceError(code: .timeout, detail: nil)
    }

    private func saveHistory(taskID: String, kind: AnalysisKind, inputSummary: String, result: AnalysisResultPayload) {
        let record = HistoryRecord(
            kind: kind,
            createdAt: Date(),
            inputSummary: inputSummary,
            resultSummary: result.summaryText,
            taskID: taskID,
            result: result
        )
        historyStore.add(record)
    }

    private func birthdaySummary(_ request: BirthdayFortuneRequest) -> String {
        "\(request.gender)｜\(request.region)｜\(request.birthday.formatted(date: .numeric, time: .omitted))"
    }

    private func auspiciousSummary(_ request: AuspiciousDateRequest) -> String {
        "\(request.eventType)｜\(request.startDate.formatted(date: .numeric, time: .omitted)) - \(request.endDate.formatted(date: .numeric, time: .omitted))"
    }

    private func normalize(_ error: Error) -> AIServiceError {
        if let error = error as? AIServiceError {
            return error
        }
        return AIServiceError(code: .serverFailed, detail: error.localizedDescription)
    }
}

extension AnalysisResultPayload {
    var kind: AnalysisKind {
        switch self {
        case .birthday:
            return .birthday
        case .palmFace:
            return .palmFace
        case .auspiciousDate:
            return .auspiciousDate
        }
    }

    var summaryText: String {
        switch self {
        case .birthday(let result):
            return result.summary
        case .palmFace(let result):
            return result.summary
        case .auspiciousDate(let result):
            return result.summary
        }
    }
}
