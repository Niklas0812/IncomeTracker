import Foundation

// MARK: - Dashboard

struct DashboardResponse: Codable {
    let totalIncome: Double
    let paysafeIncome: Double
    let paypalIncome: Double
    let paysafeChange: Double?
    let paypalChange: Double?
    let chartData: [ChartDataPointDTO]
    let topWorkers: [TopWorkerDTO]
    let recentTransactions: [TransactionDTO]
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

    enum CodingKeys: String, CodingKey {
        case worker
        case recentTransactions = "recent_transactions"
    }
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
