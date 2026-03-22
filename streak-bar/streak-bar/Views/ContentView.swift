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
                OnboardingView(isPresented: $showOnboarding)
            }
            .onChange(of: showOnboarding) { newValue in
                if !newValue && !hasCompletedOnboarding {
                    // Mark onboarding as completed when dismissed
                    hasCompletedOnboarding = true
                    // Trigger initial data fetch
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
