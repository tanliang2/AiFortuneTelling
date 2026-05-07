//
//  BirthdayFortuneView.swift
//  AiFortuneTelling
//

import SwiftUI

struct BirthdayFortuneView: View {
    @EnvironmentObject private var appState: FortuneAppState
    @Binding var path: [AppRoute]

    @State private var name = ""
    @State private var gender = "未透露"
    @State private var birthday = Calendar.current.date(byAdding: .year, value: -28, to: Date()) ?? Date()
    @State private var birthTime = Date()
    @State private var region = ""
    @State private var validationMessage: String?
    @State private var isSubmitting = false
    @State private var currentTaskID: String?

    private let genders = ["未透露", "女性", "男性", "其他"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                DisclosureBanner(
                    title: "生日资料用途",
                    message: "生日、出生时间和地区仅用于提交本次服务端命理分析，并会随历史记录保存在本机。结果仅供娱乐参考。"
                )

                VStack(spacing: 14) {
                    TextField("姓名或昵称（可选）", text: $name)
                        .textFieldStyle(.roundedBorder)

                    Picker("性别", selection: $gender) {
                        ForEach(genders, id: \.self) { gender in
                            Text(gender).tag(gender)
                        }
                    }
                    .pickerStyle(.segmented)

                    DatePicker("公历生日", selection: $birthday, displayedComponents: .date)
                    DatePicker("出生时间", selection: $birthTime, displayedComponents: .hourAndMinute)
                    TextField("出生地区，例如：杭州", text: $region)
                        .textFieldStyle(.roundedBorder)
                }
                .formSectionStyle()

                if let validationMessage {
                    ErrorBanner(message: validationMessage)
                }
                if let error = appState.latestError {
                    ErrorBanner(message: error.localizedDescription)
                }
                if isSubmitting {
                    LoadingOverlay(title: "正在生成生日命理", task: currentTaskID.flatMap { appState.taskStates[$0] })
                }

                PrimaryActionButton(title: "生成生日命理", icon: "sparkles", isLoading: isSubmitting) {
                    submit()
                }
            }
            .padding()
        }
        .navigationTitle("生日命理")
    }

    private func submit() {
        let trimmedRegion = region.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedRegion.isEmpty else {
            validationMessage = "请填写出生地区"
            return
        }
        validationMessage = nil
        isSubmitting = true
        Task {
            let request = BirthdayFortuneRequest(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                gender: gender,
                birthday: birthday,
                birthTime: birthTime,
                region: trimmedRegion
            )
            let taskID = await appState.submitBirthday(request)
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
