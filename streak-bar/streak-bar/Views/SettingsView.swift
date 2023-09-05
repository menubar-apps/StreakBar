//
//  ContentView.swift
//  streak-bar
//
//  Created by Pavel Makhov on 2023-08-31.
//

import SwiftUI
import Defaults

struct SettingsView: View {
    
    var appDelegate: AppDelegate
    
    @Default(.daysBefore) var daysBefore
    @Default(.githubUsername) var githubUsername
    @Default(.theme) var theme
    @Default(.borders) var borders
    @Default(.transparency) var transparency
    @Default(.viewMode) var viewMode
    
    @FromKeychain(.githubToken) var githubToken
    
    @Environment(\.openURL) var openURL
    
    var binding: Binding<String> {
        .init(get: {
            "\(daysBefore)"
        }, set: {
            daysBefore = Int($0) ?? daysBefore
        })
    }
    
    var body: some View {
        VStack (alignment: .leading) {
            HStack(alignment: .center) {
                Text("Username:").frame(width: 90, alignment: .trailing)
                TextField("Github username", text: $githubUsername)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disableAutocorrection(true)
                    .textContentType(.password)
                    .frame(width: 120)
                Button(action: {
                    appDelegate.redrawBarItem()
                },
                       label: {
                    HoverableLabel(iconName: "arrow.triangle.2.circlepath")
                })
                .buttonStyle(.borderless)
                .help("Re-draw")
            }
            
            HStack(alignment: .center) {
                Text("ViewMode:").frame(width: 90, alignment: .trailing)
                VStack(alignment: .leading) {
                    Picker("", selection: $viewMode, content: {
                        ForEach(ViewMode.allCases, id:\.self) { vm in
                            Text(vm.rawValue)
                        }
                    }).pickerStyle(.radioGroup)
                        .onChange(of: viewMode) { _ in
                            if viewMode == .week {
                                daysBefore = 20
                            } else {
                                daysBefore = 5
                            }
                            appDelegate.redrawBarItem()
                        }
                }
            }
            
            HStack(alignment: .center) {
                Text("\(viewMode.rawValue.capitalized)s before:").frame(width: 90, alignment: .trailing)
                                TextField("", value: $daysBefore, format: .number)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .disableAutocorrection(true)
                                    .textContentType(.password)
                                    .frame(width: 40)
                                    .frame(alignment: .center)
                                    .multilineTextAlignment(.trailing)
                                    .focusable(false)
                //                                    .disabled(true)
                
                Stepper("", onIncrement: {
                    if viewMode == .week && daysBefore < 50 {
                        daysBefore += 5
                    } else if viewMode == .day && daysBefore < 10 {
                        daysBefore += 1
                    }
                }, onDecrement: {
                    if viewMode == .week && daysBefore > 0 {
                        daysBefore -= 5
                    } else if viewMode == .day && daysBefore > 0 {
                        daysBefore -= 1
                    }                })
                
                
                //                TextField("", value: $daysBefore, format: .number)
                //                    .textFieldStyle(RoundedBorderTextFieldStyle())
                //                    .disableAutocorrection(true)
                //                    .textContentType(.password)
                //                    .frame(width: 40)
                //                    .frame(alignment: .center)
                //                    .multilineTextAlignment(.trailing)
                
                Button(action: {
                    appDelegate.redrawBarItem()
                },
                       label: {
                    HoverableLabel(iconName: "arrow.triangle.2.circlepath")
                })
                .buttonStyle(.borderless)
                .help("Re-draw")
            }
            
            HStack(alignment: .center) {
                Text("Theme:").frame(width: 90, alignment: .trailing)
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
            
            if viewMode == .week {
                HStack(alignment: .center) {
                    Text("Borders:").frame(width: 90, alignment: .trailing)
                    Toggle("", isOn: $borders)
                        .toggleStyle(.switch)
                }
            }
            
            HStack(alignment: .center) {
                Text("Transparency:").frame(width: 90, alignment: .trailing)
                Toggle("", isOn: !$transparency)
                    .toggleStyle(.switch)
            }
            
            
            HStack(alignment: .center) {
                Text("GitHub Token:").frame(width: 90, alignment: .trailing)
                SecureField("", text: $githubToken)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 120)
                Button(action: {
                    openURL(URL(string: "https://github.com/settings/tokens/new")!)
                    
                },
                       label: {
                    HoverableLabel(iconName: "square.and.arrow.up")
                })
                .buttonStyle(.plain)
                .help("Generate token")
            }
            
        }.padding(20)
            .frame(height: 360, alignment: .top)
    }
    
    var intProxy: Binding<Double>{
        Binding<Double>(get: {
            //returns the score as a Double
            return Double(daysBefore)
        }, set: {
            //rounds the double to an Int
            print($0.description)
            daysBefore = Int($0)
        })
    }
}

//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}
