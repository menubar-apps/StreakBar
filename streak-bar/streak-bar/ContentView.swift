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
    @FromKeychain(.githubToken) var githubToken

    var body: some View {
        
        HStack(alignment: .center) {
            Text("Token:").frame(width: 120, alignment: .trailing)
            VStack(alignment: .leading) {
                HStack() {
                    SecureField("", text: $githubToken)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
//                        .overlay(
//                            Image(systemName: tokenValidator.iconName).foregroundColor(tokenValidator.iconColor)
//                                .frame(maxWidth: .infinity, alignment: .trailing)
//                                .padding(.trailing, 8)
//                        )
                        .frame(width: 380)
//                        .onChange(of: githubToken) { _ in
//                            tokenValidator.validate()
//                        }
                    Button {
//                        tokenValidator.validate()
                    } label: {
                        Image(systemName: "repeat")
                    }
                    .help("Retry")
                }
                Text("[Generate](https://github.com/settings/tokens/new?scopes=repo) a personal access token, make sure to select **repo** scope")
                    .font(.footnote)
                    .padding(.leading, 8)
                    .foregroundColor(.secondary)
            }
        }
        
        HStack(alignment: .center) {
            Text("Days before:").frame(width: 120, alignment: .trailing)
            TextField("", value: $daysBefore, format: .number)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .disableAutocorrection(true)
                .textContentType(.password)
                .frame(width: 200)
            
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
