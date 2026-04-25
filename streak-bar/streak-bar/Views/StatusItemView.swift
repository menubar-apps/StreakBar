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

    var isFullSize: Bool = false
    
    // Computed property to get only the days that should be displayed in menubar
    private var displayContributions: [ContributionWeek] {
        if isFullSize {
            // In full size (popover), show all data
            return viewModel.contributions
        } else {
            // In menubar, limit to daysBefore setting
            let allDays = viewModel.contributions.flatMap { $0.contributionDays }
            let multiplier = viewMode == .week ? 7 : 1
            let daysToShow = daysBefore * multiplier
            let limitedDays = Array(allDays.suffix(daysToShow))
            
            // Group back into weeks for display
            if viewMode == .week {
                var weeks: [ContributionWeek] = []
                var currentWeek: [ContributionDay] = []
                
                for day in limitedDays {
                    currentWeek.append(day)
                    if currentWeek.count == 7 {
                        weeks.append(ContributionWeek(contributionDays: currentWeek))
                        currentWeek = []
                    }
                }
                if !currentWeek.isEmpty {
                    weeks.append(ContributionWeek(contributionDays: currentWeek))
                }
                return weeks
            } else {
                // For day view, return as single week
                return [ContributionWeek(contributionDays: limitedDays)]
            }
        }
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
    
    @ViewBuilder
    private var loadingView: some View {
        if isFullSize {
            VStack(spacing: 12) {
                ProgressView()
                    .scaleEffect(0.8)
                Text("Loading contributions...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ProgressView()
                .scaleEffect(0.5)
                .frame(width: 16, height: 16)
        }
    }
    
    @ViewBuilder
    private func errorView(message: String) -> some View {
        if isFullSize {
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.red)
                Text("Failed to load contributions")
                    .font(.headline)
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
        } else {
            Circle()
                .fill(.red)
                .frame(width: 8, height: 8)
                .help("Error loading contributions: \(message)")
        }
    }
    
    @ViewBuilder
    private var contributionChart: some View {
        if displayContributions.first?.contributionDays.isEmpty ?? false {
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
        Group {
            if isFullSize {
                VStack(spacing: 12) {
                    Image(systemName: "chart.bar.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("No contributions yet")
                        .font(.headline)
                    Text("Configure your GitHub username in Settings")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Theme.themes[theme]![.SECOND_QUARTILE]!.opacity(0.3))
                    .frame(width: 16, height: 16)
            }
        }
    }
    
    private var weekView: some View {
        HStack(alignment: .top, spacing: borders ? 1 : 0) {
            ForEach(displayContributions, id:\.self) { week in
                VStack(alignment: .leading, spacing: borders ? 1 : 0) {
                    ForEach(week.contributionDays, id:\.date) { day in
                        Rectangle()
                            .fill(Theme.themes[theme]![day.contributionLevel]!.opacity(day.contributionLevel == .NONE && emptyDayTransparency ? 0.2 : 1))
                            .frame(width: (borders ? 2 : 3) * (isFullSize ? 3 : 1), height: (borders ? 2 : 3) * (isFullSize ? 3 : 1))
                            .help(isFullSize ? contributionTooltip(for: day) : "")
                    }
                }
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if isFullSize, let lastUpdate = viewModel.lastUpdateTime {
                Text("Updated \(timeAgo(lastUpdate))")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(4)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 4))
                    .offset(y: 20)
            }
        }
    }
    
    private var dayView: some View {
        HStack(spacing: 1) {
            ForEach(displayContributions, id:\.self) { week in
                ForEach(week.contributionDays, id:\.date) { day in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Theme.themes[theme]![day.contributionLevel]!.opacity(day.contributionLevel == .NONE && emptyDayTransparency ? 0.2 : 1))
                        .frame(width: 16 * (isFullSize ? 3 : 1), height: 16 * (isFullSize ? 3 : 1))
                        .help(isFullSize ? contributionTooltip(for: day) : "")
                }
            }
        }
        .overlay(alignment: .bottom) {
            if isFullSize, let lastUpdate = viewModel.lastUpdateTime {
                Text("Updated \(timeAgo(lastUpdate))")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(4)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 4))
                    .offset(y: 20)
            }
        }
    }
    
    // Reused across all cells — DateFormatter is expensive to allocate
    private static let dayInputFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private static let dayOutputFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    private func contributionTooltip(for day: ContributionDay) -> String {
        if let date = Self.dayInputFormatter.date(from: day.date) {
            let dateString = Self.dayOutputFormatter.string(from: date)
            let count = day.contributionCount
            let plural = count == 1 ? "contribution" : "contributions"
            return "\(dateString)\n\(count) \(plural)"
        } else {
            let count = day.contributionCount
            let plural = count == 1 ? "contribution" : "contributions"
            return "\(day.date)\n\(count) \(plural)"
        }
    }
    
    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f
    }()

    private func timeAgo(_ date: Date) -> String {
        Self.relativeFormatter.localizedString(for: date, relativeTo: Date())
    }
}

struct StatusItemView_Previews: PreviewProvider {
    static var previews: some View {
        StatusItemView(viewModel: ViewModel())
    }
}
