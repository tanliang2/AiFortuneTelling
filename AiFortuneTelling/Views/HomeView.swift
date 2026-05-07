//
//  HomeView.swift
//  AiFortuneTelling
//

import SwiftUI

struct HomeView: View {
    @Binding var path: [AppRoute]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("AI 命理")
                        .font(.largeTitle.bold())
                    Text("生日命理、掌纹面相与黄道吉日均由服务端大模型生成，客户端负责采集、展示和历史管理。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 12) {
                    FeatureCard(title: "生日命理", subtitle: "输入生日、时间和地区，生成结构化命理解读。", icon: AnalysisKind.birthday.iconName) {
                        path.append(.birthday)
                    }
                    FeatureCard(title: "掌纹面相", subtitle: "拍摄或导入掌纹与面部照片，上传前可预览确认。", icon: AnalysisKind.palmFace.iconName) {
                        path.append(.palmFace)
                    }
                    FeatureCard(title: "黄道吉日", subtitle: "选择事项与候选日期范围，获得主推荐和备选日期。", icon: AnalysisKind.auspiciousDate.iconName) {
                        path.append(.auspiciousDate)
                    }
                }

                HStack(spacing: 12) {
                    Button {
                        path.append(.history)
                    } label: {
                        Label("历史记录", systemImage: "clock.arrow.circlepath")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    Button {
                        path.append(.settings)
                    } label: {
                        Label("设置", systemImage: "gearshape")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
        }
        .navigationTitle("首页")
    }
}
