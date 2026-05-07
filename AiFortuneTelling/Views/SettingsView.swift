//
//  SettingsView.swift
//  AiFortuneTelling
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: FortuneAppState
    @Binding var path: [AppRoute]
    @State private var showClearConfirm = false

    var body: some View {
        List {
            Section("服务") {
                LabeledContent("当前模式", value: "Mock 服务")
                Text("真实服务端域名、鉴权和图片上传协议确定后，可替换 `NetworkAIAnalysisService`。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("隐私") {
                Text("生日、掌纹、面相图片属于敏感信息。采集前会展示用途说明，成功结果只保存本地摘要和任务引用。")
                Button(role: .destructive) {
                    showClearConfirm = true
                } label: {
                    Label("清空全部历史", systemImage: "trash")
                }
                .disabled(appState.historyStore.records.isEmpty)
            }

            Section("免责声明") {
                Text("本应用内容由服务端大模型生成，仅供娱乐参考，不构成医学、法律、金融或投资建议。")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("设置")
        .alert("清空全部历史？", isPresented: $showClearConfirm) {
            Button("取消", role: .cancel) {}
            Button("清空", role: .destructive) {
                Task {
                    await appState.clearHistory()
                }
            }
        } message: {
            Text("本机历史会被删除，并会请求服务端删除关联任务数据。")
        }
    }
}
