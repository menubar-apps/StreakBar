//
//  ContentView.swift
//  streak-bar
//
//  Created by Pavel Makhov on 2023-09-03.
//

import SwiftUI

struct ContentView: View {
    
    var appDelegate: AppDelegate
    @State private var favoriteColor = 0
    
    var body: some View {
        
        VStack(spacing: 10) {
            Picker("", selection: $favoriteColor) {
                Text("Settings").tag(0)
                Text("About").tag(1)
            }
            .pickerStyle(.segmented)
            .frame(width: 150)
            .border(.red)
            
            if favoriteColor == 0 {
                SettingsView(appDelegate: appDelegate)
            } else {
                AboutView()
            }
        }
        .border(.red)
    }
}

//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView(appDelegate: AppDelegate())
//    }
//}
