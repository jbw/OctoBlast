import KeychainSwift
import Preferences
import SwiftUI
import LaunchAtLogin
import OctoKit

struct PreferencesView: View {
    @State private var isActive: Bool = true
    var refreshStatusIcon: () -> Void

    var body: some View {
        NavigationView {
            List {
                NavigationLink(isActive: $isActive) {
                    GeneralAccess()

                } label: {
                    Label("General", systemImage: "switch.2")
                }

                NavigationLink() {
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

struct GeneralAccess: View {
    @StateObject var updaterViewModel = UpdaterViewModel()

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Application")
                LaunchAtLogin.Toggle { Text("Launch at login") }
                
                Text("Check for updates")
                CheckForUpdatesView(updaterViewModel: updaterViewModel)
                            
            }.padding()
            Spacer()
        }.padding()
        Spacer()
    }
    
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
                
                Button("Reset"){
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
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 16) {
                let buildNumber = Bundle.main.object(forInfoDictionaryKey:"CFBundleVersion") as! String
                Text("Version: \(buildNumber)")
        
            Spacer()
        }.padding()
            Spacer()
        }.padding()
    }
}

struct Preferences_Previews: PreviewProvider {
    static var previews: some View {
        AppearanceDetail(refreshStatusIcon: {})
    }
}
