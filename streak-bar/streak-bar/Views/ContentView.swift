//
//  ContentView.swift
//  streak-bar
//
//  Created by Pavel Makhov on 2023-09-03.
//

import SwiftUI
import Defaults

struct ContentView: View {
    
    var appDelegate: AppDelegate
    @Default(.hasCompletedOnboarding) var hasCompletedOnboarding
    @State private var showOnboarding = false
    
    var body: some View {
        CommitsChartView(viewModel: appDelegate.viewModel, appDelegate: appDelegate)
            .frame(minWidth: 400, minHeight: 600)
            .onAppear {
                // Check if we need to show onboarding
                if !hasCompletedOnboarding {
                    showOnboarding = true
                }
            }
            .sheet(isPresented: $showOnboarding) {
                OnboardingView(isPresented: $showOnboarding) {
                    // Mark complete and open Settings so user can enter their token
                    hasCompletedOnboarding = true
                    appDelegate.redrawBarItem()
                    appDelegate.openSettingsWindow()
                }
            }
            .onChange(of: showOnboarding) { newValue in
                // Only treat an Escape-dismiss (sheet closed without completing)
                // as needing a redraw — onComplete handles the normal completion path.
                if !newValue && !hasCompletedOnboarding {
                    hasCompletedOnboarding = true
                    appDelegate.redrawBarItem()
                }
            }
    }
}


//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView(appDelegate: AppDelegate())
//    }
//}
