import Foundation

struct UserProfile: Codable, Identifiable {
    let id: UUID
    var firstName: String
    var lastName: String
    var phone: String
    var city: String
    var readAloud: Bool
    static let demo = UserProfile(id: UUID(), firstName: "Margaret", lastName: "Ellis", phone: "(555) 014-2222", city: "Elmwood", readAloud: true)
}

struct Booking: Codable, Identifiable {
    let id: UUID
    var providerName: String
    var service: String
    var date: Date
    var priceCents: Int
    var status: String
    static let demo = [Booking(id: UUID(), providerName: "Ray Guzmán", service: "Paint the porch", date: Date().addingTimeInterval(172800), priceCents: 32000, status: "booked")]
}

struct Reminder: Codable, Identifiable {
    let id: UUID
    var title: String
    var detail: String
    var date: Date
    var enabled: Bool
    static let demo = [Reminder(id: UUID(), title: "Blood pressure pill", detail: "Take with water", date: Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date()) ?? Date(), enabled: true)]
}

struct FamilyMember: Codable, Identifiable {
    let id: UUID
    var name: String
    var relationship: String
    var phone: String
    var initials: String
    static let demo = [
        FamilyMember(id: UUID(), name: "Susan", relationship: "Daughter", phone: "555-0101", initials: "S"),
        FamilyMember(id: UUID(), name: "Michael", relationship: "Grandson", phone: "555-0102", initials: "M"),
        FamilyMember(id: UUID(), name: "Tom", relationship: "Neighbor", phone: "555-0103", initials: "T")
    ]
}
