//
//  MastodonSession.swift
//  swiftodon
//
//  Created by sonson on 2017/04/24.
//  Copyright © 2017年 sonson. All rights reserved.
//

import Foundation
import MiniKeychain
import UIKit

enum MastodonSessionError: Error {
    case invalidJSONDataInKeychain
    case invalidBaseURL
    case invalidJSONEntry(name: String)
    case invalidHost(host: String)
    case invalidParameter
    case clientKeyNotFound
    
    case invalidCallbackURL
    case invalidJSON
    case invalidJSONData
    case httpError(code: Int)
}

public let MastodonSessionUpdateNotification = UIKit.Notification.Name(rawValue: "MastodonSessionUpdateNotification")

public struct MastodonSession {
    let baseURL: URL
    let host: String
    var userName: String
    var accessToken: String
    var clientID: String
    var clientSecret: String
    var createdAt: TimeInterval
    
    // MARK: - Static properties
    
    static func redirectURI(host: String) -> String {
        return "swiftodon://\(host)/"
    }
    
    static var version: String {
        return "v1"
    }
    
    static var clientName: String {
        return "com.sonson.swiftodon"
    }
    
    static var scopes: String {
        return "read write follow"
    }
    
    static var hostKeychainIdentifier: String {
        return "com.sonson.swiftodon.host"
    }
    
    static var accountKeychainIdentifier: String {
        return "com.sonson.swiftodon.account"
    }
    
    // MARK: - Instance methods
    
    var json: [String: Any] {
        return [
            "host": host,
            "userName": userName,
            "accessToken": accessToken,
            "clientID": clientID,
            "clientSecret": clientSecret,
            "createdAt": createdAt
        ]
    }
    
    public var key: String {
        return "\(userName)@\(host)"
    }
    
    public init(host: String, userName: String, accessToken: String, clientID: String, clientSecret: String, createdAt: Double) throws {
        guard let baseURL = URL(string: "https://\(host)/api/\(MastodonSession.version)") else { throw MastodonSessionError.invalidBaseURL }
        self.baseURL = baseURL
        self.host = host
        self.userName = userName
        self.accessToken = accessToken
        self.clientID = clientID
        self.clientSecret = clientSecret
        self.createdAt = createdAt
    }
    
    public init(json: JSONDictionary) throws {
        guard let host = json["host"] as? String
            else { throw MastodonSessionError.invalidJSONEntry(name: "host") }
        guard let userName = json["userName"] as? String
            else { throw MastodonSessionError.invalidJSONEntry(name: "userName") }
        guard let accessToken = json["accessToken"] as? String
            else { throw MastodonSessionError.invalidJSONEntry(name: "accessToken") }
        guard let clientID = json["clientID"] as? String
            else { throw MastodonSessionError.invalidJSONEntry(name: "clientID") }
        guard let clientSecret = json["clientSecret"] as? String
            else { throw MastodonSessionError.invalidJSONEntry(name: "clientSecret") }
        guard let createdAt = json["createdAt"] as? Double
            else { throw MastodonSessionError.invalidJSONEntry(name: "createdAt") }
        guard let baseURL = URL(string: "https://\(host)/api/\(MastodonSession.version)")
            else { throw MastodonSessionError.invalidBaseURL }
        
        self.baseURL = baseURL
        self.host = host
        self.userName = userName
        self.accessToken = accessToken
        self.clientID = clientID
        self.clientSecret = clientSecret
        self.createdAt = createdAt
    }
    
    func save() throws {
        let data = try JSONSerialization.data(withJSONObject: json, options: [])
        let keychain = Keychain(service: MastodonSession.accountKeychainIdentifier)
        try keychain.save(key: key, data: data)
    }
    
    // MARK: -
    
    static func tryToDownloadClientKeys(host: String) throws {
        guard let url = URL(string: "https://\(host)/api/v1/apps") else { throw MastodonSessionError.invalidHost(host: host) }
        
        let parameters: [String: String] = [
            "client_name": clientName,
            "redirect_uris": redirectURI(host: host),
            "scopes": scopes
        ]
        guard let data = parameters.URLQuery.data(using: .utf8) else { throw MastodonSessionError.invalidParameter }
        
        var request = URLRequest(url: url)
        request.httpBody = data
        request.httpMethod = "POST"
        
        let task = URLSession(configuration: URLSessionConfiguration.default).dataTask(with: request) { (data, response, error) in
            switch (data, response, error) {
            case (let data?, let response as HTTPURLResponse, _):
                if 200..<300 ~= response.statusCode {
                    do {
                        guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else { return }
                        guard let client_id = json["client_id"] as? String else { return }
                        guard let client_secret = json["client_secret"] as? String else { return }
                        try MastodonSession.save(host: host, clientID: client_id, clientSecret: client_secret)
                        openBrowserForOAuth2(host: host, clientID: client_id)
                    } catch {
                        print(error)
                    }
                } else {
                }
            case (_, _, let error?):
                print(error)
            default:
                fatalError("Unexpected response from URLsession.")
            }
        }
        task.resume()
    }
    
