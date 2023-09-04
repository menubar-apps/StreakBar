//
//  AboutView.swift
//  streak-bar
//
//  Created by Pavel Makhov on 2023-09-03.
//

import SwiftUI

struct AboutView: View {
    @Environment(\.openURL) var openURL
    
    let currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    
    var body: some View {
        VStack {
            Image(nsImage: NSImage(named: "AppIcon")!)
                .frame(height: 130)
            Text("Streak Bar").font(.title)
            Text("by Pavel Makhov").font(.caption)
            Text("version " + currentVersion).font(.footnote)
            Divider()
            
            Button(action: {
                openURL(URL(string:"https://github.com/menubar-apps/StreakBar/issues/new?assignees=&labels=&projects=&template=feature_request.md&title=")!)
            }) {
                HStack {
                    Image(systemName: "star.fill")
                    Text("Request a Feature")
                }
            }
            Button(action: {
                openURL(URL(string:"https://github.com/menubar-apps/StreakBar/issues/new?assignees=&labels=&projects=&template=bug_report.md&title=")!)
            }) {
                HStack {
                    Image(systemName: "ladybug.fill")
                    Text("Report a Bug")
                }
            }
            Button(action: {
                openURL(URL(string: "https://www.buymeacoffee.com/streetturtle")!)
            }) {
                HStack {
                    Image(systemName: "cup.and.saucer.fill")
                    Text("Buy Me Coffee")
                }
            }
        }
        .padding()
//        .frame(minHeight: 400)
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
    }
}
