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
    @Published var personalAccessTokenButtonDisabled: Bool = AuthAccessToken.shared.getToken().type == TokenType.OAuth
    @Published var oAuthButtonDisabled: Bool = AuthAccessToken.shared.getToken().type == TokenType.PersonalAccessToken

    @Published var personalAccessTokenLabel: String = AuthAccessToken.shared.exists() && AuthAccessToken.shared.getToken().type != TokenType.OAuth ? "Remove" : "Save"
    @Published var oAuthButtonLabel: String = AuthAccessToken.shared.getToken().type == TokenType.OAuth ? "Logout" : "Login"

    @Published var tokenExists: Bool = AuthAccessToken.shared.exists()

    @Published var currentTokenType: TokenType = AuthAccessToken.shared.getToken().type
}

struct AccessDetail: View {
    var refreshStatusIcon: () -> Void

    @ObservedObject var model = ViewModel()

    private var github: GithubOAuth! = GithubOAuth.shared
    private var personalAccessToken: AuthAccessToken! = AuthAccessToken.shared

    @State private var personalAccessTokenString: String = ""

    init(refreshStatusIcon: @escaping (() -> Void)) {
        self.refreshStatusIcon = refreshStatusIcon

        isUsingOAuth() ? useOAuthToken(initial: true) : useAccessToken(initial: true)
        if AuthAccessToken.shared.getToken().type == TokenType.PersonalAccessToken {
            personalAccessTokenString = AuthAccessToken.shared.getToken().token ?? ""
        }
    }

    func isUsingOAuth() -> Bool {
        return model.currentTokenType == TokenType.OAuth
    }

    func isUsingPersonalAuthToken() -> Bool {
        return model.currentTokenType == TokenType.PersonalAccessToken
    }

    func useOAuthToken(initial: Bool = false) {
        if !initial {
            let url = github.oAuth()
            NSWorkspace.shared.open(url)
            model.oAuthButtonLabel = "Logout"
            model.currentTokenType = TokenType.OAuth
            model.tokenExists = true
            personalAccessTokenString = ""
        }

        model.personalAccessTokenButtonDisabled = true
        model.oAuthButtonDisabled = false
    }

    func useAccessToken(initial: Bool = false) {
        if !initial {
            personalAccessToken.setPersonalAccessToken(token: personalAccessTokenString)
            model.personalAccessTokenLabel = "Remove"
            model.currentTokenType = TokenType.PersonalAccessToken
            model.tokenExists = AuthAccessToken.shared.exists()
        }

        model.personalAccessTokenButtonDisabled = false
        model.oAuthButtonDisabled = AuthAccessToken.shared.exists()
    }

    func removeToken() {
        personalAccessToken.remove()
        personalAccessTokenString = ""

        model.tokenExists = AuthAccessToken.shared.exists()
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

    func personalAccessTokenButtonDisabled() -> Bool {
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
                // current login method status
                if self.model.tokenExists {
                    Text(isUsingOAuth() ? "You're authenticated using oAuth" : "You're authenticated using Personal Access Token")
                            .padding(.trailing, 100.0).foregroundColor(.secondary).font(.callout)
                } else {
                    Text("You are not authenticated. Choose an method:")
                            .padding(.trailing, 100.0)
                }

                // Personal Token method
                GroupBox(label: Text("Add your personal access token from GitHub").foregroundColor(.secondary)) {
                    SecureField("Copy token here", text: $personalAccessTokenString).disabled(self.model.tokenExists).padding(.trailing, 100.0).padding(.top, 2)

                    Button {
                        isUsingPersonalAuthToken() ? removeToken() : useAccessToken()
                        self.refreshStatusIcon()

                    } label: {
                        Text(self.model.personalAccessTokenLabel)
                    }
                }
                        .groupBoxStyle(CardGroupBoxStyle())
                        .disabled(self.model.personalAccessTokenButtonDisabled)

                // OAuth method
                GroupBox(label: Text("Login via GitHub").foregroundColor(.secondary)) {
                    Button {
                        isUsingOAuth() ? removeToken() : useOAuthToken()
                        self.refreshStatusIcon()

                    } label: {
                        Text(self.model.oAuthButtonLabel)
                    }
                }
                        .groupBoxStyle(CardGroupBoxStyle())
                        .disabled(self.model.oAuthButtonDisabled)

                Spacer()

            }
                    .padding()
            Spacer()
        }
                .padding()
    }
}

struct CardGroupBoxStyle: GroupBoxStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading) {
            configuration.label
            configuration.content.frame(width: 575, height: 30, alignment: .leading)
        }
                .padding()
                .overlay(
                        RoundedRectangle(cornerRadius: 3)
                                .stroke(.separator, lineWidth: 1.1)
                )
    }
}

struct PlainGroupBoxStyle: GroupBoxStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading) {
            configuration.label
            configuration.content
        }
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
            }
                    .padding()
            Spacer()
        }
                .padding()
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
