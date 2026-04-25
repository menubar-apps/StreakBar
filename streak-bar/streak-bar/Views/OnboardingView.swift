//
//  OnboardingView.swift
//  streak-bar
//
//  Created for HIG improvements
//

import SwiftUI
import Defaults

struct OnboardingView: View {
    @Binding var isPresented: Bool
    var onComplete: (() -> Void)? = nil
    @State private var currentPage = 0
    @Default(.githubUsername) var githubUsername
    @Default(.theme) var selectedTheme
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    let totalPages = 3
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress indicators
            HStack(spacing: 8) {
                ForEach(0..<totalPages, id: \.self) { index in
                    Capsule()
                        .fill(index == currentPage ? Color.accentColor : Color.secondary.opacity(0.3))
                        .frame(width: index == currentPage ? 32 : 8, height: 4)
                        .animation(reduceMotion ? nil : .spring(response: 0.3), value: currentPage)
                }
            }
            .padding(.top, 20)
            .padding(.bottom, 24)
            
            // Page content
            TabView(selection: $currentPage) {
                welcomePage.tag(0)
                setupPage.tag(1)
                customizePage.tag(2)
            }
            .tabViewStyle(.automatic)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Navigation buttons
            HStack {
                if currentPage > 0 {
                    Button("Back") {
                        withAnimation(reduceMotion ? nil : .easeInOut) {
                            currentPage -= 1
                        }
                    }
                    .keyboardShortcut(.cancelAction)
                }
                
                Spacer()
                
                if currentPage < totalPages - 1 {
                    Button("Continue") {
                        withAnimation(reduceMotion ? nil : .easeInOut) {
                            currentPage += 1
                        }
                    }
                    .keyboardShortcut(.defaultAction)
                } else {
                    Button("Get Started") {
                        completeOnboarding()
                    }
                    .keyboardShortcut(.defaultAction)
                }
            }
            .padding(20)
        }
        .frame(width: 500, height: 450)
    }
    
    private var welcomePage: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(nsImage: NSImage(named: "AppIcon")!)
                .resizable()
                .frame(width: 120, height: 120)
            
            VStack(spacing: 8) {
                Text("Welcome to StreakBar")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Keep your GitHub contributions visible in your menu bar")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 350)
            }
            
            Spacer()
        }
        .padding()
    }
    
    private var setupPage: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "person.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.blue)
            
            VStack(spacing: 16) {
                Text("Enter Your GitHub Username")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("We'll fetch your contribution history and display it in the menu bar")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 350)
                
                TextField("GitHub username", text: $githubUsername)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 250)
                    .font(.title3)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .padding()
    }
    
    private var customizePage: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "paintpalette.fill")
                .font(.system(size: 60))
                .foregroundStyle(.purple)
            
            VStack(spacing: 12) {
                Text("Customize Your Experience")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Choose from multiple themes")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 350)
            }
            
            // Interactive theme selector (2x3 grid)
            VStack(spacing: 8) {
                // First row
                HStack(spacing: 8) {
                    ForEach(Array(Theme.themes.keys.sorted().prefix(3)), id: \.self) { themeName in
                        Button(action: {
                            selectedTheme = themeName
                        }) {
                            VStack(spacing: 3) {
                                HStack(spacing: 2) {
                                    ForEach([ContributionLevel.FIRST_QUARTILE, .SECOND_QUARTILE, .THIRD_QUARTILE, .FOURTH_QUARTILE], id: \.self) { level in
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(Theme.themes[themeName]![level]!)
                                            .frame(width: 12, height: 12)
                                    }
                                }
                                .padding(6)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(selectedTheme == themeName ? Color.accentColor.opacity(0.2) : Color.clear)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(selectedTheme == themeName ? Color.accentColor : Color.clear, lineWidth: 2)
                                )
                                Text(themeName)
                                    .font(.caption2)
                                    .foregroundStyle(selectedTheme == themeName ? .primary : .secondary)
                                    .fontWeight(selectedTheme == themeName ? .semibold : .regular)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(themeName) theme")
                        .accessibilityAddTraits(selectedTheme == themeName ? [.isSelected] : [])
                    }
                }
                
                // Second row
                HStack(spacing: 8) {
                    ForEach(Array(Theme.themes.keys.sorted().dropFirst(3)), id: \.self) { themeName in
                        Button(action: {
                            selectedTheme = themeName
                        }) {
                            VStack(spacing: 3) {
                                HStack(spacing: 2) {
                                    ForEach([ContributionLevel.FIRST_QUARTILE, .SECOND_QUARTILE, .THIRD_QUARTILE, .FOURTH_QUARTILE], id: \.self) { level in
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(Theme.themes[themeName]![level]!)
                                            .frame(width: 12, height: 12)
                                    }
                                }
                                .padding(6)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(selectedTheme == themeName ? Color.accentColor.opacity(0.2) : Color.clear)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(selectedTheme == themeName ? Color.accentColor : Color.clear, lineWidth: 2)
                                )
                                Text(themeName)
                                    .font(.caption2)
                                    .foregroundStyle(selectedTheme == themeName ? .primary : .secondary)
                                    .fontWeight(selectedTheme == themeName ? .semibold : .regular)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(themeName) theme")
                        .accessibilityAddTraits(selectedTheme == themeName ? [.isSelected] : [])
                    }
                }
            }
            
            Spacer()
        }
        .padding()
    }
    
    private func completeOnboarding() {
        isPresented = false
        onComplete?()
    }
}
