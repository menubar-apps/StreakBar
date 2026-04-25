//
//  Dto.swift
//  streak-bar
//
//  Created by Pavel Makhov on 2023-08-31.
//

import Foundation

// MARK: - Shared outer wrappers (generic to avoid duplication)

struct GraphQLResponse<T: Codable>: Codable {
    let data: GraphQLData<T>
}

struct GraphQLData<T: Codable>: Codable {
    let user: T
}

// MARK: - Contribution Calendar (menu bar heat-map)

struct ContributionDay: Codable, Hashable {
    let contributionCount: Int
    let date: String
    let color: String
    let contributionLevel: ContributionLevel
}

struct ContributionWeek: Codable, Hashable {
    let contributionDays: [ContributionDay]
}

struct ContributionCalendar: Codable {
    let totalContributions: Int
    let weeks: [ContributionWeek]
}

struct ContributionsCollection: Codable {
    let contributionCalendar: ContributionCalendar
}

struct UserCalendar: Codable {
    let name: String?
    let avatarUrl: String
    let contributionsCollection: ContributionsCollection
}

// Convenience typealiases
typealias JsonResponse = GraphQLResponse<UserCalendar>

enum ContributionLevel: String, Codable {
    case FIRST_QUARTILE
    case SECOND_QUARTILE
    case THIRD_QUARTILE
    case FOURTH_QUARTILE
    case NONE
}

// MARK: - Repository-level Contributions (popover chart)

struct Repository: Codable, Hashable {
    let name: String
    let owner: Owner
}

struct Owner: Codable, Hashable {
    let login: String
}

struct CommitContribution: Codable, Hashable {
    let commitCount: Int
    let occurredAt: String
}

struct CommitContributions: Codable, Hashable {
    let nodes: [CommitContribution]
}

struct CommitContributionsByRepository: Codable, Hashable {
    let repository: Repository
    let contributions: CommitContributions
}

struct ContributionsCollectionDetailed: Codable {
    let commitContributionsByRepository: [CommitContributionsByRepository]
}

struct UserDetailed: Codable {
    let contributionsCollection: ContributionsCollectionDetailed
}

// Convenience typealiases
typealias JsonResponseDetailed = GraphQLResponse<UserDetailed>
