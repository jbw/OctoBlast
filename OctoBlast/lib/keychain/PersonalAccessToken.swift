//
//  PersonalAccessToken.swift
//  OctoBlast
//
//  Created by Jason Watson on 16/08/2022.
//

import KeychainSwift

class PersonalAccessToken {
    static let shared = PersonalAccessToken()

    private let keychain: KeychainSwift!

    private var key = "OctoBlastGithubAccessKey"

    init() {
        keychain = KeychainSwift()
        keychain.synchronizable = false
    }

    func exists() -> Bool {
        return personalAccessToken != nil
    }

    func remove() {
        keychain.delete(key)
    }

    var personalAccessToken: String? {
        get {
            return keychain.get(key)
        }
        set {
            if let newValue = newValue {
                keychain.set(newValue, forKey: key, withAccess: .accessibleAfterFirstUnlock)
            } else {
                keychain.delete(key)
            }
        }
    }
}
