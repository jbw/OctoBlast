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
                    AccessDetail()

                } label: {
                    Label("Access", systemImage: "key")
                }

                NavigationLink {
                    AppearanceDetail(refreshStatusIcon: self.refreshStatusIcon)
                } label: {
                    Label("Appearance", systemImage: "paintpalette")
                }

                NavigationLink {} label: {
                    Label("Notfications", systemImage: "bell")

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
    @Published var personalAccessTokenButtonDisabled: Bool = AuthAccessToken.shared.getToken().type == TokenType.OAuth
    @Published var oAuthButtonDisabled: Bool = AuthAccessToken.shared.getToken().type == TokenType.PersonalAccessToken

    @Published var personalAccessTokenLabel: String = AuthAccessToken.shared.getToken().type != TokenType.OAuth ? "Remove" : "Save"
    @Published var oAuthButtonLabel: String = AuthAccessToken.shared.getToken().type == TokenType.OAuth ? "Logout" : "Login"

    @Published var tokenExists: Bool = AuthAccessToken.shared.exists()

    @Published var currentTokenType: TokenType = AuthAccessToken.shared.getToken().type
}

struct AccessDetail: View {
    @ObservedObject var model = ViewModel()

    private var github: GithubOAuth! = GithubOAuth.shared
    private var personalAccessToken: AuthAccessToken! = AuthAccessToken.shared

    @State private var personalAccessTokenString: String = AuthAccessToken.shared.getToken().token ?? ""

    init() {
        isUsingOAuth() ?useOAuthToken() : useAccessToken()
    }

    func isUsingOAuth() -> Bool {
        return model.currentTokenType == TokenType.OAuth
    }

    func isUsingPersonalAuthToken() -> Bool {
        return model.currentTokenType == TokenType.PersonalAccessToken
    }

    func useOAuthToken() {
        let url = github.oAuth()
        NSWorkspace.shared.open(url)

        model.tokenExists = true
        model.currentTokenType = TokenType.OAuth

        model.oAuthButtonLabel = "Logout"

        model.personalAccessTokenButtonDisabled = true
        model.oAuthButtonDisabled = false
    }

    func useAccessToken() {
        personalAccessToken.setPersonalAccessToken(token: personalAccessTokenString)

        model.tokenExists = true
        model.currentTokenType = TokenType.PersonalAccessToken

        model.personalAccessTokenLabel = "Remove"

        model.personalAccessTokenButtonDisabled = false
        model.oAuthButtonDisabled = true
    }

    func removeToken() {
        personalAccessToken.remove()
        personalAccessTokenString = ""

        model.tokenExists = false
        model.currentTokenType = TokenType.Undefined

        model.personalAccessTokenLabel = "Save"
        model.oAuthButtonLabel = "Login"

        model.personalAccessTokenButtonDisabled = false
        model.oAuthButtonDisabled = false
    }

    func oauthButtonDisabled() -> Bool {
        if !model.tokenExists {
            return false
        }

        if personalAccessToken.getToken().type == TokenType.OAuth {
            return false
        }

        if !model.personalAccessTokenButtonDisabled {
            return false
        }

        return true
    }

    func personalAcccessTokenButtonDisabled() -> Bool {
        if !model.tokenExists {
            return false
        }

        if personalAccessToken.getToken().type == TokenType.OAuth {
            return true
        }

        if !oauthButtonDisabled() {
            return false
        }

        return true
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 16) {
                if self.model.tokenExists {
                    Text(isUsingOAuth() ? "You're authenticated using oAuth" : "You're authenticated using Personal Access Token")
                        .padding(.trailing, 100.0)
                } else {
                    Text("You are not authenticated. Choose an method:")
                        .padding(.trailing, 100.0)
                }

                Text("Add your personal access token from Github")
                    .font(.title)
                    .padding(.trailing, 100.0)

                SecureField("Copy token here", text: $personalAccessTokenString).disabled(self.model.tokenExists).padding(.trailing, 100.0)

                Button {
                    isUsingPersonalAuthToken() ? removeToken() : useAccessToken()

                } label: {
                    Text(self.model.personalAccessTokenLabel)
                }
                .disabled(self.model.personalAccessTokenButtonDisabled)

                Text("Login via Github")
                    .font(.title)
                    .padding(.trailing, 100.0)

                Button {
                    isUsingOAuth() ? removeToken() : useOAuthToken()

                } label: {
                    Text(self.model.oAuthButtonLabel)
                }
                .disabled(self.model.oAuthButtonDisabled)

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

struct AppearanceDetail: View {
    var refreshStatusIcon: () -> Void

    @State private var iconColor: Color = UserDefaults.standard.color(forKey: "iconTint")

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 16) {
                ColorPicker("Status icon color: ", selection: $iconColor, supportsOpacity: true)
                    .onChange(of: iconColor, perform: { newValue in
                        UserDefaults.standard.setColor(newValue, forKey: "iconTint")
                        self.refreshStatusIcon()

                    })

                Button("Reset") {
                    UserDefaults.standard.setColor(.accentColor, forKey: "iconTint")
                    iconColor = .accentColor
                    self.refreshStatusIcon()
                }
                Spacer()
            }.padding()
            Spacer()
        }.padding()
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

            LaunchAtLogin.Toggle { Text("Launch at login") }

            CheckForUpdatesView(updaterViewModel: updaterViewModel)

            Spacer()
        }
    }
}

struct Preferences_Previews: PreviewProvider {
    static var previews: some View {
        AboutDetail()
    }
}
