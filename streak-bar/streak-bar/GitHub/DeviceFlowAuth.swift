//
//  DeviceFlowAuth.swift
//  streak-bar
//

import Foundation

@MainActor
final class DeviceFlowAuth: ObservableObject {

    /// Public client ID of the StreakBar OAuth App (Device Flow enabled). Empty disables "Sign in with GitHub".
    nonisolated static let clientId = "Ov23liK6l3B3PUQKyaTJ"
    static var isConfigured: Bool { !clientId.isEmpty }
    static var manageAccessUrl: URL? {
        isConfigured ? URL(string: "https://github.com/settings/connections/applications/\(clientId)") : nil
    }

    static let scope = "read:user"
    static let deviceCodeUrl = URL(string: "https://github.com/login/device/code")!
    static let accessTokenUrl = URL(string: "https://github.com/login/oauth/access_token")!
    static let grantType = "urn:ietf:params:oauth:grant-type:device_code"

    enum State: Equatable {
        case idle
        case requestingCode
        case waitingForUser(userCode: String, verificationUri: URL)
        case signedIn
        case expired
        case denied
        case failed(String)
    }

    typealias Transport = (URLRequest) async throws -> Foundation.Data
    typealias Sleep = (UInt64) async throws -> Void

    @Published private(set) var state: State = .idle

    private let clientId: String
    private let transport: Transport
    private let sleep: Sleep
    private let onToken: @MainActor (String) -> Void
    private var task: Task<Void, Never>?

    init(
        clientId: String = DeviceFlowAuth.clientId,
        transport: @escaping Transport = { try await URLSession.shared.data(for: $0).0 },
        sleep: @escaping Sleep = { try await Task.sleep(nanoseconds: $0) },
        onToken: @escaping @MainActor (String) -> Void = { token in
            let keychainToken = FromKeychain(.githubToken)
            keychainToken.wrappedValue = token
        }
    ) {
        self.clientId = clientId
        self.transport = transport
        self.sleep = sleep
        self.onToken = onToken
    }

    func start() {
        task?.cancel()
        state = .requestingCode
        task = Task { await run() }
    }

    func cancel() {
        task?.cancel()
        task = nil
        state = .idle
    }

    private func run() async {
        let code: DeviceCodeResponse
        do {
            let data = try await transport(Self.formRequest(Self.deviceCodeUrl, ["client_id": clientId, "scope": Self.scope]))
            code = try Self.parseDeviceCodeResponse(data)
        } catch {
            if !Task.isCancelled { state = .failed(error.localizedDescription) }
            return
        }
        guard !Task.isCancelled else { return }

        state = .waitingForUser(userCode: code.userCode, verificationUri: code.verificationUri)

        var interval = max(code.interval, 1)
        let deadline = Date().addingTimeInterval(TimeInterval(code.expiresIn))
        let pollRequest = Self.formRequest(Self.accessTokenUrl, [
            "client_id": clientId,
            "device_code": code.deviceCode,
            "grant_type": Self.grantType
        ])

        while !Task.isCancelled {
            if Date() >= deadline {
                state = .expired
                return
            }
            do { try await sleep(UInt64(interval) * 1_000_000_000) } catch { return }

            // Network errors are treated as transient; polling continues until the code expires.
            guard let data = try? await transport(pollRequest), !Task.isCancelled else { continue }

            switch Self.parsePollResponse(data) {
            case .token(let token):
                onToken(token)
                state = .signedIn
                return
            case .pending:
                continue
            case .slowDown(let suggested):
                interval = Self.nextInterval(current: interval, suggested: suggested)
            case .expired:
                state = .expired
                return
            case .denied:
                state = .denied
                return
            case .failure(let message):
                state = .failed(message)
                return
            }
        }
    }

    // MARK: - Request / response handling

    nonisolated static func formRequest(_ url: URL, _ fields: [String: String]) -> URLRequest {
        var components = URLComponents()
        components.queryItems = fields.sorted { $0.key < $1.key }.map { URLQueryItem(name: $0.key, value: $0.value) }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = components.percentEncodedQuery?.data(using: .utf8)
        return request
    }

    nonisolated static func parseDeviceCodeResponse(_ data: Foundation.Data) throws -> DeviceCodeResponse {
        if let code = try? JSONDecoder().decode(DeviceCodeResponse.self, from: data) {
            return code
        }
        let error = try? JSONDecoder().decode(OAuthErrorResponse.self, from: data)
        throw DeviceFlowError.github(error?.errorDescription ?? error?.error ?? "Unexpected response from GitHub")
    }

    nonisolated static func parsePollResponse(_ data: Foundation.Data) -> DeviceTokenPollResult {
        guard let response = try? JSONDecoder().decode(OAuthErrorResponse.self, from: data) else {
            return .failure("Unexpected response from GitHub")
        }
        if let token = response.accessToken, !token.isEmpty {
            return .token(token)
        }
        switch response.error {
        case "authorization_pending": return .pending
        case "slow_down": return .slowDown(interval: response.interval)
        case "expired_token": return .expired
        case "access_denied": return .denied
        default: return .failure(response.errorDescription ?? response.error ?? "Unexpected response from GitHub")
        }
    }

    /// GitHub asks for at least 5 more seconds after `slow_down` and may send the new interval itself.
    nonisolated static func nextInterval(current: Int, suggested: Int?) -> Int {
        max(suggested ?? 0, current + 5)
    }
}

struct DeviceCodeResponse: Decodable, Equatable {
    let deviceCode: String
    let userCode: String
    let verificationUri: URL
    let expiresIn: Int
    let interval: Int

    enum CodingKeys: String, CodingKey {
        case deviceCode = "device_code"
        case userCode = "user_code"
        case verificationUri = "verification_uri"
        case expiresIn = "expires_in"
        case interval
    }
}

enum DeviceTokenPollResult: Equatable {
    case token(String)
    case pending
    case slowDown(interval: Int?)
    case expired
    case denied
    case failure(String)
}

enum DeviceFlowError: LocalizedError {
    case github(String)

    var errorDescription: String? {
        switch self {
        case .github(let message): return message
        }
    }
}

private struct OAuthErrorResponse: Decodable {
    let accessToken: String?
    let error: String?
    let errorDescription: String?
    let interval: Int?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case error
        case errorDescription = "error_description"
        case interval
    }
}

enum AuthMethod: String, CaseIterable, Identifiable {
    case github
    case personalToken

    var id: Self { self }

    /// Tokens issued by "Sign in with GitHub" (OAuth Apps) start with `gho_`; anything else is a personal token.
    static func of(token: String) -> AuthMethod? {
        if token.isEmpty { return nil }
        return token.hasPrefix("gho_") ? .github : .personalToken
    }
}
