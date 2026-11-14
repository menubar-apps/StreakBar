//
//  MockData.swift
//  streak-bar
//

#if DEBUG
import Foundation
import Defaults

/// Generated contributions for screenshots. Enable with the `-mockContributions YES` launch argument.
/// The signed-in user's login, name and avatar still come from GitHub.
enum MockData {

    static var isEnabled: Bool {
        UserDefaults.standard.bool(forKey: "mockContributions")
    }

    private static let calendar = Calendar.current
    private static let streakLength = 24

    private static var repos: [(owner: String, name: String, weight: UInt64)] {
        let login = Defaults[.githubUsername].isEmpty ? "octocat" : Defaults[.githubUsername]
        return [
            ("menubar-apps", "StreakBar", 6),
            ("menubar-apps", "PullBar", 4),
            ("menubar-apps", "ToDoBar", 3),
            (login, "dotfiles", 1),
            (login, "swift-playground", 2)
        ]
    }

    // Same value for the same day, so refreshes and both charts agree
    private static func seed(_ day: Date) -> UInt64 {
        let c = calendar.dateComponents([.year, .month, .day], from: day)
        var x = UInt64((c.year ?? 0) * 10000 + (c.month ?? 0) * 100 + (c.day ?? 0))
        x = (x ^ (x >> 30)) &* 0xbf58476d1ce4e5b9
        x = (x ^ (x >> 27)) &* 0x94d049bb133111eb
        return x ^ (x >> 31)
    }

    static func commitCount(on day: Date) -> Int {
        let today = calendar.startOfDay(for: Date())
        let daysAgo = calendar.dateComponents([.day], from: calendar.startOfDay(for: day), to: today).day ?? 0
        guard daysAgo >= 0 else { return 0 }
        let r = seed(day)
        let weekend = calendar.isDateInWeekend(day)
        if daysAgo < streakLength {
            return 1 + Int((r >> 8) % (weekend ? 4 : 10))
        }
        if Int(r % 100) < (weekend ? 55 : 18) { return 0 }
        return 1 + Int((r >> 8) % (weekend ? 4 : 12))
    }

    private static func level(for count: Int) -> (ContributionLevel, String) {
        switch count {
        case 0: return (.NONE, "#ebedf0")
        case 1...2: return (.FIRST_QUARTILE, "#9be9a8")
        case 3...5: return (.SECOND_QUARTILE, "#40c463")
        case 6...8: return (.THIRD_QUARTILE, "#30a14e")
        default: return (.FOURTH_QUARTILE, "#216e39")
        }
    }

    private static func days(from: Date, to: Date) -> [Date] {
        var result: [Date] = []
        var day = calendar.startOfDay(for: from)
        let end = calendar.startOfDay(for: min(to, Date()))
        while day <= end {
            result.append(day)
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return result
    }

    /// Sunday-aligned weeks, like GitHub's contribution calendar.
    static func weeks(from: Date) -> [ContributionWeek] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"

        var weeks: [ContributionWeek] = []
        var current: [ContributionDay] = []
        for day in days(from: from, to: Date()) {
            if calendar.component(.weekday, from: day) == 1, !current.isEmpty {
                weeks.append(ContributionWeek(contributionDays: current))
                current = []
            }
            let count = commitCount(on: day)
            let (level, color) = level(for: count)
            current.append(ContributionDay(contributionCount: count, date: formatter.string(from: day), color: color, contributionLevel: level))
        }
        if !current.isEmpty {
            weeks.append(ContributionWeek(contributionDays: current))
        }
        return weeks
    }

    /// Splits each day's commits across a few repositories.
    static func repositories(from: Date, to: Date, maxRepos: Int) -> [CommitContributionsByRepository] {
        let repos = repos
        let totalWeight = repos.reduce(0) { $0 + $1.weight }
        let isoFormatter = ISO8601DateFormatter()
        var nodes: [Int: [CommitContribution]] = [:]

        for day in days(from: from, to: to) {
            let count = commitCount(on: day)
            guard count > 0 else { continue }
            var perRepo: [Int: Int] = [:]
            var r = seed(day) >> 16
            for _ in 0..<count {
                var pick = r % totalWeight
                r = (r &* 6364136223846793005) &+ 1442695040888963407
                for (index, repo) in repos.enumerated() {
                    if pick < repo.weight { perRepo[index, default: 0] += 1; break }
                    pick -= repo.weight
                }
            }
            let noon = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: day) ?? day
            for (index, commits) in perRepo {
                nodes[index, default: []].append(CommitContribution(commitCount: commits, occurredAt: isoFormatter.string(from: noon)))
            }
        }

        return nodes
            .map { index, contributions in
                CommitContributionsByRepository(
                    repository: Repository(name: repos[index].name, owner: Owner(login: repos[index].owner)),
                    contributions: CommitContributions(nodes: contributions)
                )
            }
            .sorted { $0.contributions.nodes.reduce(0) { $0 + $1.commitCount } > $1.contributions.nodes.reduce(0) { $0 + $1.commitCount } }
            .prefix(maxRepos)
            .map { $0 }
    }
}
#endif
