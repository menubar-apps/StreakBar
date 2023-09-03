//
//  Settings.swift
//  streak-bar
//
//  Created by Pavel Makhov on 2023-08-31.
//

import Foundation
import Defaults
import SwiftUI

extension Defaults.Keys {
    static let githubUsername = Key<String>("githubUsername", default: "")
    static let daysBefore = Key<Int>("daysBefore", default: 20)
    static let theme = Key<String>("theme", default: "standard")
    static let borders = Key<Bool>("borders", default: true)
    static let transparency = Key<Bool>("transparency", default: true)
}

extension KeychainKeys {
    static let githubToken: KeychainAccessKey = KeychainAccessKey(key: "githubToken")
}

prefix func ! (value: Binding<Bool>) -> Binding<Bool> {
    Binding<Bool>(
        get: { !value.wrappedValue },
        set: { value.wrappedValue = !$0 }
    )
}
