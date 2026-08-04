import SwiftUI

extension Color {
    static let bellInk = Color(hex: 0x1C1A17)
    static let bellSlate = Color(hex: 0x5C544B)
    static let bellMute = Color(hex: 0x8A8078)
    static let bellHint = Color(hex: 0xB2A99F)
    static let bellPaper = Color(hex: 0xFBF7F2)
    static let bellSand = Color(hex: 0xF3EEE7)
    static let bellLine = Color(hex: 0xE5DCD2)
    static let bellLineStrong = Color(hex: 0xCFC5B9)
    static let bellTeal = Color(hex: 0x0F5B57)
    static let bellTealPress = Color(hex: 0x0B4643)
    static let bellTealTint = Color(hex: 0xEAF3F2)
    static let bellClay = Color(hex: 0xB4472E)
    static let bellClayTint = Color(hex: 0xF7EAE6)

    init(hex: UInt, alpha: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xff) / 255,
                  green: Double((hex >> 8) & 0xff) / 255,
                  blue: Double(hex & 0xff) / 255,
                  opacity: alpha)
    }
}

enum BellType {
    static func title(_ size: CGFloat = 36) -> Font { .system(size: size, weight: .regular, design: .serif) }
    static let section = Font.system(size: 15, weight: .bold)
    static let rowTitle = Font.system(size: 22, weight: .semibold)
    static let body = Font.system(size: 19, weight: .regular)
    static let button = Font.system(size: 21, weight: .bold)
}

struct BellCard<Content: View>: View {
    var primary = false
    @ViewBuilder var content: Content
    var body: some View {
        content.padding(18).frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(primary ? Color.bellTeal : Color.bellLine, lineWidth: primary ? 2 : 1))
    }
}

struct BellPrimaryButton: View {
    let title: String
    var icon: String? = nil
    var height: CGFloat = 68
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if let icon { Image(systemName: icon) }
                Text(title).font(BellType.button)
            }.frame(maxWidth: .infinity).frame(height: height)
        }
        .buttonStyle(.plain).foregroundStyle(.white).background(Color.bellTeal)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .accessibilityAddTraits(.isButton)
    }
}

struct HelpButton: View {
    var compact = false
    @Environment(AppState.self) private var state
    var body: some View {
        Button { state.presentedHelp = true } label: {
            VStack(spacing: 3) {
                Image(systemName: "phone.fill").font(.system(size: compact ? 20 : 27))
                Text("HELP").font(.system(size: compact ? 10 : 12, weight: .bold))
            }.frame(width: compact ? 62 : 82, height: compact ? 62 : 82)
        }
        .buttonStyle(.plain).foregroundStyle(.white).background(Color.bellClay)
        .clipShape(RoundedRectangle(cornerRadius: compact ? 21 : 27))
        .accessibilityLabel("Help — call for help")
    }
}
