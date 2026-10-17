//
//  AppPromotionView.swift
//  streak-bar
//

import SwiftUI

struct MyApp: Identifiable {
    let id = UUID()
    let name: String
    let iconName: String
    let appStoreURL: String
}

struct AppPromotionView: View {
    let apps: [MyApp] = [
        MyApp(name: "ToDoBar",
              iconName: "todobar",
              appStoreURL: "https://apps.apple.com/app/id1641624925"),
        MyApp(name: "GojiBar",
              iconName: "gojibar",
              appStoreURL: "https://apps.apple.com/app/id6471348025"),
        MyApp(name: "PullBar Pro",
              iconName: "pullbarpro",
              appStoreURL: "https://apps.apple.com/app/id6462591649"),
        MyApp(name: "Swifty Stats",
              iconName: "swiftystats",
              appStoreURL: "https://apps.apple.com/app/id6482977831"),
    ]

    var body: some View {
        VStack(spacing: 8) {
            Text("More apps")
                .font(.headline)

            HStack {
                ForEach(apps) { app in
                    AppView(app: app)
                }
            }
        }
    }
}

struct AppView: View {
    @Environment(\.openURL) var openURL

    let app: MyApp
    @State private var isHovered = false

    var body: some View {
        VStack(spacing: 0) {
            Image(app.iconName)
                .resizable()
                .frame(width: 64, height: 64)

            Text(app.name)
                .font(.caption)
        }
        .padding(8)
        .background(isHovered ? Color.gray.opacity(0.1) : Color.clear)
        .cornerRadius(8)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .onTapGesture {
            openURL(URL(string: app.appStoreURL)!)
        }
        .help("Open \(app.name) in the App Store")
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(app.name)
        .accessibilityAddTraits(.isLink)
    }
}

#Preview {
    AppPromotionView()
}
