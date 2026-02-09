import UserNotifications

final class NotificationService {
    static let shared = NotificationService()

    private init() {}

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    func sendTransactionNotification(workerName: String, amount: Double, source: String) {
        let content = UNMutableNotificationContent()
        content.title = "New Payment Received"
        content.body = "\(workerName) - \(String(format: "%.2f", amount))\u{20AC} via \(source.capitalized)"
        content.sound = UNNotificationSound(named: UNNotificationSoundName("shopify_sale.caf"))

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }
}
