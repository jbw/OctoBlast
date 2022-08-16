//
//  Github.swift
//  OctoBlast
//
//  Created by Jason Watson on 16/08/2022.
//
import Foundation
import OctoKit

class GitHub {
    static let shared = GitHub()

    public var me: User!
    public var myNotifications: [Any] = []

    private var personalAccessToken: String? = ""

    public func fetch(_ token: String, cb: @escaping (Bool) -> Void) {
        personalAccessToken = token
        auth()

        getMyNofications(cb: cb)
    }

    private var client: Octokit! {
        guard let personalAccessToken = personalAccessToken else {
            return nil
        }

        let config = TokenConfiguration(personalAccessToken)

        return Octokit(config)
    }

    private func auth() {
        client.me { response in
            switch response {
            case let .success(user):
                self.me = user
            case let .failure(error):
                print(error)
            }
        }
    }

    private func getMyPullRequests(_ login: String, _ repo: String, _ base: String) {
        client.pullRequests(owner: login, repository: repo, base: base, state: Openness.open) { response in
            switch response {
            case let .success(pullRequests):
                print(pullRequests as Any)
            case let .failure(error):
                print(error)
            }
        }
    }

    private func getMyNofications(cb: @escaping (Bool) -> Void) {
        var newNotifications: [Any] = []
        client.myNotifications(URLSession(configuration: URLSessionConfiguration.ephemeral), all: false, participating: true, page: "1", perPage: "25") { response in
            switch response {
            case let .success(notifications):
                for notification in notifications {
                    if notification.subject.type == "PullRequest" {
                        if notification.reason == OctoKit.NotificationThread.Reason.reviewRequested {
                            newNotifications.append(notification)
                        } else if notification.reason == OctoKit.NotificationThread.Reason.stateChange {
                            newNotifications.append(notification)
                        } else if notification.reason == OctoKit.NotificationThread.Reason.author {
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
