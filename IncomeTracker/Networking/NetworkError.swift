import Foundation

enum NetworkError: Error, LocalizedError {
    case unauthorized
    case serverError(Int)
    case noConnection
    case decodingError(Error)
    case timeout
    case invalidURL
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Invalid API token. Check Settings."
        case .serverError(let code):
            return "Server error (\(code)). Try again later."
        case .noConnection:
            return "No connection to server."
        case .decodingError:
            return "Failed to parse server response."
        case .timeout:
            return "Request timed out."
        case .invalidURL:
            return "Invalid server URL."
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}
