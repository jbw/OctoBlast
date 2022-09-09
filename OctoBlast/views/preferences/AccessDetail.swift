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
                    Text(
                        isUsingOAuth()
                            ? "You're authenticated using oAuth"
                            : "You're authenticated using Personal Access Token"
                    )
                    .padding(.trailing, 100.0).foregroundColor(.secondary).font(.callout)
                }
                else {
                    Text("You are not authenticated. Choose an method:")
                        .padding(.trailing, 100.0)
                }

                // Personal Token method
                GroupBox(
                    label: Text("Add your personal access token from GitHub").foregroundColor(
                        .secondary
                    )
                ) {
                    SecureField("Copy token here", text: $personalAccessTokenString).disabled(
                        self.model.tokenExists
                    ).padding(.trailing, 100.0).padding(.top, 2)

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
