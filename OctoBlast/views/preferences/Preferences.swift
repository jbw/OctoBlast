import KeychainSwift
import Preferences
import SwiftUI

struct PreferencesView: View {
    @State private var isActive: Bool = true

    var body: some View {
        NavigationView {
            List {
                NavigationLink(isActive: $isActive) {
                    AccessDetail()

                } label: {
                    Label("Access", systemImage: "key")
                }

                NavigationLink {} label: {
                    Label("Notfications", systemImage: "bell")

                }.disabled(true)

                NavigationLink {} label: {
                    Label("Appearance", systemImage: "paintpalette")
                }.disabled(true)

                NavigationLink {
                    AdvancedDetail()

                } label: {
                    Label("Advanced", systemImage: "gear")
                }.disabled(true)

                NavigationLink {
                    AboutDetail()
                } label: {
                    Label("About", systemImage: "questionmark")
                }

            }.listStyle(.sidebar)

            Text("No selection")
        }.frame(width: 820, height: 600, alignment: Alignment.top)
    }
}

class ViewModel: ObservableObject {
    @Published var buttonState: String = PersonalAccessToken.shared.exists() ? "Remove" : "Save"
    @Published var personalAccessTokenExists: Bool = PersonalAccessToken.shared.exists()
}

struct AccessDetail: View {
    @ObservedObject var model = ViewModel()

    private var loginManager: PersonalAccessToken! = PersonalAccessToken.shared

    @State private var personalAccessToken: String = PersonalAccessToken.shared.personalAccessToken ?? ""

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 16) {
                SecureField("Github personal access token", text: $personalAccessToken).disabled(self.model.personalAccessTokenExists).padding(.trailing, 100.0)

                Button {
                    // Toggle
                    if PersonalAccessToken.shared.exists() {
                        loginManager.remove()
                        self.model.buttonState = "Save"
                        self.model.personalAccessTokenExists = false

                    } else {
                        loginManager.personalAccessToken = personalAccessToken
                        self.model.buttonState = "Remove"
                        self.model.personalAccessTokenExists = true
                    }

                } label: {
                    Text(self.model.buttonState)
                }
                Spacer()
            }.padding()
            Spacer()
        }.padding()
    }
}

struct AdvancedDetail: View {
    var body: some View {
        Text("")
    }
}

struct AboutDetail: View {
    var body: some View {
        Text("Version: v0.0.1.dev.3")
    }
}

struct Preferences_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView()
    }
}
