//
//  StatusItemView.swift
//  streak-bar
//
//  Created by Pavel Makhov on 2023-08-30.
//

import SwiftUI
import Defaults

struct StatusItemView: View {
    
    @StateObject var viewModel: ViewModel
    @Default(.theme) var theme
    @Default(.borders) var borders
    @Default(.transparency) var transparency
    
    var body: some View {
        HStack(alignment: .top, spacing: borders ? 1 : 0) {
            ForEach(viewModel.contributions, id:\.self) { week in
                VStack(alignment: .leading, spacing:  borders ? 1 : 0) {
                    ForEach(week.contributionDays, id:\.date) { day in
                        Rectangle()
                            .fill(Theme.themes[theme]![day.contributionLevel]!.opacity(day.contributionLevel == .NONE && !transparency ? 0 : 1))
                            .frame(width: borders ? 2 : 3, height: borders ? 2 : 3)
                    }
                }
            }
        }
    }
}

struct StatusItemView_Previews: PreviewProvider {
    static var previews: some View {
        StatusItemView(viewModel: ViewModel())
    }
}
