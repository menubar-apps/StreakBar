//
//  CommitsChartView.swift
//  streak-bar
//
//  Created for HIG improvements
//

import Cocoa
import SwiftUI
import Charts
import Defaults

struct DayCommitData: Identifiable {
    let id = UUID()
    let date: Date
    let commits: Int
}

struct StackedCommitData: Identifiable {
    let id = UUID()
    let date: Date
    let repoCommits: [RepoCommit]
}

struct RepoCommit: Identifiable {
    let id = UUID()
    let repoName: String
    let count: Int
    let color: Color
}

struct CommitsChartView: View {
    @ObservedObject var viewModel: ViewModel
    var appDelegate: AppDelegate
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    // Track the offset in 21-day periods (0 = most recent, 1 = previous 21 days, etc.)
    @State private var periodOffset: Int = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar with navigation and hamburger menu
            HStack(spacing: 12) {
                // Navigation controls on the left
                HStack(spacing: 8) {
                    Button(action: { periodOffset += 1 }) {
                        Image(systemName: "chevron.left")
                            .font(.body)
                            .frame(width: 28, height: 28)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(!canNavigateBackward)
                    .help("Previous 21 days")
                    
                    Text(dateRangeText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(minWidth: 100)
                        .fixedSize()
                    
                    Button(action: { periodOffset = max(0, periodOffset - 1) }) {
                        Image(systemName: "chevron.right")
                            .font(.body)
                            .frame(width: 28, height: 28)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(periodOffset == 0)
                    .help("Next 21 days")
                    
                    if periodOffset > 0 {
                        Button(action: { periodOffset = 0 }) {
                            Text("Today")
                                .font(.caption)
                                .fixedSize()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .help("Return to current period")
                    }
                }
                
                Spacer()
                
                // Menu button on the right
                Menu {
                    Button("Settings...") {
                        openSettings()
                    }
                    .keyboardShortcut(",", modifiers: .command)
                    
                    Button("About StreakBar") {
                        openAbout()
                    }
                    
                    Divider()
                    
                    Button("Quit") {
                        NSApplication.shared.terminate(nil)
                    }
                    .keyboardShortcut("q", modifiers: .command)
                } label: {
                    Image(systemName: "line.3.horizontal")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .fixedSize()
                .accessibilityLabel("Menu")
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)
            
            Divider()
            
            // Main content - no scrolling
            VStack(spacing: 20) {
                // Stats section - only use skeleton before profile data has ever loaded
                Group {
                    if viewModel.avatarUrl != nil {
                        statsSection
                    } else {
                        skeletonStatsSection
                    }
                }
                .frame(height: 56) // Fixed height to prevent jumping
                
                // Chart section
                chartSection
            }
            .padding(20)
        }
        .onAppear {
            // Fetch chart data when view appears (only if not already loaded)
            if case .idle = viewModel.chartLoadingState {
                fetchChartData()
            }
        }
        .onChange(of: periodOffset) { _ in
            // Fetch more data when user navigates to a period we don't have yet
            fetchChartData()
        }
    }
    
    private var skeletonStatsSection: some View {
        HStack(spacing: 16) {
            // Avatar skeleton
            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 4) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 90, height: 13)
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 60, height: 11)
            }

            Spacer()

            // Stat rows skeleton
            VStack(alignment: .trailing, spacing: 6) {
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 100, height: 12)
                }
            }
        }
        .padding(.horizontal, 4)
        .shimmering(reduceMotion: reduceMotion)
        .accessibilityElement(children: .contain)
    }

    private var statsSection: some View {
        HStack(spacing: 16) {
            // Avatar + username
            HStack(spacing: 10) {
                Group {
                    if let urlString = viewModel.avatarUrl, let url = URL(string: urlString) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable().scaledToFill()
                            default:
                                Circle().fill(Color.gray.opacity(0.2))
                            }
                        }
                    } else {
                        Circle().fill(Color.gray.opacity(0.2))
                    }
                }
                .frame(width: 48, height: 48)
                .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    if let name = viewModel.userDisplayName, !name.isEmpty {
                        Text(name)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                    }
                    Text("@\(Defaults[.githubUsername])")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Compact stats
            VStack(alignment: .trailing, spacing: 5) {
                compactStat(value: "\(totalCommits)", label: "commits")
                compactStat(value: String(format: "%.1f", averageCommits), label: "per day")
                compactStat(value: "\(currentStreak)d", label: "streak")
            }
        }
        .padding(.horizontal, 4)
        .accessibilityElement(children: .contain)
    }

    private func compactStat(value: String, label: String) -> some View {
        HStack(spacing: 4) {
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            switch viewModel.chartLoadingState {
            case .idle:
                skeletonChartView
            case .loading:
                skeletonChartView
            case .success:
                if stackedChartData.isEmpty {
                    emptyStateView(message: "No commit data available for the last 21 days")
                } else {
                    VStack(spacing: 16) {
                        stackedBarChart
                        
                        if !repositoryLegendItems.isEmpty {
                            repositoryLegend
                        }
                    }
                }
            case .error(let message):
                errorStateView(message: message)
            }
        }
        .padding(16)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }
    
    // Fixed heights for the 21 skeleton bars — stable across re-renders
    private let skeletonBarHeights: [CGFloat] = [
        80, 120, 60, 150, 90, 180, 70, 110, 140, 55,
        160, 95, 130, 75, 100, 170, 85, 120, 65, 145, 90
    ]

    private var skeletonChartView: some View {
        VStack(spacing: 16) {
            // Skeleton chart bars
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(0..<21, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: skeletonBarHeights[i])
                }
            }
            .frame(height: 200)
            .redacted(reason: .placeholder)
            .shimmering(reduceMotion: reduceMotion)
            
            // Skeleton legend
            VStack(alignment: .leading, spacing: 8) {
                Text("Repositories")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], alignment: .leading, spacing: 8) {
                    ForEach(0..<4, id: \.self) { _ in
                        HStack(spacing: 6) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 12, height: 12)
                            
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 100, height: 12)
                        }
                    }
                }
            }
            .padding(12)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
            .cornerRadius(6)
            .frame(maxHeight: 180)
            .redacted(reason: .placeholder)
            .shimmering(reduceMotion: reduceMotion)
        }
    }
    
    private func emptyStateView(message: String, isError: Bool = false) -> some View {
        VStack(spacing: 12) {
            Image(systemName: isError ? "exclamationmark.triangle" : "chart.bar")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text(message)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
    
    private func errorStateView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(.orange)
            
            Text(message)
                .font(.body)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            
            // Show action button if it's a configuration issue
            if message.contains("token") || message.contains("username") || message.contains("Settings") {
                Button(action: openSettings) {
                    HStack(spacing: 6) {
                        Image(systemName: "gearshape")
                        Text("Open Settings")
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
    
    private var stackedBarChart: some View {
        Chart {
            ForEach(stackedChartData) { dayData in
                if dayData.repoCommits.isEmpty {
                    // Show a zero-height bar for days with no commits
                    BarMark(
                        x: .value("Date", dayData.date, unit: .day),
                        y: .value("Commits", 0)
                    )
                    .foregroundStyle(.clear)
                } else {
                    ForEach(dayData.repoCommits) { repoCommit in
                        BarMark(
                            x: .value("Date", dayData.date, unit: .day),
                            y: .value("Commits", repoCommit.count)
                        )
                        .foregroundStyle(repoCommit.color)
                    }
                }
            }
        }
        .frame(height: 200)
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: 5))
        }
        .chartYAxis {
            AxisMarks()
        }
        .chartLegend(.hidden)
        .accessibilityLabel("Commits by repository over last 21 days")
        .accessibilityValue("\(totalCommits) total commits")
    }
    
    private var simpleBarChart: some View {
        Chart {
            ForEach(chartData) { dayData in
                BarMark(
                    x: .value("Date", dayData.date, unit: .day),
                    y: .value("Commits", dayData.commits)
                )
                .foregroundStyle(.blue)
            }
        }
        .frame(height: 200)
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: 5))
        }
        .chartYAxis {
            AxisMarks()
        }
        .accessibilityLabel("Commits over last 21 days")
        .accessibilityValue("\(chartData.reduce(0) { $0 + $1.commits }) total commits")
    }
    
    private var repositoryLegend: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Repositories")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], alignment: .leading, spacing: 8) {
                    ForEach(repositoryLegendItems, id: \.name) { item in
                        HStack(spacing: 6) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(item.color)
                                .frame(width: 12, height: 12)
                            
                            Text(item.name)
                                .font(.caption)
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                            
                            Text("(\(item.commits))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .frame(maxHeight: 180)
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        .cornerRadius(6)
    }
    
    // MARK: - Computed Properties
    
    private var canNavigateBackward: Bool {
        // Always allow navigating backward - we'll fetch more data as needed
        // You could add a reasonable limit here if desired (e.g., max 365 days)
        let maxPeriodsBack = 17 // ~1 year (17 * 21 = 357 days)
        return periodOffset < maxPeriodsBack
    }
    
    private var dateRangeText: String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Calculate the start date based on periodOffset
        let offsetDays = periodOffset * 21
        guard let endDate = calendar.date(byAdding: .day, value: -offsetDays, to: today),
              let startDate = calendar.date(byAdding: .day, value: -20, to: endDate) else {
            return "Last 21 Days"
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        
        if periodOffset == 0 {
            return "Last 21 Days"
        } else {
            return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
        }
    }
    
    private var stackedChartData: [StackedCommitData] {
        // Get date range for last 21 days
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime]
        
        var dateToRepoCommits: [Date: [String: Int]] = [:]
        var allRepoNames = Set<String>()
        
        // Process all repository contributions
        for repoData in viewModel.contributionsByRepo {
            let repoName = "\(repoData.repository.owner.login)/\(repoData.repository.name)"
            allRepoNames.insert(repoName)
            
            for contribution in repoData.contributions.nodes {
                if let date = dateFormatter.date(from: contribution.occurredAt) {
                    let dayStart = calendar.startOfDay(for: date)
                    
                    if dateToRepoCommits[dayStart] == nil {
                        dateToRepoCommits[dayStart] = [:]
                    }
                    dateToRepoCommits[dayStart]?[repoName] = contribution.commitCount
                }
            }
        }
        
        // Assign colors to repositories (sorted for consistency)
        let repoColors = assignColorsToRepos(Array(allRepoNames).sorted())
        
        // Calculate the base date for this period
        let baseDaysOffset = periodOffset * 21
        
        // Create data for 21 days based on the period offset
        var result: [StackedCommitData] = []
        for dayOffset in (0..<21).reversed() {
            let totalOffset = baseDaysOffset + dayOffset
            if let date = calendar.date(byAdding: .day, value: -totalOffset, to: today) {
                let repoCommits = (dateToRepoCommits[date] ?? [:])
                    .map { repoName, count in
                        RepoCommit(repoName: repoName, count: count, color: repoColors[repoName] ?? .gray)
                    }
                    .sorted { $0.repoName < $1.repoName }
                
                result.append(StackedCommitData(date: date, repoCommits: repoCommits))
            }
        }
        
        return result
    }
    
    private func assignColorsToRepos(_ repoNames: [String]) -> [String: Color] {
        let predefinedColors: [Color] = [
            .blue, .green, .orange, .purple, .pink,
            .red, .yellow, .cyan, .mint, .indigo
        ]
        
        var result: [String: Color] = [:]
        for (index, repoName) in repoNames.enumerated() {
            result[repoName] = predefinedColors[index % predefinedColors.count]
        }
        return result
    }
    
    private var repositoryLegendItems: [(name: String, color: Color, commits: Int)] {
        var repoInfo: [String: (color: Color, commits: Int)] = [:]

        // Derive totals and colors directly from stackedChartData so both
        // chart bars and legend always use the same color assignment.
        for dayData in stackedChartData {
            for repoCommit in dayData.repoCommits {
                let existing = repoInfo[repoCommit.repoName]
                repoInfo[repoCommit.repoName] = (
                    color: existing?.color ?? repoCommit.color,
                    commits: (existing?.commits ?? 0) + repoCommit.count
                )
            }
        }

        return repoInfo
            .map { (name: $0.key, color: $0.value.color, commits: $0.value.commits) }
            .sorted { $0.commits > $1.commits }
    }
    
    private var totalCommits: Int {
        stackedChartData.reduce(0) { total, dayData in
            total + dayData.repoCommits.reduce(0) { $0 + $1.count }
        }
    }

    private var chartData: [DayCommitData] {
        stackedChartData.map { dayData in
            DayCommitData(
                date: dayData.date,
                commits: dayData.repoCommits.reduce(0) { $0 + $1.count }
            )
        }
    }
    
    private var averageCommits: Double {
        guard !stackedChartData.isEmpty else { return 0 }
        return Double(totalCommits) / Double(stackedChartData.count)
    }
    
    private var currentStreak: Int {
        // Use allContributionDays (full year) so the streak is not capped by the menubar display window
        let allDays = viewModel.allContributionDays
        guard !allDays.isEmpty else { return 0 }
        
        var streak = 0
        for day in allDays.reversed() {
            if day.contributionCount > 0 {
                streak += 1
            } else {
                break
            }
        }
        return streak
    }
    
    // MARK: - Actions
    
    private func fetchChartData() {
        // Calculate how many days we need based on periodOffset
        let daysNeeded = (periodOffset + 1) * 21
        viewModel.getContributionsByRepository(days: daysNeeded)
    }
    
    private func openSettings() {
        appDelegate.openSettingsWindow()
    }
    
    private func openAbout() {
        appDelegate.openAboutWindow()
    }
}

// MARK: - Shimmering Effect

struct Shimmering: ViewModifier {
    @State private var phase: CGFloat = 0
    var reduceMotion: Bool
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [
                        .clear,
                        .white.opacity(reduceMotion ? 0 : 0.3),
                        .clear
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase)
                .mask(content)
            )
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(
                    .linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
                ) {
                    phase = 400
                }
            }
    }
}

extension View {
    func shimmering(reduceMotion: Bool = false) -> some View {
        modifier(Shimmering(reduceMotion: reduceMotion))
    }
}
