import SwiftUI

struct RootView: View {
    @Environment(AppState.self) private var state
    var body: some View {
        @Bindable var state = state
        TabView(selection: $state.selectedTab) {
            NavigationStack { HomeView() }.tag(BellTab.home).tabItem { Label("Home", systemImage: "house.fill") }
            NavigationStack { PlansView() }.tag(BellTab.plans).tabItem { Label("Plans", systemImage: "calendar") }
            NavigationStack { ProfileView() }.tag(BellTab.me).tabItem { Label("Me", systemImage: "person.fill") }
        }
        .tint(.bellTeal)
        .sheet(isPresented: $state.presentedHelp) { EmergencyView() }
    }
}

struct HomeView: View {
    @Environment(AppState.self) private var state
    private let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                            .font(BellType.section).foregroundStyle(Color.bellMute).textCase(.uppercase)
                        Text("Good morning,\n\(state.profile.firstName)").font(BellType.title()).foregroundStyle(Color.bellInk)
                    }
                    Spacer(); HelpButton()
                }
                LazyVGrid(columns: columns, spacing: 14) {
                    HomeTile(title: "Home help", subtitle: "Painter, plumber", icon: "hammer.fill", destination: ServiceListView(title: "Home help", items: ["Painting", "Plumbing", "Electrical", "Odd jobs", "Cleaning"]))
                    HomeTile(title: "A ride", subtitle: "Doctor, errands", icon: "car.fill", destination: ServiceListView(title: "A ride", items: ["Dr. Feld’s office", "Elmwood Pharmacy", "St. Anne’s Church", "Susan’s house"]))
                    HomeTile(title: "Groceries", subtitle: "Fresh today", icon: "basket.fill", destination: GroceriesView())
                    HomeTile(title: "My family", subtitle: "Call Susan", icon: "person.2.fill", destination: FamilyView())
                }
                BellCard {
                    Text("LATER TODAY").font(BellType.section).tracking(1.5).foregroundStyle(Color.bellMute)
                    Text("Blood pressure pill at 6:00 pm").font(BellType.body).foregroundStyle(Color.bellInk).padding(.top, 5)
                }
                NavigationLink(destination: AskBellView()) {
                    HStack(spacing: 14) {
                        ZStack { Circle().fill(Color.bellPaper).frame(width: 56, height: 56); Image(systemName: "mic.fill").font(.system(size: 25)).foregroundStyle(Color.bellTeal) }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Ask me anything").font(.system(size: 26, weight: .semibold))
                            Text("Tap and talk, or type").font(.system(size: 18)).foregroundStyle(Color(hex: 0x9CC6C2))
                        }
                        Spacer()
                    }.padding(18).frame(maxWidth: .infinity).background(Color.bellTeal).foregroundStyle(.white).clipShape(RoundedRectangle(cornerRadius: 24))
                }.buttonStyle(.plain)
            }.padding(20)
        }.background(Color.bellPaper).navigationBarHidden(true)
    }
}

struct HomeTile<Destination: View>: View {
    let title: String; let subtitle: String; let icon: String; let destination: Destination
    var body: some View {
        NavigationLink(destination: destination) {
            VStack(alignment: .leading) {
                Image(systemName: icon).font(.system(size: 32)).foregroundStyle(Color.bellTeal)
                Spacer()
                Text(title).font(BellType.rowTitle).foregroundStyle(Color.bellInk)
                Text(subtitle).font(.system(size: 16)).foregroundStyle(Color.bellSlate)
            }.padding(18).frame(maxWidth: .infinity, minHeight: 150, alignment: .leading).background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 22)).overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.bellLine))
        }.buttonStyle(.plain)
    }
}

struct BellHeader: View {
    let title: String
    var body: some View { HStack(alignment: .top) { Text(title).font(BellType.title(34)); Spacer(); HelpButton(compact: true) }.padding(.bottom, 8) }
}

