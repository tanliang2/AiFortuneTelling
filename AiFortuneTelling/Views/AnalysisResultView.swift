//
//  AnalysisResultView.swift
//  AiFortuneTelling
//

import SwiftUI

struct AnalysisResultView: View {
    @EnvironmentObject private var appState: FortuneAppState
    let taskID: String
    @Binding var path: [AppRoute]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let task = appState.taskStates[taskID] {
                    LoadingOverlay(title: "任务状态", task: task)
                }

                if let result = appState.results[taskID] {
                    switch result {
                    case .birthday(let result):
                        BirthdayResultContent(result: result) {
                            path.append(.birthday)
                        }
                    case .palmFace(let result):
                        PalmFaceResultContent(result: result) {
                            path.append(.palmFace)
                        }
                    case .auspiciousDate(let result):
                        AuspiciousDateResultContent(result: result) {
                            path.append(.auspiciousDate)
                        }
                    }
                } else if let error = appState.latestError {
                    ErrorBanner(message: error.localizedDescription, actionTitle: error.code.isRecoverable ? "重试" : nil) {
                        Task {
                            await appState.retry(taskID: taskID)
                        }
                    }
                } else {
                    EmptyStateView(title: "暂无结果", message: "任务结果还未返回，请稍后刷新。", icon: "hourglass")
                }
            }
            .padding()
        }
        .navigationTitle("分析结果")
    }
}

private struct BirthdayResultContent: View {
    let result: BirthdayFortuneResult
    let regenerateAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ResultCard(title: "基础命盘", icon: "person.text.rectangle") {
                VStack(alignment: .leading, spacing: 6) {
                    Text("星座：\(result.constellation)")
                    Text("生辰八字：\(result.eightCharacters)")
                    Text("五行：\(result.fiveElements)")
                }
            }
            ResultCard(title: "性格", icon: "brain.head.profile") {
                Text(result.personality)
            }
            ResultCard(title: "事业", icon: "briefcase") {
                Text(result.career)
            }
            ResultCard(title: "感情", icon: "heart") {
                Text(result.relationship)
            }
            ResultCard(title: "健康", icon: "cross.case") {
                Text(result.health)
            }
            DisclosureBanner(title: "娱乐参考声明", message: result.disclaimer)
            Button(action: regenerateAction) {
                Label("修改资料重新生成", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

private struct PalmFaceResultContent: View {
    let result: PalmFaceReadingResult
    let regenerateAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ResultCard(title: "掌纹特征", icon: "hand.raised") {
                BulletList(items: result.palmFeatures)
            }
            ResultCard(title: "面相特征", icon: "face.smiling") {
                BulletList(items: result.faceFeatures)
            }
            ResultCard(title: "综合建议", icon: "lightbulb") {
                Text(result.advice)
            }
            DisclosureBanner(title: "敏感风险提示", message: result.riskNotice)
            DisclosureBanner(title: "娱乐参考声明", message: result.disclaimer)
            Button(action: regenerateAction) {
                Label("重新选择图片", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

private struct AuspiciousDateResultContent: View {
    let result: AuspiciousDateResult
    let regenerateAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let primary = result.primary {
                DateRecommendationCard(title: "主推荐", recommendation: primary)
                ForEach(result.alternatives) { item in
                    DateRecommendationCard(title: "备选 \(item.rank)", recommendation: item)
                }
            } else {
                EmptyStateView(
                    title: "暂无合适日期",
                    message: result.noSuitableReason ?? "当前候选范围内没有匹配日期。",
                    icon: "calendar.badge.exclamationmark"
                )
                Button(action: regenerateAction) {
                    Label("扩大范围重新生成", systemImage: "calendar.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            DisclosureBanner(title: "娱乐参考声明", message: result.disclaimer)
        }
    }
}

private struct DateRecommendationCard: View {
    let title: String
    let recommendation: DateRecommendation

    var body: some View {
        ResultCard(title: title, icon: "calendar") {
            VStack(alignment: .leading, spacing: 8) {
                Text(recommendation.date.formatted(date: .long, time: .omitted))
                    .font(.title3.bold())
                LabeledContent("宜") {
                    Text(recommendation.suitable.joined(separator: "、"))
                }
                LabeledContent("忌") {
                    Text(recommendation.avoid.joined(separator: "、"))
                }
                Text(recommendation.reason)
                Text(recommendation.notes)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct BulletList: View {
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Text("•")
                    Text(item)
                }
            }
        }
    }
}
