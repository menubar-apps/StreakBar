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
    @Default(.theme) var theme
    @Default(.borders) var borders
    @Default(.emptyDayTransparency) var emptyDayTransparency
    @Default(.viewMode) var viewMode
    
    @FromKeychain(.githubToken) var githubToken

    @StateObject private var auth = DeviceFlowAuth()
    @State private var method: AuthMethod = DeviceFlowAuth.isConfigured ? .github : .personalToken
    @State private var isConfirmingSignOut = false

    @Environment(\.openURL) var openURL

    private var personalTokenBinding: Binding<String> {
        Binding(
            get: { AuthMethod.of(token: githubToken) == .personalToken ? githubToken : "" },
            set: { githubToken = $0 }
        )
    }

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
                if !githubToken.isEmpty {
                    LabeledContent(AuthMethod.of(token: githubToken) == .github ? "Signed in with GitHub" : "Using a personal access token") {
                        HStack(spacing: 8) {
                            Button(action: {
                                appDelegate.redrawBarItem()
                            }) {
                                Image(systemName: "arrow.triangle.2.circlepath")
                            }
                            .buttonStyle(.borderless)
                            .help("Refresh contributions")
                            .accessibilityLabel("Refresh contributions")
                            if AuthMethod.of(token: githubToken) == .github, let manageAccessUrl = DeviceFlowAuth.manageAccessUrl {
                                Link("Manage Access", destination: manageAccessUrl)
                                    .font(.footnote)
                            }
                            Button("Sign Out") {
                                if AuthMethod.of(token: githubToken) == .personalToken {
                                    isConfirmingSignOut = true
                                } else {
                                    signOut()
                                }
                            }
                        }
                    }
                }

                Picker("Sign in with", selection: $method) {
                    Text("GitHub account")
                        .tag(AuthMethod.github)
                        .disabled(!DeviceFlowAuth.isConfigured)
                    Text("Personal access token")
                        .tag(AuthMethod.personalToken)
                }
                .pickerStyle(.radioGroup)

                if method == .github {
                    signInSection
                } else {
                    HStack(spacing: 8) {
                        SecureField("GitHub token", text: personalTokenBinding)
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
                }
            } header: {
                Text("Account")
            } footer: {
                VStack(alignment: .leading, spacing: 6) {
                    if method == .github {
                        Text("StreakBar asks for the **read:user** permission to read your contributions.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Your token must have the **read:user** or **user** scope to display the repository chart.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
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
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
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
        .confirmationDialog("Remove the saved token?", isPresented: $isConfirmingSignOut) {
            Button("Remove Token", role: .destructive) { signOut() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("StreakBar will stop loading your contributions.")
        }
        .onAppear {
            method = AuthMethod.of(token: githubToken) ?? (DeviceFlowAuth.isConfigured ? .github : .personalToken)
        }
        .onChange(of: auth.state) { state in
            if state == .signedIn {
                appDelegate.redrawBarItem()
            }
        }
        .onDisappear { auth.cancel() }
    }

    @ViewBuilder
    private var signInSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            switch auth.state {
            case .requestingCode:
                ProgressView().controlSize(.small)
            case .waitingForUser(let userCode, let verificationUri):
                HStack {
                    Text(userCode)
                        .font(.system(.title3, design: .monospaced).bold())
                        .textSelection(.enabled)
                        .accessibilityLabel("Sign-in code \(userCode)")
                    Button("Copy Code and Open GitHub") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(userCode, forType: .string)
                        NSWorkspace.shared.open(verificationUri)
                    }
                }
                HStack(spacing: 6) {
                    ProgressView().controlSize(.small)
                    Text("Waiting for approval on GitHub…")
                        .foregroundStyle(.secondary)
                    Button("Cancel") { auth.cancel() }
                        .buttonStyle(.link)
                }
                .font(.footnote)
            case .idle, .signedIn, .expired, .denied, .failed:
                if AuthMethod.of(token: githubToken) == .github {
                    Text("To use a different account, sign out first.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    Button("Sign in with GitHub") { auth.start() }
                    if let message = message(for: auth.state) {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private func message(for state: DeviceFlowAuth.State) -> String? {
        switch state {
        case .expired: return "The code expired. Please try again."
        case .denied: return "Sign-in was cancelled on GitHub."
        case .failed(let message): return "Sign-in failed: \(message)"
        default: return nil
        }
    }

    private func signOut() {
        auth.cancel()
        githubToken = ""
        Defaults[.githubUsername] = ""
        appDelegate.redrawBarItem()
    }
}

//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}
