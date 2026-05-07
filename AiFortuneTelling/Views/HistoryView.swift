//
//  HistoryView.swift
//  AiFortuneTelling
//

import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var appState: FortuneAppState
    @Binding var path: [AppRoute]

    @State private var selectedKind: AnalysisKind?
    @State private var showClearConfirm = false

    private var filteredRecords: [HistoryRecord] {
        guard let selectedKind else { return appState.historyStore.records }
        return appState.historyStore.records.filter { $0.kind == selectedKind }
    }

    var body: some View {
        VStack {
            Picker("类型", selection: $selectedKind) {
                Text("全部").tag(AnalysisKind?.none)
                ForEach(AnalysisKind.allCases) { kind in
                    Text(kind.title).tag(AnalysisKind?.some(kind))
                }
            }
            .pickerStyle(.segmented)
            .padding([.horizontal, .top])

            if filteredRecords.isEmpty {
                EmptyStateView(title: "暂无历史", message: "完成一次分析后会在这里保存摘要和结果引用。", icon: "clock")
                    .padding()
            } else {
                List {
                    ForEach(filteredRecords) { record in
                        Button {
                            path.append(.historyDetail(record.id))
                        } label: {
                            HistoryRow(record: record)
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                Task {
                                    await appState.deleteHistory(record)
                                }
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("历史记录")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    showClearConfirm = true
                } label: {
                    Image(systemName: "trash")
                }
                .disabled(appState.historyStore.records.isEmpty)
            }
        }
        .alert("清空全部历史？", isPresented: $showClearConfirm) {
            Button("取消", role: .cancel) {}
            Button("清空", role: .destructive) {
                Task {
                    await appState.clearHistory()
                }
            }
        } message: {
            Text("本机历史会被删除，并会批量请求服务端删除关联任务数据。")
        }
    }
}

private struct HistoryRow: View {
    let record: HistoryRecord

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: record.kind.iconName)
                .frame(width: 34, height: 34)
                .background(.purple.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(record.kind.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(record.resultSummary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(record.createdAt.formatted(date: .numeric, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

struct HistoryDetailView: View {
    @EnvironmentObject private var appState: FortuneAppState
    let recordID: UUID
    @Binding var path: [AppRoute]

    var body: some View {
        ScrollView {
            if let record = appState.historyStore.record(id: recordID) {
                VStack(alignment: .leading, spacing: 16) {
                    ResultCard(title: "输入摘要", icon: record.kind.iconName) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(record.inputSummary)
                            Text(record.createdAt.formatted(date: .long, time: .shortened))
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }

                    switch record.result {
                    case .birthday(let result):
                        BirthdayHistoryContent(result: result)
                    case .palmFace(let result):
                        PalmFaceHistoryContent(result: result)
                    case .auspiciousDate(let result):
                        AuspiciousDateHistoryContent(result: result)
                    }

                    Button(role: .destructive) {
                        Task {
                            await appState.deleteHistory(record)
                            await MainActor.run {
                                _ = path.popLast()
                            }
                        }
                    } label: {
                        Label("删除该记录", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            } else {
                EmptyStateView(title: "记录不存在", message: "该历史记录可能已经被删除。", icon: "questionmark.folder")
                    .padding()
            }
        }
        .navigationTitle("历史详情")
    }
}

private struct BirthdayHistoryContent: View {
    let result: BirthdayFortuneResult

    var body: some View {
        VStack(spacing: 12) {
            ResultCard(title: "命理摘要", icon: "person.text.rectangle") {
                Text("\(result.constellation)，\(result.eightCharacters)，\(result.fiveElements)")
            }
            ResultCard(title: "综合解读", icon: "text.alignleft") {
                Text([result.personality, result.career, result.relationship, result.health].joined(separator: "\n\n"))
            }
            DisclosureBanner(title: "声明", message: result.disclaimer)
        }
    }
}

private struct PalmFaceHistoryContent: View {
    let result: PalmFaceReadingResult

    var body: some View {
        VStack(spacing: 12) {
            ResultCard(title: "掌纹面相摘要", icon: "camera.viewfinder") {
                Text((result.palmFeatures + result.faceFeatures).joined(separator: "\n"))
            }
            ResultCard(title: "建议", icon: "lightbulb") {
                Text(result.advice)
            }
            DisclosureBanner(title: "声明", message: result.disclaimer)
        }
    }
}

private struct AuspiciousDateHistoryContent: View {
    let result: AuspiciousDateResult

    var body: some View {
        VStack(spacing: 12) {
            if let primary = result.primary {
                ResultCard(title: "首选日期", icon: "calendar") {
                    Text("\(primary.date.formatted(date: .long, time: .omitted))\n\(primary.reason)")
                }
            }
            DisclosureBanner(title: "声明", message: result.disclaimer)
        }
    }
}
