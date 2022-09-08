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
                NavigationLink (isActive: $isActive) {
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
    @Published var buttonState: String = PersonalAccessToken.shared.exists() ? "Remove" : "Save"
    @Published var personalAccessTokenExists: Bool = PersonalAccessToken.shared.exists()
}

struct AccessDetail: View {
    @ObservedObject var model = ViewModel()
    private var github: GithubOAuth! = GithubOAuth.shared

    private var personalAccessToken: PersonalAccessToken! = PersonalAccessToken.shared

    @State private var personalAccessTokenString: String = PersonalAccessToken.shared.personalAccessToken ?? ""

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Add your personal access token from Github")
                    .font(.title)
                    .padding(.trailing, 100.0)

                SecureField("Copy token here", text: $personalAccessTokenString).disabled(self.model.personalAccessTokenExists).padding(.trailing, 100.0)

                Button {
                    // Toggle
                    if PersonalAccessToken.shared.exists() {
                        personalAccessToken.remove()
                        self.model.buttonState = "Save"
                        self.model.personalAccessTokenExists = false

                    } else {
                        personalAccessToken.personalAccessToken = personalAccessTokenString
                        self.model.buttonState = "Remove"
                        self.model.personalAccessTokenExists = true
                    }

                } label: {
                    Text(self.model.buttonState)
                }
                
                Text("Login via Github")
                    .font(.title)
                    .padding(.trailing, 100.0)
                Button {
                    let url = github.oAuth()
                    NSWorkspace.shared.open(url)
                } label: {
                    Text("Login")
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
