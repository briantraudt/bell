import SwiftUI

@main
struct BellApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            Group {
                if appState.hasCompletedOnboarding {
                    RootView()
                } else {
                    OnboardingFlowView()
                }
            }
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
    var hasCompletedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: "bell.onboarding.completed")
        }
    }
    var textScale: Double {
        didSet {
            UserDefaults.standard.set(textScale, forKey: "bell.text.scale")
        }
    }

    init() {
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "bell.onboarding.completed")
        let savedScale = UserDefaults.standard.double(forKey: "bell.text.scale")
        textScale = savedScale == 0 ? 1.0 : savedScale
    }

    func completeOnboarding(firstName: String, lastName: String, phone: String, city: String, readAloud: Bool) {
        profile = UserProfile(id: UUID(), firstName: firstName, lastName: lastName, phone: phone, city: city, readAloud: readAloud)
        bookings = []
        reminders = []
        family = []
        hasCompletedOnboarding = true
    }

    func resetForTesting() {
        hasCompletedOnboarding = false
    }
}

enum BellTab: Hashable { case home, plans, me }
