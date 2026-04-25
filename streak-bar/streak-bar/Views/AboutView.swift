//
//  AboutView.swift
//  streak-bar
//
//  Created by Pavel Makhov on 2023-09-03.
//

import SwiftUI

struct AboutView: View {
    @Environment(\.openURL) var openURL
    
    let currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
    var currentYear: Int { Calendar.current.component(.year, from: Date()) }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // App Icon and Info
                VStack(spacing: 12) {
                    Image(nsImage: NSImage(named: "AppIcon")!)
                        .resizable()
                        .frame(width: 96, height: 96)
                        .accessibilityHidden(true)
                    
                    VStack(spacing: 4) {
                        Text("StreakBar")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Version \(currentVersion)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Text("Shows your GitHub contribution chart in the menu bar")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.top, 20)
                
                Divider()
                    .padding(.horizontal, 40)
                
                // Links Section
                GroupBox {
                    VStack(spacing: 16) {
                        Link(destination: URL(string:"https://github.com/menubar-apps/StreakBar/issues/new?assignees=&labels=&projects=&template=feature_request.md&title=")!) {
                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(.yellow)
                                    .frame(width: 20)
                                Text("Request a Feature")
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                        .help("Open GitHub to request a new feature")
                        .accessibilityLabel("Request a feature on GitHub")
                        
                        Divider()
                        
                        Link(destination: URL(string:"https://github.com/menubar-apps/StreakBar/issues/new?assignees=&labels=&projects=&template=bug_report.md&title=")!) {
                            HStack {
                                Image(systemName: "ladybug.fill")
                                    .foregroundStyle(.red)
                                    .frame(width: 20)
                                Text("Report a Bug")
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                        .help("Open GitHub to report a bug")
                        .accessibilityLabel("Report a bug on GitHub")
                        
                        Divider()
                        
                        Link(destination: URL(string: "https://github.com/menubar-apps/StreakBar")!) {
                            HStack {
                                Image(systemName: "chevron.left.forwardslash.chevron.right")
                                    .frame(width: 20)
                                Text("View Source Code")
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                        .help("View the source code on GitHub")
                        .accessibilityLabel("View source code on GitHub")
                    }
                    .padding(8)
                }
                .padding(.horizontal, 40)
                
                // Buy Me a Coffee
                Link(destination: URL(string: "https://buymeacoffee.com/streetturtle")!) {
                    HStack(spacing: 8) {
                        Text("☕")
                        Text("Buy me a coffee")
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color(red: 1.0, green: 0.81, blue: 0.27))
                    .foregroundStyle(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 40)
                .help("Support StreakBar development")
                .accessibilityLabel("Buy me a coffee to support development")
                
                // Credits
                VStack(spacing: 4) {
                    Text("Created by Pavel Makhov")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("© 2023-\(String(currentYear)) StreakBar")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .padding(.bottom, 20)
            }
        }
        .frame(minWidth: 400, minHeight: 500)
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
    }
}
