//
//  ContentView.swift
//  streak-bar
//
//  Created by Pavel Makhov on 2023-09-03.
//

import SwiftUI
import Defaults

struct ContentView: View {

    enum Tab: String, CaseIterable, Identifiable {
        case contributions = "Contributions"
        case settings = "Settings"

        var id: Self { self }
    }

    var appDelegate: AppDelegate
    @Default(.hasCompletedOnboarding) var hasCompletedOnboarding
    @State private var showOnboarding = false
    @State private var selectedTab: Tab = .contributions

    private var isShowingSettings: Binding<Bool> {
        Binding(
            get: { selectedTab == .settings },
            set: { selectedTab = $0 ? .settings : .contributions }
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Picker("", selection: $selectedTab) {
                    ForEach(Tab.allCases) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .fixedSize()

                HStack {
                    Spacer()
                    Menu {
                        Button("About StreakBar") {
                            appDelegate.openAboutWindow()
                        }
                        Divider()
                        Button("Quit StreakBar") {
                            NSApplication.shared.terminate(nil)
                        }
                        .keyboardShortcut("q", modifiers: .command)
                    } label: {
                        Image(systemName: "line.3.horizontal")
                    }
                    .menuStyle(.borderlessButton)
                    .menuIndicator(.hidden)
                    .fixedSize()
                    .help("More")
                    .accessibilityLabel("More")
                }
                .padding(.horizontal, 16)
            }
            .padding(.top, 12)
            .padding(.bottom, 4)

            switch selectedTab {
            case .contributions:
                CommitsChartView(viewModel: appDelegate.viewModel, appDelegate: appDelegate, isShowingSettings: isShowingSettings)
            case .settings:
                SettingsView(appDelegate: appDelegate)
            }
        }
        .frame(minWidth: 400, minHeight: 600)
        .onAppear {
            // Check if we need to show onboarding
            if !hasCompletedOnboarding {
                showOnboarding = true
            }
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingView(isPresented: $showOnboarding) {
                // Mark complete and show Settings so user can sign in
                hasCompletedOnboarding = true
                appDelegate.refreshContributions()
                selectedTab = .settings
            }
        }
        .onChange(of: showOnboarding) { newValue in
            // Only treat an Escape-dismiss (sheet closed without completing)
            // as needing a refresh — onComplete handles the normal completion path.
            if !newValue && !hasCompletedOnboarding {
                hasCompletedOnboarding = true
                appDelegate.refreshContributions()
            }
        }
    }
}


//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView(appDelegate: AppDelegate())
//    }
//}
