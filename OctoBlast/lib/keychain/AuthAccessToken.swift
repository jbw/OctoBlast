//
//  AuthAccessToken.swift
//  OctoBlast
//
//  Created by Jason Watson on 16/08/2022.
//

import KeychainSwift

enum TokenType: String {
    case OAuth = "oauth"
    case PersonalAccessToken = "pat"
    case Unknown = "unknown"
    case Empty = "empty"
}

class AuthAccessToken {
    static let shared = AuthAccessToken()

    private let keychain: KeychainSwift!

    private var key = "OctoBlastGithubAccessKey"

    private var separator = "|"

    init() {
        keychain = KeychainSwift()
        keychain.synchronizable = false
    }

    func exists() -> Bool {
        if (authAccessToken ?? "").isEmpty { return false }

        return true
    }

    func remove() { keychain.delete(key) }

    func setPersonalAccessToken(token: String) {
        authAccessToken = TokenType.PersonalAccessToken.rawValue + separator + token
    }

    func setOAuthAccessToken(token: String) {
        authAccessToken = TokenType.OAuth.rawValue + separator + token
    }

    func getType() -> TokenType {
        getToken().type
    }

    func isPersonalAccessToken() -> Bool {
        // note: for backwards compatibility we assume Undefined is also a PAT
        // as it was the only option until TokenType and OAuth option existed.
        getType() == TokenType.PersonalAccessToken || getType() == TokenType.Unknown
    }

    func isOAuth() -> Bool {
        getType() == TokenType.OAuth
    }

    func getToken() -> (token: String?, type: TokenType) {
        let token = authAccessToken

        if token == nil { return (nil, TokenType.Empty) }

        let split = token!.components(separatedBy: separator)

        // note: assuming we have pre TokenType baked in setting string
        if split.count == 1 { return (split[0], TokenType.Unknown) }

        let head = split[0]
        let body = split[1]
        let type = TokenType(rawValue: head)!

        return (body, type)
    }

    private var authAccessToken: String? {
        get { keychain.get(key) }
        set {
            if let newValue = newValue {
                keychain.set(newValue, forKey: key, withAccess: .accessibleAfterFirstUnlock)
            } else {
                keychain.delete(key)
            }
        }
    }
}
