//
//  CommitsChartView.swift
//  streak-bar
//
//  Created for HIG improvements
//

import Cocoa
import SwiftUI
import Charts
import Accessibility
import Defaults

struct StackedCommitData: Identifiable {
    let date: Date
    let repoCommits: [RepoCommit]

    var id: Date { date }
    var total: Int { repoCommits.reduce(0) { $0 + $1.count } }
}

struct RepoCommit: Identifiable {
    let repoName: String
    let count: Int
    let color: Color

    var id: String { repoName }
}

struct RepoLegendItem: Identifiable {
    let name: String
    let color: Color
    let commits: Int

    var id: String { name }
}

/// Chart data for one calendar month. Days after today are listed in `futureDays` only.
struct MonthChartModel {
    let month: Date
    let nextMonth: Date
    let today: Date
    let days: [StackedCommitData]
    let futureDays: [Date]
    let legend: [RepoLegendItem]

    var totalCommits: Int { days.reduce(0) { $0 + $1.total } }
    var maxDailyCommits: Int { days.map(\.total).max() ?? 0 }
    var average: Double { days.isEmpty ? 0 : Double(totalCommits) / Double(days.count) }
    var containsToday: Bool { today >= month && today < nextMonth }
    var title: String { month.formatted(.dateTime.month(.wide).year()) }
}

struct CommitsChartView: View {
    @ObservedObject var viewModel: ViewModel
    var appDelegate: AppDelegate
    @Binding var isShowingSettings: Bool
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    // Months back from the current month (0 = current month)
    @State private var monthOffset: Int = 0
    @State private var navigationEdge: Edge = .trailing
    @State private var selectedDate: Date?
    @State private var hoveredRepo: String?
    @State private var pinnedRepo: String?
    @State private var isCelebrating = false

    private let maxMonthsBack = 12
    private let otherRepoName = "Other"
    private let streakMilestones: Set<Int> = [7, 30, 100, 365]
    private let avatarSize: CGFloat = 52

    var body: some View {
        let model = makeMonthModel()

        VStack(spacing: 0) {
            Group {
                if viewModel.avatarUrl != nil {
                    headerSection(model)
                } else {
                    skeletonHeaderSection
                }
            }
            .frame(height: 56) // Fixed height to prevent jumping
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 12)

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                monthNavigation(model)
                chartSection(model)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)

