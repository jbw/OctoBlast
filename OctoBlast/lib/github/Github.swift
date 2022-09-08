//
//  Github.swift
//  OctoBlast
//
//  Created by Jason Watson on 16/08/2022.
//
import Foundation
import OctoKit

class GithubOAuth {
    public static let shared: GithubOAuth = .init()

    private var token: String = Bundle.main.object(forInfoDictionaryKey: "AUTH_TOKEN") as! String
    private var secret: String = Bundle.main.object(forInfoDictionaryKey: "AUTH_SECRET") as! String
    private var scopes: [String] = ["read:user", "notifications"]

    private var oAuthConfig: OAuthConfiguration?

    public func oAuth() -> URL {
        oAuthConfig = OAuthConfiguration(token: token, secret: secret, scopes: scopes)
        let url = oAuthConfig!.authenticate()

        return url!
    }

    public func handleOAuthCallback(url: URL, completion: @escaping (_ config: TokenConfiguration, _ user: User) -> Void) {
        oAuthConfig!.handleOpenURL(url: url, completion: { tokenConfig in
            Octokit(tokenConfig).me { response in
                switch response {
                case let .success(user):
                    completion(tokenConfig, user)
                case let .failure(error):
                    print("Error: \(error)")
                }
            }
        })
    }
}

class GitHub {
    public var myNotifications: [Any] = []

    private var client: Octokit!
    private var config: TokenConfiguration!

    public init(config: TokenConfiguration) {
        self.config = config
        client = Octokit(config)
    }

    public func fetch(cb: @escaping (Bool) -> Void) {
        getMyNotifications(cb: cb)
    }

    private func getMyNotifications(cb: @escaping (Bool) -> Void) {
        var newNotifications: [Any] = []

        client.myNotifications(URLSession(configuration: URLSessionConfiguration.ephemeral), all: false, participating: true, page: "1", perPage: "25") { response in
            switch response {
            case let .success(notifications):
                for notification in notifications {
                    if notification.subject.type == "PullRequest" {
                        if notification.reason == OctoKit.NotificationThread.Reason.reviewRequested || notification.reason == OctoKit.NotificationThread.Reason.stateChange || notification.reason == OctoKit.NotificationThread.Reason.author {
                            newNotifications.append(notification)
                        }
                    }
                }

                self.myNotifications = newNotifications
                cb(true)

            case let .failure(error):
                print(error)
                cb(false)
            }
        }
    }
}
