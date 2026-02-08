import Foundation

// MARK: - Sample Data Generator
// Realistic mock data for 8+ workers and 50+ transactions over 12 months.

struct SampleData {

    // MARK: - Workers

    static let workers: [Worker] = [
        // PaySafe workers
        Worker(id: workerIDs[0], name: "Elena Müller", paymentSource: .paysafe, totalEarnings: 14_520.00, isActive: true,
               joinedDate: date(2024, 1, 15)),
        Worker(id: workerIDs[1], name: "Marco Rossi", paymentSource: .paysafe, totalEarnings: 11_340.50, isActive: true,
               joinedDate: date(2024, 2, 3)),
        Worker(id: workerIDs[2], name: "Sophie Laurent", paymentSource: .paysafe, totalEarnings: 8_790.25, isActive: true,
               joinedDate: date(2024, 3, 20)),
        Worker(id: workerIDs[3], name: "Jan Novak", paymentSource: .paysafe, totalEarnings: 5_210.00, isActive: false,
               joinedDate: date(2024, 5, 10)),

        // PayPal workers
        Worker(id: workerIDs[4], name: "Anna Schmidt", paymentSource: .paypal, totalEarnings: 18_650.75, isActive: true,
               joinedDate: date(2024, 1, 8)),
        Worker(id: workerIDs[5], name: "Luca Bianchi", paymentSource: .paypal, totalEarnings: 9_875.00, isActive: true,
               joinedDate: date(2024, 4, 1)),
        Worker(id: workerIDs[6], name: "Emma Johansson", paymentSource: .paypal, totalEarnings: 7_430.50, isActive: true,
               joinedDate: date(2024, 6, 15)),
        Worker(id: workerIDs[7], name: "Thomas Weber", paymentSource: .paypal, totalEarnings: 3_280.00, isActive: false,
               joinedDate: date(2024, 7, 22)),
        Worker(id: workerIDs[8], name: "Clara Fernandez", paymentSource: .paysafe, totalEarnings: 6_120.00, isActive: true,
               joinedDate: date(2024, 8, 5)),
        Worker(id: workerIDs[9], name: "Niklas Berg", paymentSource: .paypal, totalEarnings: 4_950.30, isActive: true,
               joinedDate: date(2024, 9, 12)),
    ]

    // Stable UUIDs so transactions can reference workers
    static let workerIDs: [UUID] = (0..<10).map { _ in UUID() }

    // MARK: - Transactions

    static let transactions: [Transaction] = generateTransactions()

    // MARK: - Generator

    private static func generateTransactions() -> [Transaction] {
        var txns: [Transaction] = []
        var counter = 1

        // Amounts pool for variation
        let amountRanges: [(Decimal, Decimal)] = [
            (15, 150), (100, 500), (200, 800), (350, 1200), (500, 2500),
            (75, 300), (150, 600), (25, 200), (180, 950), (400, 1800)
        ]

        let calendar = Calendar.current
        let now = Date()

        for workerIndex in 0..<workers.count {
            let worker = workers[workerIndex]
            let (low, high) = amountRanges[workerIndex]

            // Generate 5-8 transactions per worker spread over last 12 months
            let txCount = 5 + (workerIndex % 4)

            for i in 0..<txCount {
                let daysBack = Int.random(in: 1...365)
                let txDate = calendar.date(byAdding: .day, value: -daysBack, to: now)!

                let range = high - low
                let randomFraction = Decimal(Int.random(in: 0...100)) / 100
                let amount = (low + range * randomFraction).rounded(scale: 2)

                // Most transactions completed; sprinkle in pending and failed
                let status: TransactionStatus
                if i == txCount - 1 && workerIndex % 3 == 0 {
                    status = .pending
                } else if i == txCount - 2 && workerIndex % 5 == 0 {
                    status = .failed
                } else {
                    status = .completed
                }

                let ref = String(format: "TXN-2024-%05d", counter)
                counter += 1

                txns.append(Transaction(
                    workerId: worker.id,
                    workerName: worker.name,
                    paymentSource: worker.paymentSource,
                    amount: amount,
                    date: txDate,
                    status: status,
                    reference: ref
                ))
            }
        }

        // Add some extra recent transactions for dashboard richness
        let recentWorkers = Array(workers.prefix(5))
        for i in 0..<10 {
            let worker = recentWorkers[i % recentWorkers.count]
            let hoursBack = Int.random(in: 1...72)
            let txDate = calendar.date(byAdding: .hour, value: -hoursBack, to: now)!
            let amount = Decimal(Int.random(in: 50...1500))
            let ref = String(format: "TXN-2025-%05d", counter)
            counter += 1

            txns.append(Transaction(
                workerId: worker.id,
                workerName: worker.name,
                paymentSource: worker.paymentSource,
                amount: amount,
                date: txDate,
                status: i == 8 ? .pending : .completed,
                reference: ref
            ))
        }

        return txns.sorted { $0.date > $1.date }
    }

    // MARK: - Helpers

    private static func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return Calendar.current.date(from: components) ?? .now
    }
}

private extension Decimal {
    func rounded(scale: Int) -> Decimal {
        var value = self
        var result = Decimal()
        NSDecimalRound(&result, &value, scale, .plain)
        return result
    }
}
