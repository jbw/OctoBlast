import KeychainSwift
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

struct Preferences_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView(refreshStatusIcon: {})
    }
}