    static func tryToDownloadUserProfile(session: MastodonSession) throws {
        let endpoint = CurrentUser(session: session)
        let request = try endpoint.request()
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            do {
                let account = try endpoint.parse(data: data, response: response, error: error)
                var copied = session
                copied.userName = account.username
                try copied.save()
                DispatchQueue.main.async(execute: {
                    NotificationCenter.default.post(name: MastodonSessionUpdateNotification, object: nil, userInfo: nil)
                })
            } catch {
                print(error)
            }
        }
        task.resume()
    }
    
    static func handleAccessTokenReponse(data: Data?, response: URLResponse?, error: Error?) throws -> (String, Double) {
        switch (data, response, error) {
        case (let data?, let response as HTTPURLResponse, _):
            if 200..<300 ~= response.statusCode {
                do {
                    guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else { throw MastodonSessionError.invalidJSONData }
                    guard let accessToken = json["access_token"] as? String else { throw MastodonSessionError.invalidJSON }
                    guard let createdAt = json["created_at"] as? Double else { throw MastodonSessionError.invalidJSON }
                    return (accessToken, createdAt)
                } catch {
                    throw error
                }
            } else {
                throw MastodonSessionError.httpError(code: response.statusCode)
            }
        case (_, _, let error?):
            throw error
        default:
            fatalError("Unexpected response from URLsession.")
        }
    }
    
    static func tryToDownloadAccessToken(host: String, code: String) throws {
        guard let (clientID, clientSecret) = MastodonSession.clientKeys(of: host) else { throw MastodonSessionError.clientKeyNotFound }
        
        let parameters: [String: String] = [
            "grant_type": "authorization_code",
            "client_id": clientID,
            "client_secret": clientSecret,
            "redirect_uri": redirectURI(host: host),
            "code": code
        ]
        guard let data = parameters.URLQuery.data(using: .utf8) else { throw MastodonSessionError.invalidParameter }
        guard let url = URL(string: "https://\(host)/oauth/token") else { throw MastodonSessionError.invalidBaseURL }
        
        var request = URLRequest(url: url)
        request.httpBody = data
        request.httpMethod = "POST"
        
        let task = URLSession(configuration: URLSessionConfiguration.default).dataTask(with: request) { (data, response, error) in
            do {
                let (accessToken, createdAt) = try handleAccessTokenReponse(data: data, response: response, error: error)
                let session = try MastodonSession(host: host, userName: "", accessToken: accessToken, clientID: clientID, clientSecret: clientSecret, createdAt: createdAt)
                try tryToDownloadUserProfile(session: session)
            } catch {
                print(error)
            }
        }
        task.resume()
    }
    
    static func openBrowserForOAuth2(host: String, clientID: String) {
        let parameters: [String: String] = [
            "client_id": clientID,
            "response_type": "code",
            "scope": scopes,
            "redirect_uri": redirectURI(host: host)
        ]
        let query = parameters.URLQuery

        let urlstring = "https://\(host)/oauth/authorize?" + query
        if let url = URL(string: urlstring) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    // MARK: -
    
    public static func sessions() throws -> [MastodonSession] {
        let keychain = Keychain(service: MastodonSession.accountKeychainIdentifier)
        let keys = try keychain.keys()
        return keys.flatMap({
            do {
                let data = try keychain.data(of: $0)
                guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else { return nil }
                return try MastodonSession(json: json)
            } catch {
                return nil
            }
        })
    }
    
    public static func add(host: String) {
        guard let (clientID, _) = MastodonSession.clientKeys(of: host)
            else {
                do {
                    try tryToDownloadClientKeys(host: host)
                } catch {
                    print(error)
                }
                return
            }
        openBrowserForOAuth2(host: host, clientID: clientID)
    }
    
    static func removeAll() {
        [MastodonSession.hostKeychainIdentifier, MastodonSession.accountKeychainIdentifier].forEach({
            removeAllData(of: $0)
        })
    }
    
    public static func handleCallback(url: URL) throws {
        guard let query = url.query else { throw MastodonSessionError.invalidCallbackURL }
        guard let host = url.host else { throw MastodonSessionError.invalidCallbackURL }
        let entries = query.components(separatedBy: "&")
        let dictionary: [String: String] = entries.reduce([:], { (result, string) -> [String: String] in
            let components = string.components(separatedBy: "=")
            guard components.count == 2 else { return result }
            var temp = result
            temp[components[0]] = components[1]
            return temp
        })
        guard let code = dictionary["code"] else { throw MastodonSessionError.invalidCallbackURL }
        try MastodonSession.tryToDownloadAccessToken(host: host, code: code)
    }
    
    static func removeAllData(of identifier: String) {
        let keychain = Keychain(service: identifier)
        do {
            let keys = try keychain.keys()
            keys.forEach({ keychain.delete(key: $0) })
        } catch {
            print(error)
        }
    }
    
    public static func delete(host: String) throws {
        let keychain = Keychain(service: MastodonSession.hostKeychainIdentifier)
        keychain.delete(key: host)
    }
    
    public static func delete(session: MastodonSession) throws {
        let keychain = Keychain(service: MastodonSession.accountKeychainIdentifier)
        keychain.delete(key: "\(session.userName)@\(session.host)")
    }
    
    static func save(host: String, clientID: String, clientSecret: String) throws {
        let info = [
            "clientID": clientID,
            "clientSecret": clientSecret
        ]
        let data = try JSONSerialization.data(withJSONObject: info, options: [])
        let keychain = Keychain(service: MastodonSession.hostKeychainIdentifier)
        try keychain.save(key: host, data: data)
    }
    
    static func clientKeys(of host: String) -> (String, String)? {
        let keychain = Keychain(service: MastodonSession.hostKeychainIdentifier)
        do {
            let data = try keychain.data(of: host)
            guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: String] else { throw MastodonSessionError.invalidJSONDataInKeychain }
            guard let clientID = json["clientID"] else { throw MastodonSessionError.invalidJSONDataInKeychain }
            guard let clientSecret = json["clientSecret"] else { throw MastodonSessionError.invalidJSONDataInKeychain }
            return (clientID, clientSecret)
        } catch MiniKeychain.Status.itemNotFound {
            return nil
        } catch {
            keychain.delete(key: host)
            return nil
        }
    }
}
