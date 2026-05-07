//
//  HistoryStore.swift
//  AiFortuneTelling
//

import Combine
import Foundation

@MainActor
final class HistoryStore: ObservableObject {
    @Published private(set) var records: [HistoryRecord] = []

    private let storageKey = "fortune.analysis.history.v1"

    init() {
        load()
    }

    func add(_ record: HistoryRecord) {
        records.insert(record, at: 0)
        save()
    }

    func record(id: UUID) -> HistoryRecord? {
        records.first { $0.id == id }
    }

    func delete(id: UUID) -> HistoryRecord? {
        guard let index = records.firstIndex(where: { $0.id == id }) else { return nil }
        let removed = records.remove(at: index)
        save()
        return removed
    }

    func clearAll() -> [HistoryRecord] {
        let removed = records
        records.removeAll()
        save()
        return removed
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        do {
            records = try JSONDecoder().decode([HistoryRecord].self, from: data)
        } catch {
            records = []
        }
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(records)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            assertionFailure("保存历史记录失败: \(error)")
        }
    }
}