struct ServiceListView: View {
    let title: String; let items: [String]
    var body: some View {
        ScrollView { VStack(spacing: 14) {
            BellHeader(title: title)
            Text("Everyone here is checked and insured").font(BellType.body).foregroundStyle(Color.bellSlate).frame(maxWidth: .infinity, alignment: .leading)
            ForEach(items, id: \.self) { item in
                NavigationLink(destination: AskBellView()) {
                    BellCard { HStack { Image(systemName: "checkmark.shield.fill").frame(width: 36).foregroundStyle(Color.bellTeal); Text(item).font(BellType.rowTitle); Spacer(); Image(systemName: "chevron.right").foregroundStyle(Color.bellHint) }.frame(minHeight: 64) }
                }.buttonStyle(.plain).foregroundStyle(Color.bellInk)
            }
            NavigationLink(destination: AskBellView()) { Text("Just describe it\nI’ll work out who you need").multilineTextAlignment(.center).font(BellType.button).frame(maxWidth: .infinity, minHeight: 88).foregroundStyle(.white).background(Color.bellTeal).clipShape(RoundedRectangle(cornerRadius: 22)) }.buttonStyle(.plain)
        }.padding(20) }.background(Color.bellPaper).navigationBarHidden(true)
    }
}

struct GroceriesView: View {
    var body: some View { ScrollView { VStack(spacing: 14) {
        BellHeader(title: "Groceries")
        BellCard(primary: true) {
            Text("YOUR USUAL ORDER").font(BellType.section).foregroundStyle(Color.bellTeal)
            Text("Milk, bread, eggs, bananas, tea, chicken, oatmeal and 5 more").font(BellType.rowTitle).padding(.vertical, 6)
            Text("12 items · about $84").font(BellType.body).foregroundStyle(Color.bellSlate)
            BellPrimaryButton(title: "Order this again") { }.padding(.top, 12)
        }
        BellCard { Text("Change the list").font(BellType.rowTitle); Divider().padding(.vertical, 10); Text("Start a new order").font(BellType.rowTitle); Text("Read your list out loud").font(.system(size: 17)).foregroundStyle(Color.bellSlate) }
        BellCard { Text("ARRIVES TOMORROW").font(BellType.section).foregroundStyle(Color.bellMute); Text("Between 10 am and noon. Ken carries it to the kitchen.").font(BellType.body).padding(.top, 5) }
        Text("Nothing is paid for until it’s at your door.").font(BellType.body).foregroundStyle(Color.bellSlate).multilineTextAlignment(.center)
    }.padding(20) }.background(Color.bellPaper).navigationBarHidden(true) }
}

struct FamilyView: View {
    @Environment(AppState.self) private var state
    var body: some View { ScrollView { VStack(spacing: 14) {
        BellHeader(title: "My family")
        ForEach(state.family) { person in BellCard(primary: person.name == "Susan") { HStack { Text(person.initials).font(.system(size: 22, weight: .bold)).frame(width: 64, height: 64).background(Color.bellTealTint).foregroundStyle(Color.bellTeal).clipShape(Circle()); VStack(alignment: .leading) { Text(person.name).font(BellType.rowTitle); Text(person.relationship).font(BellType.body).foregroundStyle(Color.bellSlate) }; Spacer(); Image(systemName: "phone.fill").frame(width: 56, height: 56).background(Color.bellTealTint).foregroundStyle(Color.bellTeal).clipShape(Circle()) } } }
        BellPrimaryButton(title: "Add someone", icon: "plus") { }
    }.padding(20) }.background(Color.bellPaper).navigationBarHidden(true) }
}

struct AskBellView: View {
    @State private var text = ""
    var body: some View { VStack(spacing: 0) {
        ScrollView { VStack(alignment: .leading, spacing: 16) {
            Text("Ask Bell").font(BellType.title()).frame(maxWidth: .infinity, alignment: .leading)
            Text("Good morning, Margaret. What can I help with?").font(BellType.body).padding(16).background(Color.bellTealTint).clipShape(RoundedRectangle(cornerRadius: 20))
            Text("How much should it cost to paint my porch?").font(BellType.body).padding(16).background(Color.white).clipShape(RoundedRectangle(cornerRadius: 20)).frame(maxWidth: .infinity, alignment: .trailing)
            BellCard(primary: true) { Text("A porch like yours usually costs").font(BellType.body); Text("$280 – $420").font(BellType.title(30)).padding(.vertical, 2); Text("No payment until the work is done.").font(BellType.body).foregroundStyle(Color.bellSlate); BellPrimaryButton(title: "Show me the 3 painters") { }.padding(.top, 10) }
        }.padding(20) }
        BellPrimaryButton(title: "Talk to a real person", icon: "person.wave.2.fill") { }.padding(.horizontal, 20).padding(.bottom, 10)
        HStack { TextField("Type here", text: $text).font(BellType.body).padding().frame(minHeight: 64).background(Color.white).clipShape(RoundedRectangle(cornerRadius: 18)).overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.bellLineStrong)); Button { } label: { Image(systemName: "mic.fill").font(.system(size: 25)).frame(width: 64, height: 64).background(Color.bellClay).foregroundStyle(.white).clipShape(RoundedRectangle(cornerRadius: 18)) }.accessibilityLabel("Speak your question") }.padding(20).background(Color.bellPaper)
    }.background(Color.bellPaper) }
}

