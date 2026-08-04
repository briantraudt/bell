import SwiftUI

@main
struct BellApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .preferredColorScheme(.light)
        }
    }
}

@Observable
final class AppState {
    var selectedTab: BellTab = .home
    var presentedHelp = false
    var isListening = false
    var profile = UserProfile.demo
    var bookings = Booking.demo
    var reminders = Reminder.demo
    var family = FamilyMember.demo
}

enum BellTab: Hashable { case home, plans, me }
