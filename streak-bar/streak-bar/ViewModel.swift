//
//  ViewModel.swift
//  streak-bar
//
//  Created by Pavel Makhov on 2023-08-31.
//

import Foundation
import Defaults

class ViewModel: ObservableObject {

    private var client = Client()

    @Published var contributions: [ContributionWeek] = []
    
    init() {
        print("ViewModel init")
    }
    
    func getContributions() {
        let multiplier = Defaults[.viewMode] == .week ? 7 : 1
        
        let fromDate = getDateNDaysBeforeToday(n: Defaults[.daysBefore] * multiplier)
        
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
