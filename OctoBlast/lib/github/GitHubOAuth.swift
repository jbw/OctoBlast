//
// Created by Jason Watson on 09/09/2022.
// Copyright (c) 2022 JBW. All rights reserved.
//

import Foundation
import OctoKit

open class GithubOAuth {
    public static let shared: GithubOAuth = .init()

    private var token: String = Bundle.main.object(forInfoDictionaryKey: "AUTH_TOKEN") as! String
    private var secret: String = Bundle.main.object(forInfoDictionaryKey: "AUTH_SECRET") as! String
    private var scopes: [String] = ["read:user", "notifications"]

    private var user: User?

    private var oAuthConfig: OAuthConfiguration?

    public func oAuth() -> URL {
        oAuthConfig = OAuthConfiguration(token: token, secret: secret, scopes: scopes)
        let url = oAuthConfig!.authenticate()

        return url!
    }

    public func handleOAuthCallback(
        url: URL,
        completion: @escaping (_ config: TokenConfiguration, _ user: User) -> Void
    ) {
        oAuthConfig!.handleOpenURL(
            url: url,
            completion: { tokenConfig in
                Octokit(tokenConfig).me { response in
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
