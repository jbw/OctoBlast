//
// Created by Jason Watson on 09/09/2022.
// Copyright (c) 2022 JBW. All rights reserved.
//

import Foundation
import OctoKit

enum GitHubOAuthError: Error {
    case credsMissing
}

open class GitHubOAuth {
    public static let shared: GitHubOAuth = .init()

    let token: String? = ProcessInfo.processInfo.environment["AUTH_TOKEN"]
    let secret: String? = ProcessInfo.processInfo.environment["AUTH_SECRET"]

    private var scopes: [String] = ["read:user", "notifications"]

    private var user: User?

    private var oAuthConfig: OAuthConfiguration?

    public func oAuth() throws -> URL {

        if token == nil || secret == nil {
            throw GitHubOAuthError.credsMissing
        }

        oAuthConfig = OAuthConfiguration(token: token!, secret: secret!, scopes: scopes)
        let url = oAuthConfig!.authenticate()

        return url!
    }

    public func handleOAuthCallback(
        url: URL,
        completion: @escaping (_ config: TokenConfiguration, _ user: User) -> Void
    ) {
        oAuthConfig!
            .handleOpenURL(
                url: url,
                completion: { tokenConfig in
                    Octokit(tokenConfig)
                        .me { response in
                            switch response {
                                case let .success(user):
                                    completion(tokenConfig, user)
                                case let .failure(error):
                                    print("Error: \(error)")
                            }
                        }
                }
            )
    }
}
