import Foundation

struct Transaction: Identifiable, Hashable {
    let id: String
    let workerId: Int
    let workerName: String
    let paymentSource: PaymentSource
    let amount: Decimal
    let date: Date
    let status: TransactionStatus
    let reference: String
    let hasScreenshot: Bool
    let screenshotFilename: String?

    init(
        id: String = UUID().uuidString,
        workerId: Int,
        workerName: String,
        paymentSource: PaymentSource,
        amount: Decimal,
        date: Date,
        status: TransactionStatus = .completed,
        reference: String,
        hasScreenshot: Bool = false,
        screenshotFilename: String? = nil
    ) {
        self.id = id
        self.workerId = workerId
        self.workerName = workerName
        self.paymentSource = paymentSource
        self.amount = amount
        self.date = date
        self.status = status
        self.reference = reference
        self.hasScreenshot = hasScreenshot
        self.screenshotFilename = screenshotFilename
    }

    init(from dto: TransactionDTO) {
        self.id = dto.id
        self.workerId = dto.workerId
        self.workerName = dto.workerName
        self.paymentSource = PaymentSource(apiString: dto.source) ?? .paysafe
        self.amount = Decimal(dto.amount)
        self.status = TransactionStatus(apiString: dto.status) ?? .completed
        self.reference = dto.reference
        self.hasScreenshot = dto.hasScreenshot
        self.screenshotFilename = dto.screenshotFilename

        if let dateStr = dto.date {
            self.date = Date.fromAPIString(dateStr) ?? Date()
        } else {
            self.date = Date()
        }
    }
}
