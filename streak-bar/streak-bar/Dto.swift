//
//  Dto.swift
//  streak-bar
//
//  Created by Pavel Makhov on 2023-08-31.
//

import Foundation

struct ContributionDay: Codable, Hashable {
    let contributionCount: Int
    let date: String
    let color: String
    
    enum CodingKeys: String, CodingKey {
        case contributionCount
        case date
        case color
    }
}

struct ContributionWeek: Codable, Hashable {
    let contributionDays: [ContributionDay]
    
    enum CodingKeys: String, CodingKey {
        case contributionDays
    }
    
}

struct ContributionCalendar: Codable {
    let totalContributions: Int
    let weeks: [ContributionWeek]
    
    enum CodingKeys: String, CodingKey {
        case totalContributions
        case weeks
    }
    
}

struct ContributionsCollection: Codable {
    let contributionCalendar: ContributionCalendar
    
    enum CodingKeys: String, CodingKey {
        case contributionCalendar
    }
    
}

struct User: Codable {
    let contributionsCollection: ContributionsCollection
    
    enum CodingKeys: String, CodingKey {
        case contributionsCollection
    }
    
}

struct DataResponse: Codable {
    let user: User
    
    enum CodingKeys: String, CodingKey {
        case user
    }
    
}

struct JsonResponse: Codable {
    let data: DataResponse
    
    enum CodingKeys: String, CodingKey {
        case data
    }
    
}
