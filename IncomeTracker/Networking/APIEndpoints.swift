import Foundation

enum APIEndpoint {
    case health
    case dashboard(period: String)
    case transactions(period: String, source: String?, status: String?, search: String?, page: Int)
    case newTransactions(since: String)
    case workers
    case workerDetail(userId: Int)
    case createWorker
    case updateWorker(userId: Int)
    case deleteWorker(userId: Int)
    case workerPayment(userId: Int, period: String)
    case screenshot(filename: String)
    case telegramStats
    case breaks(userId: Int?)

    var path: String {
        switch self {
        case .health:
            return "/api/health"
        case .dashboard:
            return "/api/dashboard"
        case .transactions:
            return "/api/transactions"
        case .newTransactions:
            return "/api/transactions/new"
        case .workers, .createWorker:
            return "/api/workers"
        case .workerDetail(let userId), .updateWorker(let userId), .deleteWorker(let userId):
            return "/api/workers/\(userId)"
        case .workerPayment(let userId, _):
            return "/api/workers/\(userId)/payment"
        case .screenshot(let filename):
            return "/api/screenshots/\(filename)"
        case .telegramStats:
            return "/api/telegram-stats"
        case .breaks:
            return "/api/breaks"
        }
    }

    var queryItems: [URLQueryItem]? {
        switch self {
        case .dashboard(let period):
            return [URLQueryItem(name: "period", value: period)]
        case .transactions(let period, let source, let status, let search, let page):
            var items = [
                URLQueryItem(name: "period", value: period),
                URLQueryItem(name: "page", value: "\(page)"),
            ]
            if let source { items.append(URLQueryItem(name: "source", value: source)) }
            if let status { items.append(URLQueryItem(name: "status", value: status)) }
            if let search, !search.isEmpty { items.append(URLQueryItem(name: "search", value: search)) }
            return items
        case .newTransactions(let since):
            return [URLQueryItem(name: "since", value: since)]
        case .workerPayment(_, let period):
            return [URLQueryItem(name: "period", value: period)]
        case .breaks(let userId):
            if let userId { return [URLQueryItem(name: "user_id", value: "\(userId)")] }
            return nil
        default:
            return nil
        }
    }

    var method: String {
        switch self {
        case .createWorker: return "POST"
        case .updateWorker: return "PUT"
        case .deleteWorker: return "DELETE"
        default: return "GET"
        }
    }
}
