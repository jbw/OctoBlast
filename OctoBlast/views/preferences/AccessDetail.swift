//
// Created by Jason Watson on 09/09/2022.
// Copyright (c) 2022 JBW. All rights reserved.
//

import SwiftUI

struct AccessDetail: View {
    @ObservedObject var model: AccessSettings

    private var refreshCallback: () -> Void
    private var auth: GithubOAuth! = GithubOAuth.shared
    private var accessToken: AuthAccessToken! = AuthAccessToken.shared

    private func getUser(github: GitHub) {
        github.me { user, _ in
            model.userId = "@" + user!.login!
            model.fullName = user!.name!
            model.avatarURL = user!.avatarURL!
        }
    }

    init(refreshCallback: @escaping () -> Void) {
        self.refreshCallback = refreshCallback

        model = AccessSettings(accessToken: accessToken)

        if accessToken.exists() {
            let github = GitHub(token: accessToken.getToken().token!)
            getUser(github: github)
        }

        if !accessToken.exists() {
            emptyState()
        }
        else if accessToken.isOAuth() {
            setOAuthAsActive()
        }
        else if accessToken.isPersonalAccessToken() {
            setAccessTokenAsActive()
        }
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 16) {
                if accessToken.exists() {
                    userInfo(
                        fullName: model.fullName,
                        userId: model.userId,
                        avatarURL: model.avatarURL
                    )
                }

                showAuthOptionPersonalAccessToken()
                showAuthOptionOAuth()
                Spacer()
            }
            .padding()
            Spacer()
        }
        .padding()
    }

    private func emptyState() {
        model.personalAccessTokenButtonDisabled = false
        model.oAuthButtonDisabled = false
        model.oAuthButtonLabel = "Sign In"
        model.personalAccessTokenLabel = "Save"
        model.fullName = ""
        model.userId = ""
        model.avatarURL = ""
    }

    private func useOAuthToken() {
        if let url = try? auth.oAuth(){
            NSWorkspace.shared.open(url)
            refreshUserInfo()
            setOAuthAsActive()
        }
    }

    private func refreshUserInfo() {
        if accessToken.exists() {
            let github = GitHub(token: accessToken.getToken().token!)
            getUser(github: github)
        }
    }

    private func setOAuthAsActive() {
        model.oAuthButtonLabel = "Sign Out"
        model.personalAccessTokenString = ""
        model.personalAccessTokenButtonDisabled = true
        model.oAuthButtonDisabled = false
    }

    private func useAccessToken(initial: Bool = false) {
        accessToken.setPersonalAccessToken(token: model.personalAccessTokenString)
        refreshUserInfo()
        setAccessTokenAsActive()
    }

    private func setAccessTokenAsActive() {
        model.personalAccessTokenLabel = "Remove"
        model.personalAccessTokenButtonDisabled = false
        model.oAuthButtonDisabled = true
    }

    private func removeToken() {
        accessToken.remove()
        model.personalAccessTokenString = ""

        emptyState()
    }

    private func oauthButtonDisabled() -> Bool {
        if !accessToken.exists() { return false }

        if accessToken.getToken().type == TokenType.OAuth { return false }

        return true
    }

    private func personalAccessTokenButtonDisabled() -> Bool {
        if !accessToken.exists() { return false }

        if accessToken.getToken().type == TokenType.OAuth { return true }

        return true
    }

    private func showAuthOptionOAuth() -> some View {
        let tokenExists = accessToken.exists() && accessToken.isOAuth()

        let text = Text("GitHub.com").foregroundColor(.secondary)

        let label = Label(
            title: { text },
            icon: { tokenExists ? authOptionSelectedIcon() : nil }
        )

        return GroupBox(label: label) {
            Button {
                accessToken.isOAuth() ? removeToken() : useOAuthToken()
                refreshCallback()
            } label: {
                Text(model.oAuthButtonLabel)
            }
        }
        .groupBoxStyle(CardGroupBoxStyle())
        .disabled(model.oAuthButtonDisabled)
    }

    private func showAuthOptionPersonalAccessToken() -> some View {
        let tokenExists = accessToken.exists() && accessToken.isPersonalAccessToken()
        let text = Text("Add your personal access token from GitHub").foregroundColor(.secondary)

        let label = Label(
            title: { text },
            icon: { tokenExists ? authOptionSelectedIcon() : nil }
        )

        return GroupBox(label: label) {
            secureField()
                .disabled(tokenExists)
                .padding(.trailing, 100.0)
                .padding(.top, 2)

            togglePersonalAccessTokenButton()
        }
        .groupBoxStyle(CardGroupBoxStyle())
        .disabled(model.personalAccessTokenButtonDisabled)
    }

    private func authOptionSelectedIcon() -> some View {
        let selectedIcon = "checkmark.circle.fill"
        let fill = Color(.green)
        let icon = Image(systemName: selectedIcon).foregroundColor(fill)

        return icon
    }

    private func userInfo(fullName: String, userId: String, avatarURL: String) -> some View {
        HStack(alignment: .top) {

            HStack(
                alignment: .center

            ) {
                AsyncImage(url: URL(string: avatarURL)) { image in
                    image.resizable()
                } placeholder: {
                    Color.gray
                }
                .frame(width: 44, height: 44)
                .clipShape(Circle())

            }
            VStack(
                alignment: .leading,
                spacing: 2
            ) {
                Text(fullName)
                    .foregroundColor(.secondary)
                    .font(.title3)

                Text(userId)
                    .foregroundColor(.secondary)
                    .font(.title3)
            }
        }

    }

    private func secureField() -> SecureField<Text> {
        SecureField("Copy token here", text: $model.personalAccessTokenString)
    }

    private func togglePersonalAccessTokenButton() -> Button<Text> {
        Button {
            accessToken.isPersonalAccessToken() ? removeToken() : useAccessToken()
            refreshCallback()
        } label: {
            Text(model.personalAccessTokenLabel)
        }
    }
}

class AccessSettings: ObservableObject {
    @Published var personalAccessTokenLabel: String
    @Published var personalAccessTokenButtonDisabled: Bool
    @Published var personalAccessTokenString: String = ""

    @Published var oAuthButtonLabel: String
    @Published var oAuthButtonDisabled: Bool

    @Published var userId: String = ""
    @Published var fullName: String = ""
    @Published var avatarURL: String = ""

    init(accessToken: AuthAccessToken) {
        personalAccessTokenString =
            accessToken.isPersonalAccessToken() ? accessToken.getToken().token ?? "" : ""

        personalAccessTokenButtonDisabled = accessToken.isOAuth()
        oAuthButtonDisabled = accessToken.isPersonalAccessToken()
        oAuthButtonLabel = accessToken.exists() && accessToken.isOAuth() ? "Sign Out" : "Sign In"
        personalAccessTokenLabel =
            accessToken.exists() && accessToken.isPersonalAccessToken() ? "Remove" : "Save"
    }
}

struct CardGroupBoxStyle: GroupBoxStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading) {
            configuration.label
            configuration.content.frame(width: 575, height: 30, alignment: .leading)
        }
        .padding().overlay(RoundedRectangle(cornerRadius: 3).stroke(.separator, lineWidth: 1.1))
    }
}
