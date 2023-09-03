//
//  ContentView.swift
//  streak-bar
//
//  Created by Pavel Makhov on 2023-08-31.
//

import SwiftUI
import Defaults

struct ContentView: View {
    
    @Default(.daysBefore) var daysBefore
    @Default(.githubUsername) var githubUsername
    @Default(.theme) var theme
    @Default(.borders) var borders
    @Default(.transparency) var transparency
    
    @FromKeychain(.githubToken) var githubToken
    
    var body: some View {
        VStack (alignment: .leading){
            HStack(alignment: .center) {
                Text("Username:").frame(width: 100, alignment: .trailing)
                TextField("", text: $githubUsername)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disableAutocorrection(true)
                    .textContentType(.password)
                    .frame(width: 200)
            }
            
            HStack(alignment: .center) {
                Text("Days before:").frame(width: 100, alignment: .trailing)
                TextField("", value: $daysBefore, format: .number)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disableAutocorrection(true)
                    .textContentType(.password)
                    .frame(width: 200)
            }
            
            HStack(alignment: .center) {
                Text("Theme:").frame(width: 100, alignment: .trailing)
                VStack(alignment: .leading) {
                    Picker("", selection: $theme, content: {
                        ForEach(Theme.themes.keys.sorted(by: <), id:\.self) {key in
                            HStack(spacing: 2) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Theme.themes[key]![.NONE]!)
                                    .frame(width: 10, height: 10)
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Theme.themes[key]![.FIRST_QUARTILE]!)
                                    .frame(width: 10, height: 10)
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Theme.themes[key]![.SECOND_QUARTILE]!)
                                    .frame(width: 10, height: 10)
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Theme.themes[key]![.THIRD_QUARTILE]!)
                                    .frame(width: 10, height: 10)
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Theme.themes[key]![.FOURTH_QUARTILE]!)
                                    .frame(width: 10, height: 10)
                                Text(" " + key)
                            }
                        }
                    }).pickerStyle(.radioGroup)
                }
            }
            
            HStack(alignment: .center) {
                Text("Borders:").frame(width: 100, alignment: .trailing)
                Toggle("", isOn: $borders)
                    .toggleStyle(.switch)
            }
            
            HStack(alignment: .center) {
                Text("Transparency:").frame(width: 100, alignment: .trailing)
                Toggle("", isOn: !$transparency)
                    .toggleStyle(.switch)
            }

            
            HStack(alignment: .center) {
                Text("Token:").frame(width: 100, alignment: .trailing)
                VStack(alignment: .leading) {
                        SecureField("", text: $githubToken)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 200)
                    Text("[Generate](https://github.com/settings/tokens/new?scopes=repo) a personal access token, make sure to select **repo** scope")
                        .font(.footnote)
                        .padding(.leading, 8)
                        .foregroundColor(.secondary)
                        .frame(width: 200)
                }
            }
            
        }.padding(20)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
