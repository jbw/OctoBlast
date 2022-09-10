//
// Created by Jason Watson on 09/09/2022.
// Copyright (c) 2022 JBW. All rights reserved.
//

import Foundation
import SwiftUI

struct AccessDetail: View {

    @ObservedObject var model: AccessSettings

    private var refreshCallback: () -> Void
    private var auth: GithubOAuth! = GithubOAuth.shared
    private var accessToken: AuthAccessToken! = AuthAccessToken.shared

    init(refreshCallback: @escaping () -> Void) {
        self.refreshCallback = refreshCallback

        model = AccessSettings(accessToken: accessToken)

        // set up initial state from any persisted data e.g. token
        // todo currently these methods need a flag to denote first initial load. we could split these?
        if isUsingOAuth() {
            useOAuthToken(initial: true)
        }

        if isUsingPersonalAuthToken() {
            useAccessToken(initial: true)
        }

        if !accessToken.exists() {
            defaultState()
        }

    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 16) {
                showUserAuthTypeMessage()
                showAuthOptionPersonalAccessToken()
                showAuthOptionOAuth()
                Spacer()
            }.padding()
            Spacer()
        }.padding()
    }

    private func isUsingOAuth() -> Bool { accessToken.getToken().type == TokenType.OAuth }

    private func isUsingPersonalAuthToken() -> Bool {
        accessToken.getToken().type == TokenType.PersonalAccessToken
    }

    private func defaultState() {
        model.personalAccessTokenButtonDisabled = false
        model.oAuthButtonDisabled = false
        model.oAuthButtonLabel = "Login"
        model.personalAccessTokenLabel = "Save"
    }

    private func useOAuthToken(initial: Bool = false) {
        if !initial {
            let url = auth.oAuth()
            NSWorkspace.shared.open(url)

            model.oAuthButtonLabel = "Logout"
            model.personalAccessTokenString = ""
        }

        model.personalAccessTokenButtonDisabled = true
        model.oAuthButtonDisabled = false
    }

    private func useAccessToken(initial: Bool = false) {
        if !initial {
            accessToken.setPersonalAccessToken(token: model.personalAccessTokenString)
            model.personalAccessTokenLabel = "Remove"
        }

        model.personalAccessTokenButtonDisabled = false
        model.oAuthButtonDisabled = true
    }

    private func removeToken() {
        accessToken.remove()
        model.personalAccessTokenString = ""

        model.personalAccessTokenLabel = "Save"
        model.oAuthButtonLabel = "Login"

        model.personalAccessTokenButtonDisabled = false
        model.oAuthButtonDisabled = false
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
        GroupBox(label: Text("Login via GitHub").foregroundColor(.secondary)) {
            Button {
                isUsingOAuth() ? removeToken() : useOAuthToken()
                refreshCallback()

            } label: {
                Text(model.oAuthButtonLabel)
            }
        }
        .groupBoxStyle(CardGroupBoxStyle())
        .disabled(model.oAuthButtonDisabled)
    }

    private func showAuthOptionPersonalAccessToken() -> some View {
        let token = accessToken.getToken()
        let tokenExists = accessToken.exists() && token.type != TokenType.OAuth

        return GroupBox(
            label: Text("Add your personal access token from GitHub")
                .foregroundColor(.secondary)
        ) {
            secureField()
                .disabled(tokenExists)
                .padding(.trailing, 100.0)
                .padding(.top, 2)

            togglePersonalAccessTokenButton()
        }
        .groupBoxStyle(CardGroupBoxStyle())
        .disabled(model.personalAccessTokenButtonDisabled)
    }

    private func showUserAuthTypeMessage() -> some View {
        if accessToken.exists() {
            let text: AttributedString =
                isUsingOAuth()
                ? "You're authenticated using oAuth"
                : "You're authenticated using Personal Access Token"

            return AnyView(
                Text(text)
                    .padding(.trailing, 100.0)
                    .foregroundColor(.secondary)
                    .font(.callout)
            )
        }

        return AnyView(
            Text("You are not authenticated. Choose an method:").padding(.trailing, 100.0)
        )

    }

    private func secureField() -> SecureField<Text> {
        SecureField("Copy token here", text: $model.personalAccessTokenString)
    }

    private func togglePersonalAccessTokenButton() -> Button<Text> {
        Button {
            isUsingPersonalAuthToken() ? removeToken() : useAccessToken()
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

    init(accessToken: AuthAccessToken) {
        if accessToken.getToken().type == TokenType.PersonalAccessToken {
            personalAccessTokenString = accessToken.getToken().token ?? ""
        }

        personalAccessTokenButtonDisabled = accessToken.getToken().type == TokenType.OAuth
        oAuthButtonDisabled = accessToken.getToken().type == TokenType.PersonalAccessToken
        oAuthButtonLabel = accessToken.getToken().type == TokenType.OAuth ? "Logout" : "Login"
        personalAccessTokenLabel =
            accessToken.exists() && accessToken.getToken().type != TokenType.OAuth
            ? "Remove" : "Save"
    }
}

struct CardGroupBoxStyle: GroupBoxStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading) {
            configuration.label
            configuration.content.frame(width: 575, height: 30, alignment: .leading)
        }.padding().overlay(RoundedRectangle(cornerRadius: 3).stroke(.separator, lineWidth: 1.1))
    }
}
