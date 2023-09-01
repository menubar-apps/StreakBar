//
//  Settings.swift
//  streak-bar
//
//  Created by Pavel Makhov on 2023-08-31.
//

import Foundation
import Defaults

extension Defaults.Keys {
    static let githubUsername = Key<String>("githubUsername", default: "")
    static let daysBefore = Key<Int>("daysBefore", default: 20)
    
}

extension KeychainKeys {
    static let githubToken: KeychainAccessKey = KeychainAccessKey(key: "githubToken")
}
