//
//  Client.swift
//  streak-bar
//
//  Created by Pavel Makhov on 2023-08-31.
//

import Foundation
import Alamofire
import Defaults

public class Client {
    
    @FromKeychain(.githubToken) var githubToken

    func getContributions(from: Date, completion: @escaping (Result<(weeks: [ContributionWeek], avatarUrl: String, displayName: String?, login: String), ClientError>) -> Void) {

        // Validate token
        guard !githubToken.isEmpty else {
            completion(.failure(.missingToken))
            return
        }

        let headers: HTTPHeaders = [
            .authorization(bearerToken: githubToken),
            .accept("application/json")
        ]

        let graphQlQuery = """
        query($from: DateTime, $to: DateTime) {
          viewer {
            login
            name
            avatarUrl
            contributionsCollection(from: $from, to: $to) {
              contributionCalendar {
                totalContributions
                weeks {
                  contributionDays {
                    contributionCount
                    date
                    color
                    contributionLevel
                  }
                }
              }
            }
          }
        }
        """
        
        var variables: [String: Any] = [:]

        // Adding values to the dictionary
        variables["from"] = formatDateToCustomString(from)
        variables["to"] = formatDateToCustomString(.now)

        
        let parameters = [
            "query": graphQlQuery,
            "variables": variables
        ] as [String: Any]
        
        AF.request("https://api.github.com/graphql", method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
            .validate(statusCode: 200..<300)
            .responseDecodable(of: JsonResponse.self) { response in
                switch response.result {
                case .success(let resp):
                    let user = resp.data.viewer
                    var weeks = user.contributionsCollection.contributionCalendar.weeks
                    #if DEBUG
                    if MockData.isEnabled {
                        weeks = MockData.weeks(from: from)
                    }
                    #endif
                    completion(.success((
                        weeks: weeks,
                        avatarUrl: user.avatarUrl,
                        displayName: user.name,
                        login: user.login
                    )))
                case .failure(let error):
                    // Check for specific error types
                    if let statusCode = response.response?.statusCode {
                        if statusCode == 401 || statusCode == 403 {
                            completion(.failure(.unauthorized))
                            return
                        }
                    }
                    
                    completion(.failure(.networkError(error.localizedDescription)))
                }
            }
    }
    
    func formatDateToCustomString(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return dateFormatter.string(from: date)
    }
    
    func getContributionsByRepository(from: Date, to: Date = .now, maxRepos: Int = 10, completion: @escaping (Result<[CommitContributionsByRepository], ClientError>) -> Void) {
        
        // Validate token
        guard !githubToken.isEmpty else {
            completion(.failure(.missingToken))
            return
        }

        #if DEBUG
        if MockData.isEnabled {
            completion(.success(MockData.repositories(from: from, to: to, maxRepos: maxRepos)))
            return
        }
        #endif

        let headers: HTTPHeaders = [
            .authorization(bearerToken: githubToken),
            .accept("application/json")
        ]

        let graphQlQuery = """
        query($from: DateTime, $to: DateTime, $maxRepos: Int!) {
          viewer {
            contributionsCollection(from: $from, to: $to) {
              commitContributionsByRepository(maxRepositories: $maxRepos) {
                repository {
                  name
                  owner {
                    login
                  }
                }
                contributions(first: 100) {
                  nodes {
                    commitCount
                    occurredAt
                  }
                }
              }
            }
          }
        }
        """
        
        var variables: [String: Any] = [:]
        variables["from"] = formatDateToCustomString(from)
        variables["to"] = formatDateToCustomString(to)
        variables["maxRepos"] = maxRepos
        
        let parameters = [
            "query": graphQlQuery,
            "variables": variables
        ] as [String: Any]
        
        AF.request("https://api.github.com/graphql", method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
            .validate(statusCode: 200..<300)
            .responseDecodable(of: JsonResponseDetailed.self) { response in
                switch response.result {
                case .success(let resp):
                    completion(.success(resp.data.viewer.contributionsCollection.commitContributionsByRepository))
                case .failure(let error):
                    // Check for specific error types
                    if let statusCode = response.response?.statusCode {
                        if statusCode == 401 || statusCode == 403 {
                            completion(.failure(.unauthorized))
                            return
                        }
                    }
                    
                    completion(.failure(.networkError(error.localizedDescription)))
                }
            }
    }
}

enum ClientError: Error {
    case missingToken
    case unauthorized
    case networkError(String)
    case invalidResponse

    var requiresSignIn: Bool {
        switch self {
        case .missingToken, .unauthorized:
            return true
        case .networkError, .invalidResponse:
            return false
        }
    }

    var userMessage: String {
        switch self {
        case .missingToken:
            return "Not signed in to GitHub. Please sign in or add a token in Settings."
        case .unauthorized:
            return "GitHub authentication failed. Please sign in again in Settings."
        case .networkError(let message):
            return "Network error: \(message)"
        case .invalidResponse:
            return "Invalid response from GitHub. Please try again."
        }
    }
}
