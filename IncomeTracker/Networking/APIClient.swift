import Foundation

final class APIClient {
    static let shared = APIClient()

    private static let defaultURL = "https://reggae-adjacent-campbell-miracle.trycloudflare.com"
    private static let hardcodedToken = "changeme"

    private let session: URLSession
    private let decoder: JSONDecoder

    var baseURL: String {
        get {
            let stored = UserDefaults.standard.string(forKey: "serverURL") ?? ""
            return stored.isEmpty ? Self.defaultURL : stored
        }
        set { UserDefaults.standard.set(newValue, forKey: "serverURL") }
    }

    private var apiToken: String { Self.hardcodedToken }

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        session = URLSession(configuration: config)
        decoder = JSONDecoder()
    }

    func request<T: Decodable>(_ endpoint: APIEndpoint, body: Data? = nil) async throws -> T {
        guard !baseURL.isEmpty, var components = URLComponents(string: baseURL + endpoint.path) else {
            throw NetworkError.invalidURL
        }

        components.queryItems = endpoint.queryItems

        guard let url = components.url else {
            throw NetworkError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = endpoint.method
        urlRequest.setValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let body {
            urlRequest.httpBody = body
        }

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch let error as URLError {
            switch error.code {
            case .timedOut:
                throw NetworkError.timeout
            case .notConnectedToInternet, .cannotFindHost, .cannotConnectToHost:
                throw NetworkError.noConnection
            default:
                throw NetworkError.unknown(error)
            }
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.unknown(URLError(.badServerResponse))
        }

        switch httpResponse.statusCode {
        case 200...299:
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw NetworkError.decodingError(error)
            }
        case 401:
            throw NetworkError.unauthorized
        default:
            throw NetworkError.serverError(httpResponse.statusCode)
        }
    }

    func screenshotURL(filename: String) -> URL? {
        var components = URLComponents(string: "\(baseURL)/api/screenshots/\(filename)")
        components?.queryItems = [URLQueryItem(name: "token", value: apiToken)]
        return components?.url
    }

    func checkHealth() async -> Bool {
        struct HealthResponse: Codable { let status: String }
        guard !baseURL.isEmpty else { return false }
        do {
            let _: HealthResponse = try await request(.health)
            return true
        } catch {
            return false
        }
    }
}
