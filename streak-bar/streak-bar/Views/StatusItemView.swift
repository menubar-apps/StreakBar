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
    @Default(.viewMode) var viewMode
    
    var body: some View {
        
        if viewModel.contributions.first?.contributionDays.isEmpty ?? false {
            RoundedRectangle(cornerRadius: 4)
                .fill(Theme.themes[theme]![.SECOND_QUARTILE]!.opacity(1))
                .frame(width: 16, height: 16)
        }
        else {
            if viewMode == .week {
                HStack(alignment: .top, spacing: borders ? 1 : 0) {
                    ForEach(viewModel.contributions, id:\.self) { week in
                        VStack(alignment: .leading, spacing:  borders ? 1 : 0) {
                            ForEach(week.contributionDays, id:\.date) { day in
                                Rectangle()
                                    .fill(Theme.themes[theme]![day.contributionLevel]!.opacity(day.contributionLevel == .NONE && !transparency ? 0.2 : 1))
                                    .frame(width: borders ? 2 : 3, height: borders ? 2 : 3)
                            }
                        }
                    }
                }
            } else {
                HStack(spacing: 1) {
                    ForEach(viewModel.contributions, id:\.self) { week in
                        ForEach(week.contributionDays, id:\.date) { day in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Theme.themes[theme]![day.contributionLevel]!.opacity(day.contributionLevel == .NONE && !transparency ? 0.2 : 1))
                                .frame(width: 16, height: 16)
                        }
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
