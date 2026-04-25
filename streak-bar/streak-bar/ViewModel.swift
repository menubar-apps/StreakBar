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
    @Published var contributionsByRepo: [CommitContributionsByRepository] = []
    @Published var loadingState: LoadingState = .idle
    @Published var chartLoadingState: LoadingState = .idle
    @Published var lastUpdateTime: Date?
    @Published var avatarUrl: String?
    @Published var userDisplayName: String?
    
    init() {
    }
    
    // For menubar - fetches based on user settings
    func getContributions() {
        loadingState = .loading
        
        let multiplier = Defaults[.viewMode] == .week ? 7 : 1
        let menubarDays = Defaults[.daysBefore] * multiplier
        
        let fromDate = getDateNDaysBeforeToday(n: menubarDays)
        
        client.getContributions(from: fromDate) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let payload):
                    self.contributions = payload.weeks
                    self.avatarUrl = payload.avatarUrl
                    self.userDisplayName = payload.displayName
                    self.loadingState = .success
                    self.lastUpdateTime = Date()
                case .failure(let error):
                    self.contributions = [ContributionWeek(contributionDays: [])]
                    self.loadingState = .error(error.userMessage)
                }
            }
        }
        
        // Always fetch a full year separately to power accurate streak calculation
        let yearAgo = getDateNDaysBeforeToday(n: 365)
        client.getContributions(from: yearAgo) { result in
            DispatchQueue.main.async {
                if case .success(let payload) = result {
                    self.allContributionDays = payload.weeks.flatMap { $0.contributionDays }
                }
            }
        }
    }
    
    func getDateNDaysBeforeToday(n: Int) -> Date {
        let calendar = Calendar.current
        let currentDate = Date()
        let dateComponent = DateComponents(day: -n)
        
        return calendar.date(byAdding: dateComponent, to: currentDate)!
    }
    
    // For chart - fetches specific number of days for repository contributions
    func getContributionsByRepository(days: Int = 21) {
        chartLoadingState = .loading
        
        let fromDate = getDateNDaysBeforeToday(n: days)
        
        client.getContributionsByRepository(from: fromDate, maxRepos: 10) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let repoContributions):
                    self.contributionsByRepo = repoContributions
                    self.chartLoadingState = .success
                    self.lastUpdateTime = Date()
                case .failure(let error):
                    self.contributionsByRepo = []
                    self.chartLoadingState = .error(error.userMessage)
                }
            }
        }
    }
}
