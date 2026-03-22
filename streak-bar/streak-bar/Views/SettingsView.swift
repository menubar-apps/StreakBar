//
//  SettingsView.swift
//  streak-bar
//
//  Created by Pavel Makhov on 2023-08-31.
//

import SwiftUI
import Defaults
import LaunchAtLogin

struct SettingsView: View {
    
    var appDelegate: AppDelegate
    
    @Default(.daysBefore) var daysBefore
    @Default(.githubUsername) var githubUsername
    @Default(.theme) var theme
    @Default(.borders) var borders
    @Default(.emptyDayTransparency) var emptyDayTransparency
    @Default(.viewMode) var viewMode
    
    @FromKeychain(.githubToken) var githubToken
    
    @Environment(\.openURL) var openURL
    
    var body: some View {
        Form {
            Section {
                LaunchAtLogin.Toggle {
                    Text("Launch at Login")
                }
            } header: {
                Text("General")
            }
            
            Section {
                HStack(spacing: 8) {
                    TextField("GitHub username", text: $githubUsername)
                        .textFieldStyle(.roundedBorder)
                        .disableAutocorrection(true)
                        .help("Your GitHub username")
                        .accessibilityLabel("GitHub username")
                    
                    Button(action: {
                        appDelegate.redrawBarItem()
                    }) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                    }
                    .buttonStyle(.borderless)
                    .help("Refresh contributions")
                    .accessibilityLabel("Refresh contributions")
                }
                
                HStack(spacing: 8) {
                    SecureField("GitHub token", text: $githubToken)
                        .textFieldStyle(.roundedBorder)
                        .help("Personal access token with read:user scope")
                        .accessibilityLabel("GitHub personal access token")
                    
                    Button(action: {
                        openURL(URL(string: "https://github.com/settings/tokens/new")!)
                    }) {
                        Image(systemName: "arrow.up.right.square")
                    }
                    .buttonStyle(.borderless)
                    .help("Generate new token on GitHub")
                    .accessibilityLabel("Open GitHub to generate token")
                }
            } header: {
                Text("Account")
            } footer: {
                VStack(alignment: .leading, spacing: 6) {
                    Text("A personal access token is required to view your GitHub contributions.")
                        .font(.caption)
                    
                    Text("Your token must have the **read:user** or **user** scope to display the repository chart.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Section {
                Picker("View Mode", selection: $viewMode) {
                    ForEach(ViewMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue.capitalized).tag(mode)
                    }
                }
                .pickerStyle(.radioGroup)
                .onChange(of: viewMode) { _ in
                    // Auto-adjust days before when switching modes
                    if viewMode == .week {
                        daysBefore = min(daysBefore, 50)
                        if daysBefore < 10 {
                            daysBefore = 20
                        }
                    } else {
                        daysBefore = min(daysBefore, 10)
                        if daysBefore > 10 {
                            daysBefore = 5
                        }
                    }
                    appDelegate.redrawBarItem()
                }
                .accessibilityLabel("View mode selection")
                
                LabeledContent("\(viewMode.rawValue.capitalized)s to Show") {
                    HStack(spacing: 8) {
                        Button(action: {
                            let step = viewMode == .week ? 5 : 1
                            let minValue = viewMode == .week ? 5 : 1
                            if daysBefore > minValue {
                                daysBefore -= step
                                appDelegate.redrawBarItem()
                            }
                        }) {
                            Image(systemName: "minus")
                                .frame(width: 28, height: 28)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.bordered)
                        .disabled(daysBefore <= (viewMode == .week ? 5 : 1))
                        .help("Decrease")
                        
                        Text("\(daysBefore)")
                            .frame(minWidth: 40)
                            .monospacedDigit()
                            .font(.body)
                        
                        Button(action: {
                            let step = viewMode == .week ? 5 : 1
                            let maxValue = viewMode == .week ? 50 : 10
                            if daysBefore < maxValue {
                                daysBefore += step
                                appDelegate.redrawBarItem()
                            }
                        }) {
                            Image(systemName: "plus")
                                .frame(width: 28, height: 28)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.bordered)
                        .disabled(daysBefore >= (viewMode == .week ? 50 : 10))
                        .help("Increase")
                    }
                    .accessibilityLabel("Number of \(viewMode.rawValue)s to display")
                    .accessibilityValue("\(daysBefore)")
                }
                
                if viewMode == .week {
                    Toggle("Show Borders", isOn: $borders)
                        .onChange(of: borders) { _ in
                            appDelegate.redrawBarItem()
                        }
                        .help("Add spacing between contribution squares")
                        .accessibilityLabel("Show borders between days")
                }
                
                Toggle("Empty Days Transparent", isOn: $emptyDayTransparency)
                    .onChange(of: emptyDayTransparency) { _ in
                        appDelegate.redrawBarItem()
                    }
                    .help("Make days with no contributions more transparent")
                    .accessibilityLabel("Make empty days transparent")
                
            } header: {
                Text("Display")
            }
            
            Section {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 12)], spacing: 12) {
                    ForEach(Theme.themes.keys.sorted(), id: \.self) { themeName in
                        ThemeCardView(
                            themeName: themeName,
                            isSelected: theme == themeName,
                            onTap: {
                                theme = themeName
                                appDelegate.redrawBarItem()
                            }
                        )
                    }
                }
                .padding(.vertical, 8)
            } header: {
                Text("Appearance")
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .frame(minWidth: 400, minHeight: 500)
    }
}

//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}
