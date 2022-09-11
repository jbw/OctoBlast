//
//  Github.swift
//  OctoBlast
//
//  Created by Jason Watson on 16/08/2022.
//

import Foundation
import OctoKit

open class GitHub {

    private var client: Octokit!
    private var config: TokenConfiguration!

    public init(token: String) {
        config = TokenConfiguration(token)
        client = Octokit(config)
    }

    public func fetch(completion: @escaping ([NotificationThread], Int) -> Void) {
        getMyNotifications(completion: completion)
    }

    public func me(completion: @escaping (User?, Error?) -> Void) {
        client.me { response in
            switch response {
                case .success(let user):
                    completion(user, nil)
                case .failure(let error):
                    print(error)
                    completion(nil, error)
            }
        }
    }

    private func notificationsFilter(notifications: [NotificationThread]) -> [NotificationThread] {
        notifications.filter { notification in
            notification.subject.type == "PullRequest"
                && (notification.reason == OctoKit.NotificationThread.Reason.reviewRequested
                    || notification.reason == OctoKit.NotificationThread.Reason.stateChange
                    || notification.reason == OctoKit.NotificationThread.Reason.author)
        }

    }

    private func getMyNotifications(
        page: Int = 1,
        perPage: Int = 25,
        completion: @escaping ([NotificationThread], Int) -> Void
    ) {
        var newNotifications: [NotificationThread] = []

        client.myNotifications(
            URLSession(configuration: URLSessionConfiguration.ephemeral),
            all: false,
            participating: true,
            page: String(page),
            perPage: String(perPage)
        ) { response in
            switch response { case let .success(notifications):
                let filteredNotifications = self.notificationsFilter(notifications: notifications)
                for notification in filteredNotifications {
                    newNotifications.append(notification)
                }

                return completion(newNotifications, 200)

                case let .failure(error):
                    if error.localizedDescription.contains("error 401") {
                        return completion([], 401)
                    }

                    return completion([], 500)
            }
        }
    }
}
