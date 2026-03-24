import Foundation

struct EmailSale {
    let subject: String
    let date: Date
    let parsedGame: String?
    let parsedAmount: Double?
}

class EmailScannerService {
        static func scanFilteredMockEmails(seasonStart: Date) -> [EmailSale] {
            let allEmails = scanMockEmails()
            return allEmails.filter { email in
                email.date > seasonStart && email.subject.lowercased().contains("sold")
            }
        }
    static func scanMockEmails() -> [EmailSale] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let now = Date()
        let sale1 = EmailSale(
            subject: "Your Ticketmaster Sale: Panthers vs Rangers",
            date: now,
            parsedGame: "Panthers vs Rangers",
            parsedAmount: 420.0
        )
        let sale2 = EmailSale(
            subject: "Your Ticketmaster Sale: Panthers vs Leafs",
            date: now.addingTimeInterval(-86400), // 1 day ago
            parsedGame: "Panthers vs Leafs",
            parsedAmount: 380.0
        )
        return [sale1, sale2]
    }
}