            Spacer(minLength: 0)
        }
        .onAppear {
            // Fetch chart data when view appears (only if not already loaded)
            if case .idle = viewModel.chartLoadingState {
                fetchChartData()
            }
        }
        .onChange(of: monthOffset) { _ in
            selectedDate = nil
            pinnedRepo = nil
            fetchChartData()
        }
    }

    // MARK: - Header

    private var skeletonHeaderSection: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: avatarSize, height: avatarSize)
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 120, height: 13)
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 80, height: 11)
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 150, height: 11)
            }
            Spacer()
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 80, height: 48)
        }
        .shimmering(reduceMotion: reduceMotion)
        .accessibilityElement(children: .contain)
    }

    private func headerSection(_ model: MonthChartModel) -> some View {
        HStack(spacing: 12) {
            avatar
            profileDetails
            Spacer(minLength: 8)
            streakSummary
        }
    }

    private var avatar: some View {
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
        .frame(width: avatarSize, height: avatarSize)
        .clipShape(Circle())
        .overlay(Circle().strokeBorder(Color.primary.opacity(0.1), lineWidth: 0.5))
        .accessibilityHidden(true)
    }

    private var profileDetails: some View {
        VStack(alignment: .leading, spacing: 1) {
            let login = "@\(Defaults[.githubUsername])"
            if let name = viewModel.userDisplayName, !name.isEmpty {
                Text(name)
                    .font(.headline)
                    .lineLimit(1)
                Text(login)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            } else {
                Text(login)
                    .font(.headline)
                    .lineLimit(1)
            }
            streakMessageRow
                .padding(.top, 2)
        }
        .accessibilityElement(children: .combine)
    }

    private var streakSummary: some View {
        VStack(alignment: .trailing, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.title2)
                    .foregroundStyle(
                        currentStreak > 0
                            ? AnyShapeStyle(LinearGradient(colors: [.yellow, .orange, .red], startPoint: .top, endPoint: .bottom))
                            : AnyShapeStyle(.tertiary)
                    )
                    .scaleEffect(isCelebrating ? 1.3 : 1, anchor: .bottom)
                Text("\(currentStreak)")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .animation(reduceMotion ? nil : .default, value: currentStreak)
            }
            Text("day streak · best \(bestStreak)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .fixedSize()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Current streak: \(currentStreak) days. Best streak: \(bestStreak) days")
        .onAppear(perform: celebrateMilestoneIfNeeded)
        .onChange(of: currentStreak) { _ in celebrateMilestoneIfNeeded() }
    }

    @ViewBuilder
    private var streakMessageRow: some View {
        if let message = streakMessage {
            Label(message.text, systemImage: message.symbol)
                .font(.caption)
                .foregroundStyle(message.tint)
                .lineLimit(1)
                .truncationMode(.tail)
        }
    }

    // MARK: - Month Navigation

    private func monthNavigation(_ model: MonthChartModel) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(model.title)
                .font(.title3)
                .fontWeight(.semibold)
                .accessibilityAddTraits(.isHeader)

            if viewModel.contributionsByMonth[model.month] != nil {
                Text("\(model.totalCommits) commits · \(String(format: "%.1f", model.average)) per day")
                    .font(.subheadline)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .contentTransition(.numericText())
                    .animation(reduceMotion ? nil : .default, value: model.totalCommits)
            }

            Spacer()

            if monthOffset > 0 {
                Button("Today") { navigate(to: 0) }
                    .controlSize(.small)
                    .keyboardShortcut("t", modifiers: .command)
                    .help("Return to the current month (⌘T)")
            }

            ControlGroup {
                Button { navigate(to: monthOffset + 1) } label: {
                    Image(systemName: "chevron.left")
                }
                .disabled(monthOffset >= maxMonthsBack)
                .keyboardShortcut(.leftArrow, modifiers: [])
                .help("Previous month (←)")
                .accessibilityLabel("Previous month")

                Button { navigate(to: monthOffset - 1) } label: {
                    Image(systemName: "chevron.right")
                }
                .disabled(monthOffset == 0)
                .keyboardShortcut(.rightArrow, modifiers: [])
                .help("Next month (→)")
                .accessibilityLabel("Next month")
            }
            .controlSize(.small)
            .fixedSize()
        }
    }

    // MARK: - Chart Section

    @ViewBuilder
    private func chartSection(_ model: MonthChartModel) -> some View {
        Group {
            if viewModel.contributionsByMonth[model.month] != nil {
                Group {
                    if model.totalCommits == 0 && !model.containsToday {
                        emptyStateView(message: "No commits in \(model.month.formatted(.dateTime.month(.wide)))")
                    } else {
                        monthContent(model)
                    }
                }
                .id(model.month)
                .transition(monthTransition)
            } else if viewModel.chartMonth == model.month, case .error(let message) = viewModel.chartLoadingState {
                errorStateView(message: message)
            } else {
                skeletonChartView
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .clipped()
    }

    private func monthContent(_ model: MonthChartModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            selectionDetail(model)
                .frame(height: 30, alignment: .topLeading)

            stackedBarChart(model)

            if !model.legend.isEmpty {
                repositoryLegend(model)
                    .padding(.top, 4)
            }
        }
    }

    @ViewBuilder
    private func selectionDetail(_ model: MonthChartModel) -> some View {
        if let selectedDate, let day = model.days.first(where: { $0.date == selectedDate }) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(day.date.formatted(.dateTime.weekday(.wide).month().day())) · \(day.total) \(day.total == 1 ? "commit" : "commits")")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(day.repoCommits.isEmpty ? "No commits" : day.repoCommits.map { "\(shortRepoName($0.repoName)) \($0.count)" }.joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        } else {
            Text("Point at a day for details. Click to open it on GitHub.")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }

    // Fixed heights for the skeleton bars — stable across re-renders
    private let skeletonBarHeights: [CGFloat] = [
        80, 120, 60, 150, 90, 160, 70, 110, 140, 55,
        150, 95, 130, 75, 100, 155, 85, 120, 65, 145, 90
    ]

    private var skeletonChartView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(0..<skeletonBarHeights.count, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: skeletonBarHeights[i])
                }
            }
            .frame(height: 160, alignment: .bottom)
            .padding(.top, 38)

            VStack(alignment: .leading, spacing: 10) {
                ForEach(0..<4, id: \.self) { _ in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 8, height: 8)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 140, height: 12)
                        Spacer()
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 24, height: 12)
                    }
                    .padding(.horizontal, 8)
                }
            }
        }
        .shimmering(reduceMotion: reduceMotion)
        .accessibilityLabel("Loading contributions")
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
            
            if viewModel.chartErrorRequiresSignIn {
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
    
    private func stackedBarChart(_ model: MonthChartModel) -> some View {
        let yMax = max(Double(model.maxDailyCommits), model.average, 4)

        return Chart {
            if model.containsToday {
                RectangleMark(x: .value("Date", model.today, unit: .day))
                    .foregroundStyle(Color.accentColor.opacity(0.1))
            }

            ForEach(model.days) { day in
                ForEach(day.repoCommits) { repoCommit in
                    BarMark(
                        x: .value("Date", day.date, unit: .day),
                        y: .value("Commits", repoCommit.count)
                    )
                    .foregroundStyle(repoCommit.color)
                    .cornerRadius(2)
                    .opacity(barOpacity(date: day.date, repoName: repoCommit.repoName))
                }
            }

            // Placeholders for the rest of the current month
            ForEach(model.futureDays, id: \.self) { day in
                PointMark(
                    x: .value("Date", day, unit: .day),
                    y: .value("Commits", 0)
                )
                .symbolSize(10)
                .foregroundStyle(Color.secondary.opacity(0.4))
            }

            if model.average > 0 {
                RuleMark(y: .value("Average", model.average))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    .foregroundStyle(Color.secondary.opacity(0.6))
            }
        }
        .frame(height: 160)
        .chartXScale(domain: model.month...model.nextMonth)
        .chartYScale(domain: 0...yMax)
        .chartXAxis {
            AxisMarks(values: weekAxisDates(model)) { _ in
                AxisValueLabel(format: .dateTime.day())
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                AxisValueLabel()
            }
        }
        .chartLegend(.hidden)
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .onContinuousHover { phase in
                        switch phase {
                        case .active(let location):
                            selectedDate = day(at: location, proxy: proxy, geometry: geometry, model: model)
                        case .ended:
                            selectedDate = nil
                        }
                    }
                    .gesture(
                        SpatialTapGesture().onEnded { value in
                            if let date = day(at: value.location, proxy: proxy, geometry: geometry, model: model) {
                                openDayOnGitHub(date)
                            }
                        }
                    )
            }
        }
        .accessibilityChartDescriptor(MonthChartDescriptor(model: model))
    }

    private func repositoryLegend(_ model: MonthChartModel) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(model.legend) { item in
                HStack(spacing: 8) {
                    Circle()
                        .fill(item.color)
                        .frame(width: 8, height: 8)
                    Text(item.name)
                        .font(.callout)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer(minLength: 8)
                    Text("\(item.commits)")
                        .font(.callout)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 8)
                .frame(height: 22)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(focusedRepo == item.name ? Color.primary.opacity(0.08) : .clear)
                )
                .contentShape(Rectangle())
                .onHover { isHovering in
                    if isHovering {
                        hoveredRepo = item.name
                    } else if hoveredRepo == item.name {
                        hoveredRepo = nil
                    }
                }
                .onTapGesture {
                    pinnedRepo = pinnedRepo == item.name ? nil : item.name
                }
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(pinnedRepo == item.name ? [.isButton, .isSelected] : .isButton)
                .accessibilityHint("Highlights this repository in the chart")
            }
        }
    }

    // MARK: - Computed Properties

    private var displayedMonth: Date {
        let calendar = Calendar.current
        let currentMonth = calendar.startOfMonth(for: Date())
        return calendar.date(byAdding: .month, value: -monthOffset, to: currentMonth) ?? currentMonth
    }

    private var focusedRepo: String? {
        hoveredRepo ?? pinnedRepo
    }

    private var monthTransition: AnyTransition {
        guard !reduceMotion else { return .opacity }
        let removalEdge: Edge = navigationEdge == .leading ? .trailing : .leading
        return .asymmetric(
            insertion: .move(edge: navigationEdge).combined(with: .opacity),
            removal: .move(edge: removalEdge).combined(with: .opacity)
        )
    }

    private func makeMonthModel() -> MonthChartModel {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let month = displayedMonth
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: month) ?? month
        let dateFormatter = ISO8601DateFormatter()

        var dayRepoCounts: [Date: [String: Int]] = [:]
        var repoTotals: [String: Int] = [:]

        for repoData in viewModel.contributionsByMonth[month] ?? [] {
            let repoName = "\(repoData.repository.owner.login)/\(repoData.repository.name)"
            for contribution in repoData.contributions.nodes {
                guard let date = dateFormatter.date(from: contribution.occurredAt) else { continue }
                let day = calendar.startOfDay(for: date)
                guard day >= month, day < nextMonth else { continue }
                dayRepoCounts[day, default: [:]][repoName, default: 0] += contribution.commitCount
                repoTotals[repoName, default: 0] += contribution.commitCount
            }
        }

        // Top repositories keep their own color; the rest are grouped as "Other"
        let ranked = repoTotals.sorted { $0.value != $1.value ? $0.value > $1.value : $0.key < $1.key }
        let namedCount = ranked.count > 6 ? 5 : ranked.count
        let namedRepos = ranked.prefix(namedCount).map(\.key)
        let colors = RepoColors.assign(namedRepos)

        var legend = namedRepos.map { RepoLegendItem(name: $0, color: colors[$0] ?? .gray, commits: repoTotals[$0] ?? 0) }
        let otherTotal = ranked.dropFirst(namedCount).reduce(0) { $0 + $1.value }
        if otherTotal > 0 {
            legend.append(RepoLegendItem(name: otherRepoName, color: .gray, commits: otherTotal))
        }

        var days: [StackedCommitData] = []
        var futureDays: [Date] = []
        var day = month
        while day < nextMonth {
            if day > today {
                futureDays.append(day)
            } else {
                var grouped: [String: Int] = [:]
                for (repoName, count) in dayRepoCounts[day] ?? [:] {
                    grouped[colors[repoName] != nil ? repoName : otherRepoName, default: 0] += count
                }
                let repoCommits = legend.compactMap { item in
                    grouped[item.name].map { RepoCommit(repoName: item.name, count: $0, color: item.color) }
                }
                days.append(StackedCommitData(date: day, repoCommits: repoCommits))
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }

        return MonthChartModel(month: month, nextMonth: nextMonth, today: today, days: days, futureDays: futureDays, legend: legend)
    }

    /// Midday of days 1, 8, 15, 22 and 29 so labels sit under their bars
    private func weekAxisDates(_ model: MonthChartModel) -> [Date] {
        let calendar = Calendar.current
        return stride(from: 0, to: 29, by: 7).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: model.month), day < model.nextMonth else { return nil }
            return day.addingTimeInterval(12 * 60 * 60)
        }
    }

    private func day(at location: CGPoint, proxy: ChartProxy, geometry: GeometryProxy, model: MonthChartModel) -> Date? {
        let origin = geometry[proxy.plotAreaFrame].origin
        guard let date: Date = proxy.value(atX: location.x - origin.x) else { return nil }
        let day = Calendar.current.startOfDay(for: date)
        guard day >= model.month, day < model.nextMonth, day <= model.today else { return nil }
        return day
    }

    private func barOpacity(date: Date, repoName: String) -> Double {
        if let focusedRepo, focusedRepo != repoName { return 0.25 }
        if let selectedDate, selectedDate != date { return 0.4 }
        return 1
    }

    private func shortRepoName(_ repoName: String) -> String {
        repoName.split(separator: "/").last.map(String.init) ?? repoName
    }

    private var currentStreak: Int {
        // Use allContributionDays (full year) so the streak is not capped by the menubar display window
        var days = viewModel.allContributionDays[...]
        // Today is still in progress, so no contributions yet doesn't break the streak
        if let today = days.last, today.contributionCount == 0 {
            days = days.dropLast()
        }

        var streak = 0
        for day in days.reversed() {
            if day.contributionCount > 0 {
                streak += 1
            } else {
                break
            }
        }
        return streak
    }

    private var bestStreak: Int {
        var best = 0
        var run = 0
        for day in viewModel.allContributionDays {
            run = day.contributionCount > 0 ? run + 1 : 0
            best = max(best, run)
        }
        return best
    }

    private var hasContributedToday: Bool {
        (viewModel.allContributionDays.last?.contributionCount ?? 0) > 0
    }

    private var isStreakMilestone: Bool {
        streakMilestones.contains(currentStreak)
    }

    private var streakMessage: (text: String, symbol: String, tint: Color)? {
        guard !viewModel.allContributionDays.isEmpty else { return nil }
        if isStreakMilestone {
            return ("\(currentStreak)-day milestone!", "star.fill", .orange)
        }
        if hasContributedToday {
            return ("Contributed today", "checkmark.circle.fill", .green)
        }
        if currentStreak > 0 {
            return ("Contribute today to keep it", "clock", .secondary)
        }
        return ("Contribute today to start one", "sparkles", .secondary)
    }

    // MARK: - Actions

    private func fetchChartData() {
        viewModel.getContributionsByRepository(monthStart: displayedMonth)
    }

    private func navigate(to offset: Int) {
        let target = min(max(offset, 0), maxMonthsBack)
        guard target != monthOffset else { return }
        // Set the direction first so the outgoing month uses the matching transition
        navigationEdge = target > monthOffset ? .leading : .trailing
        DispatchQueue.main.async {
            withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.35, dampingFraction: 0.9)) {
                monthOffset = target
            }
        }
    }

    private func celebrateMilestoneIfNeeded() {
        guard isStreakMilestone, !reduceMotion else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.35)) {
            isCelebrating = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                isCelebrating = false
            }
        }
    }

    private func openDayOnGitHub(_ date: Date) {
        let username = Defaults[.githubUsername]
        guard !username.isEmpty else { return }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let day = formatter.string(from: date)
        if let url = URL(string: "https://github.com/\(username)?tab=overview&from=\(day)&to=\(day)") {
            NSWorkspace.shared.open(url)
        }
    }

    private func openSettings() {
        isShowingSettings = true
    }
}

