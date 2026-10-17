//
//  ViewModel.swift
//  streak-bar
//
//  Created by Pavel Makhov on 2023-08-31.
//

import Foundation
import Defaults

enum LoadingState: Equatable {
    case idle
    case loading
    case success
    case error(String)
}

class ViewModel: ObservableObject {

    private var client = Client()

    @Published var contributions: [ContributionWeek] = []
    @Published var allContributionDays: [ContributionDay] = [] // Full year window for streak calc
    @Published var contributionsByMonth: [Date: [CommitContributionsByRepository]] = [:] // Keyed by first day of month
    @Published var chartMonth: Date = Calendar.current.startOfMonth(for: Date())
    @Published var loadingState: LoadingState = .idle
    @Published var chartLoadingState: LoadingState = .idle
    @Published var chartErrorRequiresSignIn = false
    @Published var lastUpdateTime: Date?
    @Published var avatarUrl: String?
    @Published var userDisplayName: String?
    
    init() {
    }
    
    // Fetches a full year, which covers both the menubar window (max 50 weeks) and the streak calculation
    func getContributions() {
        if contributions.isEmpty {
            loadingState = .loading
        }

        let yearAgo = getDateNDaysBeforeToday(n: 365)
        client.getContributions(from: yearAgo) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let payload):
                    self.contributions = payload.weeks
                    self.allContributionDays = payload.weeks.flatMap { $0.contributionDays }
                    self.avatarUrl = payload.avatarUrl
                    self.userDisplayName = payload.displayName
                    Defaults[.githubUsername] = payload.login
                    self.loadingState = .success
                    self.lastUpdateTime = Date()
                case .failure(let error):
                    self.contributions = []
                    self.loadingState = .error(error.userMessage)
                }
            }
        }
    }

    // Clears everything tied to the signed-in account
    func resetAccountData() {
        contributions = []
        allContributionDays = []
        contributionsByMonth = [:]
        avatarUrl = nil
        userDisplayName = nil
        lastUpdateTime = nil
        loadingState = .idle
        chartLoadingState = .idle
        chartErrorRequiresSignIn = false
    }
    
    func getDateNDaysBeforeToday(n: Int) -> Date {
        let calendar = Calendar.current
        let currentDate = Date()
        let dateComponent = DateComponents(day: -n)
        
        return calendar.date(byAdding: dateComponent, to: currentDate)!
    }
    
    // For chart - fetches repository contributions for one calendar month
    func getContributionsByRepository(monthStart: Date = Calendar.current.startOfMonth(for: Date())) {
        let calendar = Calendar.current
        let month = calendar.startOfMonth(for: monthStart)
        guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: month) else { return }

        chartMonth = month
        chartLoadingState = .loading

        let toDate = min(nextMonth.addingTimeInterval(-1), Date())

        client.getContributionsByRepository(from: month, to: toDate, maxRepos: 10) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let repoContributions):
                    self.contributionsByMonth[month] = repoContributions
                    if self.chartMonth == month {
                        self.chartErrorRequiresSignIn = false
                        self.chartLoadingState = .success
                    }
                    self.lastUpdateTime = Date()
                case .failure(let error):
                    if self.chartMonth == month {
                        self.chartErrorRequiresSignIn = error.requiresSignIn
                        self.chartLoadingState = .error(error.userMessage)
                    }
                    if error.requiresSignIn {
                        self.contributionsByMonth = [:]
                    }
                }
            }
        }
    }
}

extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        self.date(from: dateComponents([.year, .month], from: date)) ?? startOfDay(for: date)
    }
}
