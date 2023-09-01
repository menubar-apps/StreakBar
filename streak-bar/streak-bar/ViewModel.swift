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

    
    private var client = Client()

    @Published var contributions: [ContributionWeek] = []
    
    func getContributions() {
        let fromDate = getDateNDaysBeforeToday(n: daysBefore)
        
        client.getContributions(from: fromDate) { result in
            switch result {
            case .success(let contributionWeeks):
                self.contributions = contributionWeeks
            case .failure(_):
                NSLog("vse ochen ploho")
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
