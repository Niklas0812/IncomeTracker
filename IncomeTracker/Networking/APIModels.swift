import Foundation

// MARK: - Flexible number-or-string for percent change

/// The backend can return a Double, a String like "no_activity", or null for percent change fields.
enum PercentChangeValue: Codable {
    case number(Double)
    case noActivity
    case none

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .none
            return
        }
        if let d = try? container.decode(Double.self) {
            self = .number(d)
            return
        }
        if let s = try? container.decode(String.self), s == "no_activity" {
            self = .noActivity
            return
        }
        self = .none
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .number(let d): try container.encode(d)
        case .noActivity: try container.encode("no_activity")
        case .none: try container.encodeNil()
        }
    }

    var doubleValue: Double? {
        if case .number(let d) = self { return d }
        return nil
    }

    var isNoActivity: Bool {
        if case .noActivity = self { return true }
        return false
    }
}

// MARK: - Dashboard

struct DashboardResponse: Codable {
    let totalIncome: Double
    let paysafeIncome: Double
    let paypalIncome: Double
    let paysafeChange: PercentChangeValue
    let paypalChange: PercentChangeValue
    let chartData: [ChartDataPointDTO]
    let topWorkers: [TopWorkerDTO]
    let recentTransactions: [TransactionDTO]
    let paysafeSparkline: [Double]
    let paypalSparkline: [Double]
    let paysafeStatus: String
    let paypalStatus: String
    let period: String

    enum CodingKeys: String, CodingKey {
        case totalIncome = "total_income"
        case paysafeIncome = "paysafe_income"
        case paypalIncome = "paypal_income"
        case paysafeChange = "paysafe_change"
        case paypalChange = "paypal_change"
        case chartData = "chart_data"
        case topWorkers = "top_workers"
        case recentTransactions = "recent_transactions"
        case paysafeSparkline = "paysafe_sparkline"
        case paypalSparkline = "paypal_sparkline"
        case paysafeStatus = "paysafe_status"
        case paypalStatus = "paypal_status"
        case period
    }
}

struct ChartDataPointDTO: Codable {
    let label: String
    let date: String
    let paysafe: Double
    let paypal: Double
}

struct TopWorkerDTO: Codable {
    let workerId: Int
    let workerName: String
    let total: Double

    enum CodingKeys: String, CodingKey {
        case workerId = "worker_id"
        case workerName = "worker_name"
        case total
    }
}

// MARK: - Transactions

struct TransactionsResponse: Codable {
    let transactions: [TransactionDTO]
    let page: Int
    let totalPages: Int
    let totalCount: Int
    let totalAmount: Double

    enum CodingKeys: String, CodingKey {
        case transactions, page
        case totalPages = "total_pages"
        case totalCount = "total_count"
        case totalAmount = "total_amount"
    }
}

struct TransactionDTO: Codable {
    let id: String
    let workerId: Int
    let workerName: String
    let source: String
    let amount: Double
    let date: String?
    let status: String
    let reference: String
    let hasScreenshot: Bool
    let screenshotFilename: String?

    enum CodingKeys: String, CodingKey {
        case id
        case workerId = "worker_id"
        case workerName = "worker_name"
        case source, amount, date, status, reference
        case hasScreenshot = "has_screenshot"
        case screenshotFilename = "screenshot_filename"
    }
}

struct NewTransactionsResponse: Codable {
    let transactions: [TransactionDTO]
    let count: Int
    let polledAt: String

    enum CodingKeys: String, CodingKey {
        case transactions, count
        case polledAt = "polled_at"
    }
}

// MARK: - Workers

struct WorkersResponse: Codable {
    let workers: [WorkerDTO]
}

struct WorkerDTO: Codable {
    let id: Int
    let name: String
    let username: String
    let isActive: Bool
    let joinedDate: String?
    let dailyHours: Double?
    let hourlyRate: Double?
    let totalEarnings: Double

    enum CodingKeys: String, CodingKey {
        case id, name, username
        case isActive = "is_active"
        case joinedDate = "joined_date"
        case dailyHours = "daily_hours"
        case hourlyRate = "hourly_rate"
        case totalEarnings = "total_earnings"
    }
}

