import Foundation

struct Transaction: Identifiable, Hashable {
    let id: UUID
    let workerId: UUID
    let workerName: String
    let paymentSource: PaymentSource
    let amount: Decimal
    let currency: String
    let date: Date
    let status: TransactionStatus
    let reference: String

    init(
        id: UUID = UUID(),
        workerId: UUID,
        workerName: String,
        paymentSource: PaymentSource,
        amount: Decimal,
        currency: String = "EUR",
        date: Date,
        status: TransactionStatus = .completed,
        reference: String
    ) {
        self.id = id
        self.workerId = workerId
        self.workerName = workerName
        self.paymentSource = paymentSource
        self.amount = amount
        self.currency = currency
        self.date = date
        self.status = status
        self.reference = reference
    }
}