// MARK: - Repository Colors

private enum RepoColors {
    static let palette: [Color] = [
        .blue, .green, .orange, .purple, .pink,
        .teal, .indigo, .mint, .red, .yellow
    ]

    /// Picks each repository's color from a hash of its name so it stays the same across months.
    /// Collisions move to the next free color.
    static func assign(_ repoNames: [String]) -> [String: Color] {
        var used = Set<Int>()
        var result: [String: Color] = [:]
        for repoName in repoNames.prefix(palette.count) {
            var index = stableHash(repoName) % palette.count
            while used.contains(index) {
                index = (index + 1) % palette.count
            }
            used.insert(index)
            result[repoName] = palette[index]
        }
        return result
    }

    // djb2; String.hashValue is randomized per launch
    private static func stableHash(_ string: String) -> Int {
        var hash: UInt64 = 5381
        for byte in string.utf8 {
            hash = (hash &* 33) &+ UInt64(byte)
        }
        return Int(hash % UInt64(Int.max))
    }
}

// MARK: - VoiceOver Chart Description

private struct MonthChartDescriptor: AXChartDescriptorRepresentable {
    let model: MonthChartModel

    func makeChartDescriptor() -> AXChartDescriptor {
        let labels = model.days.map { $0.date.formatted(.dateTime.month().day()) }
        let xAxis = AXCategoricalDataAxisDescriptor(title: "Day", categoryOrder: labels)
        let yAxis = AXNumericDataAxisDescriptor(
            title: "Commits",
            range: 0...Double(max(model.maxDailyCommits, 1)),
            gridlinePositions: []
        ) { value in "\(Int(value)) commits" }

        let dataPoints = zip(model.days, labels).map { day, label in
            AXDataPoint(
                x: label,
                y: Double(day.total),
                label: day.repoCommits.map { "\($0.repoName) \($0.count)" }.joined(separator: ", ")
            )
        }
        let series = AXDataSeriesDescriptor(name: "Commits", isContinuous: false, dataPoints: dataPoints)

        return AXChartDescriptor(
            title: "Commits in \(model.title)",
            summary: "\(model.totalCommits) commits, \(String(format: "%.1f", model.average)) per day on average",
            xAxis: xAxis,
            yAxis: yAxis,
            additionalAxes: [],
            series: [series]
        )
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
