//
//  StatusItemView.swift
//  streak-bar
//
//  Created by Pavel Makhov on 2023-08-30.
//

import SwiftUI
import Defaults

struct StatusItemView: View {
    
    @ObservedObject var viewModel: ViewModel
    @Default(.theme) var theme
    @Default(.borders) var borders
    @Default(.emptyDayTransparency) var emptyDayTransparency
    @Default(.viewMode) var viewMode
    @Default(.daysBefore) var daysBefore
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    // Week mode keeps GitHub's Sunday-aligned weeks so each row is a fixed weekday
    private var displayContributions: [ContributionWeek] {
        if viewMode == .week {
            return Array(viewModel.contributions.suffix(daysBefore))
        }
        let allDays = viewModel.contributions.flatMap { $0.contributionDays }
        return [ContributionWeek(contributionDays: Array(allDays.suffix(daysBefore)))]
    }

    private func color(for level: ContributionLevel) -> Color {
        let color = Theme.palette(named: theme)[level] ?? .gray
        return color.opacity(level == .NONE && emptyDayTransparency ? 0.2 : 1)
    }

    var body: some View {
        Group {
            switch viewModel.loadingState {
            case .loading:
                loadingView
            case .error(let message):
                errorView(message: message)
            default:
                contributionChart
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: viewModel.loadingState)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: viewModel.contributions)
    }
    
    private var loadingView: some View {
        ProgressView()
            .scaleEffect(0.5)
            .frame(width: 16, height: 16)
    }

    private func errorView(message: String) -> some View {
        Circle()
            .fill(.red)
            .frame(width: 8, height: 8)
            .help("Error loading contributions: \(message)")
    }

    @ViewBuilder
    private var contributionChart: some View {
        if displayContributions.allSatisfy({ $0.contributionDays.isEmpty }) {
            emptyStateView
        } else {
            if viewMode == .week {
                weekView
            } else {
                dayView
            }
        }
    }

    private var emptyStateView: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill((Theme.palette(named: theme)[.SECOND_QUARTILE] ?? .gray).opacity(0.3))
            .frame(width: 16, height: 16)
    }

    private var weekView: some View {
        HStack(alignment: .top, spacing: borders ? 1 : 0) {
            ForEach(displayContributions, id:\.self) { week in
                VStack(alignment: .leading, spacing: borders ? 1 : 0) {
                    ForEach(week.contributionDays, id:\.date) { day in
                        Rectangle()
                            .fill(color(for: day.contributionLevel))
                            .frame(width: borders ? 2 : 3, height: borders ? 2 : 3)
                    }
                }
            }
        }
    }

    private var dayView: some View {
        HStack(spacing: 1) {
            ForEach(displayContributions, id:\.self) { week in
                ForEach(week.contributionDays, id:\.date) { day in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color(for: day.contributionLevel))
                        .frame(width: 16, height: 16)
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
