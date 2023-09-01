//
//  Client.swift
//  streak-bar
//
//  Created by Pavel Makhov on 2023-08-31.
//

import Foundation
import Alamofire

public class Client {
    
    let githubUsername = "streetturtle"
    @FromKeychain(.githubToken) var githubToken

    func getContributions(from: Date, completion: @escaping (Result<[ContributionWeek], ClientError>) -> Void) {

//        if (githubUsername.isEmpty || githubToken == "") {
//            completion(.failure(.tokenNotSet))
//            return
//        }
        
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
                  }
                }
              }
            }
          }
        }
        """
        
        var variables: [String: Any] = [:]

        // Adding values to the dictionary
        variables["userName"] = "streetturtle"
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
                    print(error)
                    completion(.failure(.unexpected(message: error.localizedDescription)))
                }
            }
    }
    
    func formatDateToCustomString(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return dateFormatter.string(from: date)
    }
}

enum ClientError: Error {
    case unexpected(message: String?)
    case tokenNotSet
}
