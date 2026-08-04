import Foundation

struct BellAuthSession: Decodable {
    let accessToken: String
    let refreshToken: String?
    let userID: UUID

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case user
    }

    private enum UserKeys: String, CodingKey { case id }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        accessToken = try container.decode(String.self, forKey: .accessToken)
        refreshToken = try container.decodeIfPresent(String.self, forKey: .refreshToken)
        let userContainer = try container.nestedContainer(keyedBy: UserKeys.self, forKey: .user)
        userID = try userContainer.decode(UUID.self, forKey: .id)
    }
}

enum BellAuthError: LocalizedError {
    case invalidPhone
    case invalidCode
    case server(String)

    var errorDescription: String? {
        switch self {
        case .invalidPhone: return "Please enter a complete phone number."
        case .invalidCode: return "Please enter the six-digit code from the text message."
        case .server(let message): return message
        }
    }
}

actor AuthService {
    static let shared = AuthService()
    private let decoder = JSONDecoder()

    func sendSMSCode(phone: String) async throws {
        let normalized = Self.normalizeUSPhone(phone)
        guard normalized.count == 12 else { throw BellAuthError.invalidPhone }
        _ = try await authRequest(
            path: "otp",
            body: ["phone": normalized, "create_user": true, "channel": "sms"]
        )
    }

    func verifySMSCode(phone: String, code: String) async throws -> BellAuthSession {
        let normalized = Self.normalizeUSPhone(phone)
        let digits = code.filter(\.isNumber)
        guard digits.count == 6 else { throw BellAuthError.invalidCode }
        let data = try await authRequest(
            path: "verify",
            body: ["phone": normalized, "token": digits, "type": "sms"]
        )
        return try decoder.decode(BellAuthSession.self, from: data)
    }

    func saveOnboarding(
        session: BellAuthSession,
        phone: String,
        firstName: String,
        lastName: String,
        address: String,
        city: String,
        textScale: Double,
        readAloud: Bool,
        trustedName: String,
        trustedRelationship: String,
        trustedPhone: String,
        canViewActivity: Bool
    ) async throws {
        let profile: [String: Any] = [
            "id": session.userID.uuidString,
            "first_name": firstName,
            "last_name": lastName,
            "phone": Self.normalizeUSPhone(phone),
            "address": address,
            "city": city,
            "text_scale": textScale,
            "read_aloud": readAloud,
            "onboarding_completed": true
        ]

        try await restRequest(
            path: "profiles?on_conflict=id",
            method: "POST",
            accessToken: session.accessToken,
            body: profile,
            prefer: "resolution=merge-duplicates,return=minimal"
        )

        if !trustedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let contact: [String: Any] = [
                "user_id": session.userID.uuidString,
                "name": trustedName,
                "relationship": trustedRelationship,
                "phone": Self.normalizeUSPhone(trustedPhone),
                "can_view_activity": canViewActivity
            ]
            try await restRequest(
                path: "family_members",
                method: "POST",
                accessToken: session.accessToken,
                body: contact,
                prefer: "return=minimal"
            )
        }
    }

    private func authRequest(path: String, body: [String: Any]) async throws -> Data {
        var request = URLRequest(url: BellEnvironment.supabaseURL.appending(path: "/auth/v1/\(path)"))
        request.httpMethod = "POST"
        request.setValue(BellEnvironment.publishableKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return try await execute(request)
    }

    private func restRequest(
        path: String,
        method: String,
        accessToken: String,
        body: [String: Any],
        prefer: String
    ) async throws {
        var request = URLRequest(url: BellEnvironment.supabaseURL.appending(path: "/rest/v1/\(path)"))
        request.httpMethod = method
        request.setValue(BellEnvironment.publishableKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(prefer, forHTTPHeaderField: "Prefer")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        _ = try await execute(request)
    }

    private func execute(_ request: URLRequest) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw BellAuthError.server("Bell could not reach the server.")
        }
        guard 200..<300 ~= http.statusCode else {
            let payload = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            let message = payload?["msg"] as? String
                ?? payload?["message"] as? String
                ?? payload?["error_description"] as? String
                ?? "Bell could not complete that step. Please try again."
            throw BellAuthError.server(message)
        }
        return data
    }

    static func normalizeUSPhone(_ input: String) -> String {
        let digits = input.filter(\.isNumber)
        if digits.count == 10 { return "+1\(digits)" }
        if digits.count == 11 && digits.first == "1" { return "+\(digits)" }
        return input.hasPrefix("+") ? "+\(digits)" : digits
    }
}
