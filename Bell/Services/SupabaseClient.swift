import Foundation

struct BellEnvironment {
    static let supabaseURL = URL(string: "https://waqmvnskumybqjziypdw.supabase.co")!
    static var publishableKey: String {
        Bundle.main.object(forInfoDictionaryKey: "SUPABASE_PUBLISHABLE_KEY") as? String ?? ""
    }
}

actor SupabaseClient {
    static let shared = SupabaseClient()

    func request(path: String, method: String = "GET", body: Data? = nil, accessToken: String? = nil) async throws -> Data {
        var request = URLRequest(url: BellEnvironment.supabaseURL.appending(path: "/rest/v1/\(path)"))
        request.httpMethod = method
        request.httpBody = body
        request.setValue(BellEnvironment.publishableKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let accessToken { request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization") }
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else { throw URLError(.badServerResponse) }
        return data
    }
}
