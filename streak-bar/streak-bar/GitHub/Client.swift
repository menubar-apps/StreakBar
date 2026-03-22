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

    func getContributions(from: Date, completion: @escaping (Result<[ContributionWeek], ClientError>) -> Void) {

        // Validate token and username
        guard !githubToken.isEmpty else {
            completion(.failure(.missingToken))
            return
        }
        
        let username = Defaults[.githubUsername]
        guard !username.isEmpty else {
            completion(.failure(.missingUsername))
            return
        }
        
        let headers: HTTPHeaders = [
            .authorization(bearerToken: githubToken),
            .accept("application/json")
        ]
        
        let graphQlQuery = """
        query($userName:String!, $from: DateTime, $to: DateTime) {
          user(login: $userName){
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
        variables["userName"] = username
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
                    completion(.success(resp.data.user.contributionsCollection.contributionCalendar.weeks))
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
    
    func getContributionsByRepository(from: Date, maxRepos: Int = 10, completion: @escaping (Result<[CommitContributionsByRepository], ClientError>) -> Void) {
        
        // Validate token and username
        guard !githubToken.isEmpty else {
            completion(.failure(.missingToken))
            return
        }
        
        let username = Defaults[.githubUsername]
        guard !username.isEmpty else {
            completion(.failure(.missingUsername))
            return
        }
        
        let headers: HTTPHeaders = [
            .authorization(bearerToken: githubToken),
            .accept("application/json")
        ]
        
        let graphQlQuery = """
        query($userName:String!, $from: DateTime, $to: DateTime, $maxRepos: Int!) {
          user(login: $userName){
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
        variables["userName"] = username
        variables["from"] = formatDateToCustomString(from)
        variables["to"] = formatDateToCustomString(.now)
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
                    completion(.success(resp.data.user.contributionsCollection.commitContributionsByRepository))
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
    case missingUsername
    case unauthorized
    case networkError(String)
    case invalidResponse
    case unexpected(message: String?)
    
    var userMessage: String {
        switch self {
        case .missingToken:
            return "GitHub token is not configured. Please add your token in Settings."
        case .missingUsername:
            return "GitHub username is not configured. Please add your username in Settings."
        case .unauthorized:
            return "GitHub authentication failed. Please check your token in Settings."
        case .networkError(let message):
            return "Network error: \(message)"
        case .invalidResponse:
            return "Invalid response from GitHub. Please try again."
        case .unexpected(let message):
            return message ?? "An unexpected error occurred."
        }
    }
}