struct WorkerDetailResponse: Codable {
    let worker: WorkerDetailDTO
    let recentTransactions: [TransactionDTO]
    let chartData: [WorkerChartDataDTO]?
    let period: String?

    enum CodingKeys: String, CodingKey {
        case worker
        case recentTransactions = "recent_transactions"
        case chartData = "chart_data"
        case period
    }
}

struct WorkerChartDataDTO: Codable {
    let date: String
    let label: String
    let amount: Double
}

struct WorkerDetailDTO: Codable {
    let id: Int
    let name: String
    let username: String
    let isActive: Bool
    let joinedDate: String?
    let dailyHours: Double?
    let hourlyRate: Double?
    let totalEarnings: Double
    let transactionCount: Int
    let averagePerTransaction: Double
    let highestTransaction: Double
    let lastTransactionDate: String?

    enum CodingKeys: String, CodingKey {
        case id, name, username
        case isActive = "is_active"
        case joinedDate = "joined_date"
        case dailyHours = "daily_hours"
        case hourlyRate = "hourly_rate"
        case totalEarnings = "total_earnings"
        case transactionCount = "transaction_count"
        case averagePerTransaction = "average_per_transaction"
        case highestTransaction = "highest_transaction"
        case lastTransactionDate = "last_transaction_date"
    }
}

struct PaymentBreakdownResponse: Codable {
    let userId: Int
    let period: String
    let totalEurEarned: Double
    let shiftPay: Double
    let bonus: Double
    let totalPayment: Double
    let transactionCount: Int
    let hourlyRate: Double?
    let dailyHours: Double?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case period
        case totalEurEarned = "total_eur_earned"
        case shiftPay = "shift_pay"
        case bonus
        case totalPayment = "total_payment"
        case transactionCount = "transaction_count"
        case hourlyRate = "hourly_rate"
        case dailyHours = "daily_hours"
    }
}

// MARK: - Available Workers

struct AvailableWorkersResponse: Codable {
    let workers: [AvailableWorkerDTO]
}

struct AvailableWorkerDTO: Codable, Identifiable, Hashable {
    let userId: Int
    let displayName: String

    var id: Int { userId }

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case displayName = "display_name"
    }
}

// MARK: - Telegram

struct TelegramUsersResponse: Codable {
    let status: String?
    let message: String?
    let count: Int?
    let data: [TelegramUserDTO]?
    let error: String?
}

struct TelegramUserDTO: Codable, Identifiable {
    let userId: String
    let phoneNumber: String?
    let authStatus: String?
    let sessionFile: String?

    var id: String { userId }

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case phoneNumber = "phone_number"
        case authStatus = "auth_status"
        case sessionFile = "session_file"
    }
}

struct TelegramActionResponse: Codable {
    let status: String?
    let message: String?
    let error: String?
}

struct TelegramAnalysisResponse: Codable {
    let userId: String?
    let analysisTimestamp: String?
    let results: [TelegramAnalysisResultDTO]?
    let error: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case analysisTimestamp = "analysis_timestamp"
        case results
        case error
    }
}

struct TelegramAnalysisResultDTO: Codable, Identifiable {
    let timeframe: String?
    let totalMessages: Int?
    let totalResponses: Int?
    let avgResponseMinutes: Double?
    let avgResponseHours: Double?
    let avgResponseDays: Double?
    let responsesOver10min: Int?
    let responsesOver10minPercent: Double?
    let error: String?

    var id: String { timeframe ?? UUID().uuidString }

    enum CodingKeys: String, CodingKey {
        case timeframe
        case totalMessages = "total_messages"
        case totalResponses = "total_responses"
        case avgResponseMinutes = "avg_response_minutes"
        case avgResponseHours = "avg_response_hours"
        case avgResponseDays = "avg_response_days"
        case responsesOver10min = "responses_over_10min"
        case responsesOver10minPercent = "responses_over_10min_percent"
        case error
    }
}

// MARK: - Bonus Tiers

struct BonusTiersResponse: Codable {
    let tiers: [BonusTierDTO]
}

struct BonusTierDTO: Codable, Identifiable {
    let threshold: Int
    let bonus: Double

    var id: Int { threshold }
}
