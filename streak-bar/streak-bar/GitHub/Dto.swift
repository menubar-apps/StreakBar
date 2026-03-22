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
    let contributionLevel: ContributionLevel
    
    enum CodingKeys: String, CodingKey {
        case contributionCount
        case date
        case color
        case contributionLevel
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

enum ContributionLevel: String, Codable {
    case FIRST_QUARTILE
    case SECOND_QUARTILE
    case THIRD_QUARTILE
    case FOURTH_QUARTILE
    case NONE
}

// MARK: - Repository-level Contributions

struct Repository: Codable, Hashable {
    let name: String
    let owner: Owner
    
    enum CodingKeys: String, CodingKey {
        case name
        case owner
    }
}

struct Owner: Codable, Hashable {
    let login: String
    
    enum CodingKeys: String, CodingKey {
        case login
    }
}

struct CommitContribution: Codable, Hashable {
    let commitCount: Int
    let occurredAt: String
    
    enum CodingKeys: String, CodingKey {
        case commitCount
        case occurredAt
    }
}

struct CommitContributions: Codable, Hashable {
    let nodes: [CommitContribution]
    
    enum CodingKeys: String, CodingKey {
        case nodes
    }
}

struct CommitContributionsByRepository: Codable, Hashable {
    let repository: Repository
    let contributions: CommitContributions
    
    enum CodingKeys: String, CodingKey {
        case repository
        case contributions
    }
}

struct ContributionsCollectionDetailed: Codable {
    let commitContributionsByRepository: [CommitContributionsByRepository]
    
    enum CodingKeys: String, CodingKey {
        case commitContributionsByRepository
    }
}

struct UserDetailed: Codable {
    let contributionsCollection: ContributionsCollectionDetailed
    
    enum CodingKeys: String, CodingKey {
        case contributionsCollection
    }
}

struct DataResponseDetailed: Codable {
    let user: UserDetailed
    
    enum CodingKeys: String, CodingKey {
        case user
    }
}

struct JsonResponseDetailed: Codable {
    let data: DataResponseDetailed
    
    enum CodingKeys: String, CodingKey {
        case data
    }
}
