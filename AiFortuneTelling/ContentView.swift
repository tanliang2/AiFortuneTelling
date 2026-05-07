//
//  ContentView.swift
//  AiFortuneTelling
//
//  Created by ws on 2026/5/7.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var appState = FortuneAppState()
    @State private var path: [AppRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            HomeView(path: $path)
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .birthday:
                        BirthdayFortuneView(path: $path)
                    case .palmFace:
                        PalmFaceReadingView(path: $path)
                    case .auspiciousDate:
                        AuspiciousDateView(path: $path)
                    case .result(let taskID):
                        AnalysisResultView(taskID: taskID, path: $path)
                    case .history:
                        HistoryView(path: $path)
                    case .historyDetail(let recordID):
                        HistoryDetailView(recordID: recordID, path: $path)
                    case .settings:
                        SettingsView(path: $path)
                    }
                }
        }
        .environmentObject(appState)
        .tint(.purple)
    }
}

#Preview {
    ContentView()
}
