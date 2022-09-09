import KeychainSwift
import LaunchAtLogin
import OctoKit
import Preferences
import SwiftUI

struct PreferencesView: View {
    @State private var isActive: Bool = true
    var refreshStatusIcon: () -> Void

    var body: some View {
        NavigationView {
            List {
                NavigationLink(isActive: $isActive) {
                    AccessDetail(refreshStatusIcon: self.refreshStatusIcon)

                } label: {
                    Label("Access", systemImage: "key")
                }

                NavigationLink {
                    AppearanceDetail(refreshStatusIcon: self.refreshStatusIcon)
                } label: {
                    Label("Appearance", systemImage: "paintpalette")
                }

                NavigationLink {
                } label: {
                    Label("Notifications", systemImage: "bell")

                }
                .disabled(true)

                NavigationLink {
                    AdvancedDetail()

                } label: {
                    Label("Advanced", systemImage: "gear")
                }
                .disabled(true)

                NavigationLink {
                    AboutDetail()
                } label: {
                    Label("About", systemImage: "questionmark")
                }

            }
            .listStyle(.sidebar)

            Text("No selection")
        }
        .frame(width: 820, height: 600, alignment: Alignment.top)
    }
}

class ViewModel: ObservableObject {
    @Published var personalAccessTokenButtonDisabled: Bool =
        AuthAccessToken.shared.getToken().type == TokenType.OAuth
    @Published var oAuthButtonDisabled: Bool =
        AuthAccessToken.shared.getToken().type == TokenType.PersonalAccessToken

    @Published var personalAccessTokenLabel: String =
        AuthAccessToken.shared.exists() && AuthAccessToken.shared.getToken().type != TokenType.OAuth
        ? "Remove" : "Save"
    @Published var oAuthButtonLabel: String =
        AuthAccessToken.shared.getToken().type == TokenType.OAuth ? "Logout" : "Login"

    @Published var tokenExists: Bool = AuthAccessToken.shared.exists()

    @Published var currentTokenType: TokenType = AuthAccessToken.shared.getToken().type
}

struct AdvancedDetail: View {
    var body: some View {
        Text("")
    }
}

struct AboutDetail: View {
    @StateObject var updaterViewModel = UpdaterViewModel()

    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            Spacer()

            Text("OctoBlast").font(.system(.title, design: .rounded))

            let buildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String
            Text("v\(buildNumber)")

            LaunchAtLogin.Toggle {
                Text("Launch at login")
            }

            CheckForUpdatesView(updaterViewModel: updaterViewModel)

            Spacer()
        }
    }
}

struct Preferences_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView(refreshStatusIcon: {})
    }
}
