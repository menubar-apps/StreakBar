//
//  Theme.swift
//  streak-bar
//
//  Created by Pavel Makhov on 2023-09-01.
//

import Foundation
import SwiftUI

struct Theme {
    static let themes: [String: [ContributionLevel: Color]] = [
        "standard": [
            .FOURTH_QUARTILE: Color(hex: "#216e39"),
            .THIRD_QUARTILE: Color(hex: "#30a14e"),
            .SECOND_QUARTILE: Color(hex: "#40c463"),
            .FIRST_QUARTILE: Color(hex: "#9be9a8"),
            .NONE: Color(hex: "#ebedf0")
        ],
        "classic": [
            .FOURTH_QUARTILE: Color(hex: "#196127"),
            .THIRD_QUARTILE: Color(hex: "#239a3b"),
            .SECOND_QUARTILE: Color(hex: "#7bc96f"),
            .FIRST_QUARTILE: Color(hex: "#c6e48b"),
            .NONE: Color(hex: "#ebedf0"),
        ],
        "teal": [
            .FOURTH_QUARTILE: Color(hex: "#458B74"),
            .THIRD_QUARTILE: Color(hex: "#66CDAA"),
            .SECOND_QUARTILE: Color(hex: "#76EEC6"),
            .FIRST_QUARTILE: Color(hex: "#7FFFD4"),
            .NONE: Color(hex: "#ebedf0"),
        ],
        "leftpad": [
            .FOURTH_QUARTILE: Color(hex: "#F6F6F6"),
            .THIRD_QUARTILE: Color(hex: "#DDDDDD"),
            .SECOND_QUARTILE: Color(hex: "#A5A5A5"),
            .FIRST_QUARTILE: Color(hex: "#646464"),
            .NONE: Color(hex: "#2F2F2F"),
        ],
        "dracula": [
            .FOURTH_QUARTILE: Color(hex: "#ff79c6"),
            .THIRD_QUARTILE: Color(hex: "#bd93f9"),
            .SECOND_QUARTILE: Color(hex: "#6272a4"),
            .FIRST_QUARTILE: Color(hex: "#44475a"),
            .NONE: Color(hex: "#282a36")
        ],
        "pink": [
            .FOURTH_QUARTILE: Color(hex: "#61185f"),
            .THIRD_QUARTILE: Color(hex: "#a74aa8"),
            .SECOND_QUARTILE: Color(hex: "#ca5bcc"),
            .FIRST_QUARTILE: Color(hex: "#e48bdc"),
            .NONE: Color(hex: "#ebedf0"),
        ]
    ]}
