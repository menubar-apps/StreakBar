//
//  ViewModel.swift
//  streak-bar
//
//  Created by Pavel Makhov on 2023-08-31.
//

import Foundation
import Defaults

class ViewModel: ObservableObject {
    @Default(.daysBefore) var daysBefore
    @Default(.viewMode) var viewMode

    private var client = Client()

    @Published var contributions: [ContributionWeek] = []
    
    func getContributions() {
        let multiplier = viewMode == .week ? 7 : 1
        
        let fromDate = getDateNDaysBeforeToday(n: daysBefore * multiplier)
        
        client.getContributions(from: fromDate) { result in
            switch result {
            case .success(let contributionWeeks):
                self.contributions = contributionWeeks
            case .failure(_):
                self.contributions = [ContributionWeek(contributionDays: [])]
            }
        }
    }
    
    func getDateNDaysBeforeToday(n: Int) -> Date {
        let calendar = Calendar.current
        let currentDate = Date()
        let dateComponent = DateComponents(day: -n)
        
        return calendar.date(byAdding: dateComponent, to: currentDate)!
    }
}