struct PlansView: View {
    @Environment(AppState.self) private var state
    var body: some View { ScrollView { VStack(spacing: 14) {
        BellHeader(title: "Your plans")
        ForEach(state.bookings) { booking in BellCard(primary: true) { Text(booking.date.formatted(date: .complete, time: .shortened)).font(BellType.section).foregroundStyle(Color.bellTeal); Text("\(booking.providerName) is coming to \(booking.service.lowercased())").font(BellType.rowTitle).padding(.vertical, 4); Text("$\(booking.priceCents / 100) after the work is finished").font(BellType.body).foregroundStyle(Color.bellSlate) } }
        ForEach(state.reminders) { reminder in BellCard { HStack { Image(systemName: "pills.fill").foregroundStyle(Color.bellTeal); VStack(alignment: .leading) { Text(reminder.title).font(BellType.rowTitle); Text(reminder.date.formatted(date: .omitted, time: .shortened)).font(BellType.body).foregroundStyle(Color.bellSlate) }; Spacer(); Image(systemName: "checkmark.circle.fill").font(.system(size: 28)).foregroundStyle(Color.bellTeal) } } }
    }.padding(20) }.background(Color.bellPaper).navigationBarHidden(true) }
}

struct ProfileView: View {
    @Environment(AppState.self) private var state
    var body: some View { ScrollView { VStack(spacing: 14) {
        BellHeader(title: "Me")
        BellCard(primary: true) { Text("\(state.profile.firstName) \(state.profile.lastName)").font(BellType.title(30)); Text(state.profile.phone).font(BellType.body).foregroundStyle(Color.bellSlate); Text(state.profile.city).font(BellType.body).foregroundStyle(Color.bellSlate) }
        ForEach(["People I trust", "How you pay", "Text size", "Read screens aloud", "Settings"], id: \.self) { item in BellCard { HStack { Text(item).font(BellType.rowTitle); Spacer(); Image(systemName: "chevron.right").foregroundStyle(Color.bellHint) } } }
    }.padding(20) }.background(Color.bellPaper).navigationBarHidden(true) }
}

struct EmergencyView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View { VStack(spacing: 16) {
        HStack { Button("Close") { dismiss() }.font(BellType.body); Spacer() }
        Text("Who should we call?").font(BellType.title(38)).frame(maxWidth: .infinity, alignment: .leading)
        Text("Nothing happens until you choose.").font(BellType.body).foregroundStyle(Color.bellSlate).frame(maxWidth: .infinity, alignment: .leading)
        EmergencyChoice(icon: "cross.case.fill", title: "Call 911", detail: "For immediate danger", urgent: true)
        EmergencyChoice(icon: "person.2.fill", title: "Call Susan", detail: "Your daughter", urgent: false)
        EmergencyChoice(icon: "headphones", title: "Talk to Bell", detail: "A real person, day or night", urgent: false)
        Spacer()
        BellCard { Text("This screen stays open. Take your time.").font(BellType.body).foregroundStyle(Color.bellSlate) }
    }.padding(20).background(Color.bellPaper) }
}

struct EmergencyChoice: View {
    let icon: String; let title: String; let detail: String; let urgent: Bool
    var body: some View { Button { } label: { HStack { Image(systemName: icon).font(.system(size: 28)).frame(width: 58, height: 58).background(urgent ? Color.bellClayTint : Color.bellTealTint).foregroundStyle(urgent ? Color.bellClay : Color.bellTeal).clipShape(RoundedRectangle(cornerRadius: 16)); VStack(alignment: .leading) { Text(title).font(BellType.rowTitle); Text(detail).font(.system(size: 17)).foregroundStyle(Color.bellSlate) }; Spacer(); Image(systemName: "chevron.right") }.padding(16).frame(maxWidth: .infinity, minHeight: 90).background(Color.white).foregroundStyle(Color.bellInk).clipShape(RoundedRectangle(cornerRadius: 22)).overlay(RoundedRectangle(cornerRadius: 22).stroke(urgent ? Color.bellClay : Color.bellLine, lineWidth: urgent ? 2 : 1)) }.buttonStyle(.plain) }
}
