//
//  AuspiciousDateView.swift
//  AiFortuneTelling
//

import SwiftUI

struct AuspiciousDateView: View {
    @EnvironmentObject private var appState: FortuneAppState
    @Binding var path: [AppRoute]

    @State private var eventType = "开业"
    @State private var startDate = Date()
    @State private var endDate = Calendar.current.date(byAdding: .day, value: 14, to: Date()) ?? Date()
    @State private var includeBirthday = false
    @State private var birthday = Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date()
    @State private var validationMessage: String?
    @State private var isSubmitting = false
    @State private var currentTaskID: String?

    private let eventTypes = ["开业", "结婚", "搬家", "签约", "出行", "面试"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                DisclosureBanner(
                    title: "吉日选择说明",
                    message: "事项类型、日期范围和可选生日信息会提交给服务端生成结构化推荐，结果不构成重大决策建议。"
                )

                VStack(spacing: 14) {
                    Picker("事项类型", selection: $eventType) {
                        ForEach(eventTypes, id: \.self) { item in
                            Text(item).tag(item)
                        }
                    }

                    DatePicker("开始日期", selection: $startDate, displayedComponents: .date)
                    DatePicker("结束日期", selection: $endDate, displayedComponents: .date)

                    Toggle("结合生日信息", isOn: $includeBirthday)
                    if includeBirthday {
                        DatePicker("生日", selection: $birthday, displayedComponents: .date)
                    }
                }
                .formSectionStyle()

                if let validationMessage {
                    ErrorBanner(message: validationMessage, actionTitle: "扩大到 30 天") {
                        let newEnd = Calendar.current.date(byAdding: .day, value: 30, to: startDate) ?? endDate
                        endDate = newEnd
                        self.validationMessage = nil
                    }
                }
                if let error = appState.latestError {
                    ErrorBanner(message: error.localizedDescription)
                }
                if isSubmitting {
                    LoadingOverlay(title: "正在筛选黄道吉日", task: currentTaskID.flatMap { appState.taskStates[$0] })
                }

                PrimaryActionButton(title: "生成吉日推荐", icon: "sparkles", isLoading: isSubmitting) {
                    submit()
                }
            }
            .padding()
        }
        .navigationTitle("黄道吉日")
    }

    private func submit() {
        guard endDate >= startDate else {
            validationMessage = "结束日期不能早于开始日期"
            return
        }
        let days = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
        guard days <= 90 else {
            validationMessage = "候选范围不能超过 90 天"
            return
        }

        validationMessage = nil
        isSubmitting = true
        Task {
            let request = AuspiciousDateRequest(
                eventType: eventType,
                startDate: startDate,
                endDate: endDate,
                birthday: includeBirthday ? birthday : nil
            )
            let taskID = await appState.submitAuspiciousDate(request)
            await MainActor.run {
                isSubmitting = false
                if let taskID {
                    currentTaskID = taskID
                    path.append(.result(taskID))
                }
            }
        }
    }
}
