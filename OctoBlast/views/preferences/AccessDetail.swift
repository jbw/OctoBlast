//
// Created by Jason Watson on 09/09/2022.
// Copyright (c) 2022 JBW. All rights reserved.
//

import Foundation
import SwiftUI

struct AccessDetail: View {
    var refreshStatusIcon: () -> Void

    @ObservedObject var model = ViewModel()

    private var github: GithubOAuth! = GithubOAuth.shared
    private var personalAccessToken: AuthAccessToken! = AuthAccessToken.shared

    @State private var personalAccessTokenString: String = ""

    init(refreshStatusIcon: @escaping () -> Void) {
        self.refreshStatusIcon = refreshStatusIcon

        // set up initial state from any persisted data e.g. token
        // todo currently these methods need a flag to denote first initial load. we could split these?
        isUsingOAuth() ? useOAuthToken(initial: true) : useAccessToken(initial: true)

        if AuthAccessToken.shared.getToken().type == TokenType.PersonalAccessToken {
            personalAccessTokenString = AuthAccessToken.shared.getToken().token ?? ""
        }
    }

    func isUsingOAuth() -> Bool { model.currentTokenType == TokenType.OAuth }

    func isUsingPersonalAuthToken() -> Bool {
        model.currentTokenType == TokenType.PersonalAccessToken
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
        if !model.tokenExists { return false }

        if personalAccessToken.getToken().type == TokenType.OAuth { return false }

        if !model.personalAccessTokenButtonDisabled { return false }

        return true
    }

    func personalAccessTokenButtonDisabled() -> Bool {
        if !model.tokenExists { return false }

        if personalAccessToken.getToken().type == TokenType.OAuth { return true }

        if !oauthButtonDisabled() { return false }

        return true
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

    private func showAuthOptionOAuth() -> some View {
        GroupBox(label: Text("Login via GitHub").foregroundColor(.secondary)) {
            Button {
                isUsingOAuth() ? removeToken() : useOAuthToken()
                refreshStatusIcon()

            } label: {
                Text(model.oAuthButtonLabel)
            }
        }
        .groupBoxStyle(CardGroupBoxStyle())
        .disabled(model.oAuthButtonDisabled)
    }

    private func showAuthOptionPersonalAccessToken() -> some View {

        GroupBox(
            label: Text("Add your personal access token from GitHub")
                .foregroundColor(.secondary)
        ) {
            secureField()
                .disabled(model.tokenExists)
                .padding(.trailing, 100.0)
                .padding(.top, 2)

            button()
        }
        .groupBoxStyle(CardGroupBoxStyle())
        .disabled(model.personalAccessTokenButtonDisabled)
    }

    private func showUserAuthTypeMessage() -> some View {
        if model.tokenExists {
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
        SecureField("Copy token here", text: $personalAccessTokenString)
    }

    private func button() -> Button<Text> {
        Button {
            isUsingPersonalAuthToken() ? removeToken() : useAccessToken()
            refreshStatusIcon()

        } label: {
            Text(model.personalAccessTokenLabel)
        }
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

struct CardGroupBoxStyle: GroupBoxStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading) {
            configuration.label
            configuration.content.frame(width: 575, height: 30, alignment: .leading)
        }.padding().overlay(RoundedRectangle(cornerRadius: 3).stroke(.separator, lineWidth: 1.1))
    }
}
