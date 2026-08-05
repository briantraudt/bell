import SwiftUI

struct OnboardingFlowView: View {
    @Environment(AppState.self) private var state

    @State private var step: OnboardingStep = .welcome
    @State private var phone = ""
    @State private var code = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var trustedName = ""
    @State private var trustedRelationship = "Daughter"
    @State private var trustedPhone = ""
    @State private var canViewActivity = true
    @State private var textScale = 1.0
    @State private var readAloud = false
    @State private var authSession: BellAuthSession?
    @State private var isWorking = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            Color.bellPaper.ignoresSafeArea()
            Group {
                switch step {
                case .welcome: welcome
                case .phone: phoneEntry
                case .code: codeEntry
                case .name: nameEntry
                case .trustedContact: trustedContact
                case .accessibility: accessibility
                case .complete: complete
                }
            }
            .animation(.easeOut(duration: 0.22), value: step)
        }
        .alert("We couldn't finish that", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "Please try again.")
        }
    }

    private var welcome: some View {
        VStack(spacing: 0) {
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: 30)
                    .fill(Color.bellPaper)
                    .frame(width: 104, height: 104)
                    .shadow(color: .black.opacity(0.08), radius: 20, y: 10)
                Image(systemName: "bell.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(Color.bellTeal)
            }
            Text("Bell")
                .font(.system(size: 70, weight: .regular, design: .serif))
                .foregroundStyle(Color.bellInk)
                .padding(.top, 24)
            Text("All of the important things.")
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(Color.bellSlate)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
            Spacer()
            BellPrimaryButton(title: "Start here") { step = .phone }
                .padding(.horizontal, 28)
                .padding(.bottom, 28)
        }
        .background(
            Image(systemName: "bell.fill")
                .font(.system(size: 330))
                .foregroundStyle(Color.bellTeal.opacity(0.08))
                .offset(x: 120, y: -270)
        )
    }

    private var phoneEntry: some View {
        OnboardingPage(
            step: "Step 1 of 4",
            title: "What's your phone number?",
            subtitle: "We'll text you a code. No password to remember, ever."
        ) {
            VStack(spacing: 18) {
                Text(formattedPhone)
                    .font(.system(size: 42, weight: .semibold, design: .rounded))
                    .frame(maxWidth: .infinity, minHeight: 86)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 22))
                    .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.bellLineStrong, lineWidth: 2))
                    .accessibilityLabel("Phone number")

                NumericKeypad(value: $phone, maximumDigits: 10)

                BellPrimaryButton(title: isWorking ? "Sending…" : "Send me the code") {
                    Task { await sendCode() }
                }
                .disabled(isWorking || phone.filter(\.isNumber).count != 10)
                .opacity(phone.filter(\.isNumber).count == 10 ? 1 : 0.45)
            }
        }
    }

    private var codeEntry: some View {
        OnboardingPage(
            step: "Step 2 of 4",
            title: "Enter the code",
            subtitle: "We sent a six-digit code to \(formattedPhone)."
        ) {
            VStack(spacing: 20) {
                HStack(spacing: 8) {
                    ForEach(0..<6, id: \.self) { index in
                        Text(codeDigit(at: index))
                            .font(.system(size: 34, weight: .semibold, design: .rounded))
                            .frame(maxWidth: .infinity, minHeight: 76)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(index == code.count ? Color.bellTeal : Color.bellLineStrong, lineWidth: 2)
                            )
                    }
                }

                NumericKeypad(value: $code, maximumDigits: 6)

                BellPrimaryButton(title: isWorking ? "Verifying…" : "Verify code") {
                    Task { await verifyCode() }
                }
                .disabled(isWorking || code.count != 6)
                .opacity(code.count == 6 ? 1 : 0.45)

                Button("Resend code") {
                    Task { await sendCode(stayOnCode: true) }
                }
                .font(BellType.button)
                .frame(minHeight: 64)

                Text("Didn't receive it? Wait a moment, then tap Resend code.")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.bellMute)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var nameEntry: some View {
        OnboardingPage(
            step: "Step 3 of 4",
            title: "What's your name?",
            subtitle: "This helps Bell feel familiar."
        ) {
            VStack(spacing: 14) {
                BellTextField(title: "First name", text: $firstName, contentType: .givenName)
                BellTextField(title: "Last name", text: $lastName, contentType: .familyName)

                Text("We'll ask for your address only when a service needs to come to your home.")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.bellSlate)
                    .frame(maxWidth: .infinity, alignment: .leading)

                BellPrimaryButton(title: "Continue") { step = .trustedContact }
                    .disabled(firstName.trimmed.isEmpty || lastName.trimmed.isEmpty)
                    .opacity(firstName.trimmed.isEmpty || lastName.trimmed.isEmpty ? 0.45 : 1)
            }
        }
    }

    private var trustedContact: some View {
        OnboardingPage(
            step: "Step 4 of 4",
            title: "Who should we call if you need help?",
            subtitle: "You can skip this and add someone later."
        ) {
            VStack(spacing: 14) {
                BellTextField(title: "Name", text: $trustedName, contentType: .name)
                BellTextField(title: "Relationship", text: $trustedRelationship)
                BellTextField(
                    title: "Phone number",
                    text: $trustedPhone,
                    contentType: .telephoneNumber,
                    keyboard: .phonePad
                )

                Toggle(isOn: $canViewActivity) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Let \(trustedName.isEmpty ? "this person" : trustedName) see what I book")
                            .font(BellType.rowTitle)
                        Text("They never see your private conversations.")
                            .font(.system(size: 16))
                            .foregroundStyle(Color.bellSlate)
                    }
                }
                .tint(.bellTeal)
                .padding(18)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 22))

                BellPrimaryButton(title: "Continue") { step = .accessibility }

                Button("Skip for now") {
                    trustedName = ""
                    trustedPhone = ""
                    step = .accessibility
                }
                .font(BellType.button)
                .frame(minHeight: 64)
            }
        }
    }

    private var accessibility: some View {
        OnboardingPage(
            step: nil,
            title: "Make Bell comfortable to read",
            subtitle: "You can change this any time."
        ) {
            VStack(spacing: 22) {
                Text("Bell will make important things clear and easy to find.")
                    .font(.system(size: 27 * textScale, weight: .medium))
                    .foregroundStyle(Color.bellInk)
                    .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
                    .padding(20)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 22))

                VStack(spacing: 10) {
                    Slider(value: $textScale, in: 0.9...1.25, step: 0.05)
                        .tint(.bellTeal)
                    HStack {
                        Text("Smaller")
                        Spacer()
                        Text("Large")
                        Spacer()
                        Text("Bigger")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.bellSlate)
                }

                Toggle("Read things out loud to me", isOn: $readAloud)
                    .font(BellType.rowTitle)
                    .tint(.bellTeal)
                    .padding(18)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 22))

                BellPrimaryButton(title: isWorking ? "Saving…" : "That's good") {
                    Task { await finishOnboarding() }
                }
                .disabled(isWorking)
            }
        }
    }

    private var complete: some View {
        VStack(spacing: 22) {
            Spacer()
            Image(systemName: "checkmark")
                .font(.system(size: 50, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 104, height: 104)
                .background(Color.bellTeal)
                .clipShape(RoundedRectangle(cornerRadius: 30))

            Text("You're all set, \(firstName)")
                .font(BellType.title(42))
                .multilineTextAlignment(.center)

            BellCard(primary: true) {
                HStack(spacing: 16) {
                    Image(systemName: "phone.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Color.bellClay)
                    Text("The red HELP button is always in the top corner.")
                        .font(BellType.body)
                }
            }

            BellCard(primary: true) {
                HStack(spacing: 16) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Color.bellTeal)
                    Text("The green bar at the bottom listens whenever you tap it.")
                        .font(BellType.body)
                }
            }

            Spacer()

            BellPrimaryButton(title: "Take me in") {
                state.completeOnboarding(
                    firstName: firstName,
                    lastName: lastName,
                    phone: phone,
                    city: "",
                    readAloud: readAloud
                )
            }
        }
        .padding(28)
    }

    private var formattedPhone: String {
        let digits = phone.filter(\.isNumber)
        let area = String(digits.prefix(3))
        let prefix = String(digits.dropFirst(3).prefix(3))
        let line = String(digits.dropFirst(6).prefix(4))
        if digits.count <= 3 { return area.isEmpty ? "(   )    –" : "(\(area))" }
        if digits.count <= 6 { return "(\(area)) \(prefix)" }
        return "(\(area)) \(prefix)-\(line)"
    }

    private func codeDigit(at index: Int) -> String {
        guard index < code.count else { return "" }
        return String(code[code.index(code.startIndex, offsetBy: index)])
    }

    @MainActor
    private func sendCode(stayOnCode: Bool = false) async {
        isWorking = true
        defer { isWorking = false }
        do {
            try await AuthService.shared.sendSMSCode(phone: phone)
            if !stayOnCode { step = .code }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func verifyCode() async {
        isWorking = true
        defer { isWorking = false }
        do {
            authSession = try await AuthService.shared.verifySMSCode(phone: phone, code: code)
            step = .name
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func finishOnboarding() async {
        guard let authSession else {
            errorMessage = "Your phone number needs to be verified again."
            step = .phone
            return
        }

        isWorking = true
        defer { isWorking = false }

        do {
            try await AuthService.shared.saveOnboarding(
                session: authSession,
                phone: phone,
                firstName: firstName.trimmed,
                lastName: lastName.trimmed,
                address: "",
                city: "",
                textScale: textScale,
                readAloud: readAloud,
                trustedName: trustedName.trimmed,
                trustedRelationship: trustedRelationship.trimmed,
                trustedPhone: trustedPhone,
                canViewActivity: canViewActivity
            )
            step = .complete
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private enum OnboardingStep {
    case welcome
    case phone
    case code
    case name
    case trustedContact
    case accessibility
    case complete
}

private struct OnboardingPage<Content: View>: View {
    let step: String?
    let title: String
    let subtitle: String
    @ViewBuilder let content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if let step {
                    Text(step.uppercased())
                        .font(BellType.section)
                        .foregroundStyle(Color.bellTeal)
                }
                Text(title)
                    .font(BellType.title(40))
                    .foregroundStyle(Color.bellInk)
                Text(subtitle)
                    .font(BellType.body)
                    .foregroundStyle(Color.bellSlate)
                    .padding(.bottom, 10)
                content
            }
            .padding(.horizontal, 28)
            .padding(.top, 32)
            .padding(.bottom, 40)
        }
        .scrollDismissesKeyboard(.interactively)
    }
}

private struct NumericKeypad: View {
    @Binding var value: String
    let maximumDigits: Int

    private let rows = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        ["", "0", "delete.left.fill"]
    ]

    var body: some View {
        VStack(spacing: 10) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: 10) {
                    ForEach(row, id: \.self) { key in
                        if key.isEmpty {
                            Color.clear.frame(maxWidth: .infinity, minHeight: 66)
                        } else {
                            Button {
                                if key == "delete.left.fill" {
                                    if !value.isEmpty { value.removeLast() }
                                } else if value.count < maximumDigits {
                                    value.append(key)
                                }
                            } label: {
                                Group {
                                    if key == "delete.left.fill" {
                                        Image(systemName: key)
                                    } else {
                                        Text(key)
                                    }
                                }
                                .font(.system(size: 30, weight: .semibold, design: .rounded))
                                .frame(maxWidth: .infinity, minHeight: 66)
                                .background(Color.white)
                                .foregroundStyle(Color.bellInk)
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.bellLine))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(key == "delete.left.fill" ? "Delete" : key)
                        }
                    }
                }
            }
        }
    }
}

private struct BellTextField: View {
    let title: String
    @Binding var text: String
    var contentType: UITextContentType? = nil
    var keyboard: UIKeyboardType = .default

    var body: some View {
        TextField(title, text: $text)
            .font(BellType.body)
            .textContentType(contentType)
            .keyboardType(keyboard)
            .textInputAutocapitalization(.words)
            .padding(.horizontal, 18)
            .frame(minHeight: 72)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.bellLineStrong, lineWidth: 1.5))
    }
}

private extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
