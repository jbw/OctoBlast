//
//  Github.swift
//  OctoBlast
//
//  Created by Jason Watson on 16/08/2022.
//

import Foundation
import OctoKit


class GitHub {
    public var myNotifications: [Any] = []

    private var client: Octokit!
    private var config: TokenConfiguration!

    public init(config: TokenConfiguration) {
        self.config = config
        client = Octokit(config)
    }

    public func fetch(cb: @escaping (Bool, Int) -> Void) {
        getMyNotifications(cb: cb)
    }

    private func getMyNotifications(cb: @escaping (Bool, Int) -> Void) {
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
                return cb(true, 200)

            case let .failure(error):

                print(error.localizedDescription)
                if error.localizedDescription.contains("error 401") {
                    return cb(false, 401)
                }

                // todo pass error back and if is an auth error, delete the token
                return cb(false, 500)
            }
        }
    }
}
