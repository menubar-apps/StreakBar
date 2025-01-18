//
//  ContentView.swift
//  streak-bar
//
//  Created by Pavel Makhov on 2023-09-03.
//

import SwiftUI
import LaunchAtLogin

struct ContentView: View {
    
    var appDelegate: AppDelegate
    @State private var selectedTab = 0
    
    var body: some View {
        
        VStack(spacing: 10) {
            ZStack {
                Picker("", selection: $selectedTab) {
                    Text("Streaks").tag(0)
                    Text("Settings").tag(1)
                    Text("About").tag(2)
                }
                .pickerStyle(.segmented)
                .frame(width: 150)
                
                HStack {
                    Spacer()
                    Menu {
                        LaunchAtLogin.Toggle()

                        Button(action: {
                            appDelegate.quit()
                        }) {
                            Image(systemName: "power")
                            Text("Quit")
                        }
                    } label: {
                        HoverableLabel(iconName: "line.3.horizontal")
                            .foregroundColor(.secondary)
                    }
                    .menuStyle(.borderlessButton)
                    .frame(width: 20, height: 16)
                    .padding(8)
                    .padding(.trailing, 2)
                    .focusable(false)
                    .menuIndicator(.hidden)
                    .contentShape(Rectangle())
                }
            }
            
            if selectedTab == 0 {
                StatusItemView(viewModel: appDelegate.viewModel, isFullSize: true)
                    .padding()
            } else if selectedTab == 1 {
                SettingsView(appDelegate: appDelegate)
            } else if selectedTab == 2 {
                AboutView()
            }
        }
        .padding(.top, 16)
        .frame(alignment: .top)
    }
}

//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView(appDelegate: AppDelegate())
//    }
//}
