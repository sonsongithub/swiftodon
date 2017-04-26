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
}

let MastodonSessionUpdateNotification = UIKit.Notification.Name(rawValue: "MastodonSessionUpdateNotification")

struct MastodonSession {
    let host: String
    let userName: String
    let accessToken: String
    let clientID: String
    let clientSecret: String
    let createdAt: TimeInterval
    
    // MARK: - Static properties
    
    static func redirectURI(host: String) -> String {
        return "swiftodon://\(host)/"
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
    
    var key: String {
        return "\(userName)@\(host)"
    }
    
    init(host: String, userName: String, accessToken: String, clientID: String, clientSecret: String, createdAt: Double) {
        self.host = host
        self.userName = userName
        self.accessToken = accessToken
        self.clientID = clientID
        self.clientSecret = clientSecret
        self.createdAt = createdAt
    }
    
    init?(json: JSONDictionary) {
        guard let host = json["host"] as? String else { return nil }
        guard let userName = json["userName"] as? String else { return nil }
        guard let accessToken = json["accessToken"] as? String else { return nil }
        guard let clientID = json["clientID"] as? String else { return nil }
        guard let clientSecret = json["clientSecret"] as? String else { return nil }
        guard let createdAt = json["createdAt"] as? Double else { return nil }
        
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
        
    func createRequest<T>(resouce: Resource<T>) -> URLRequest {
        let baseURL = "https://\(host)/api/v1/"
        
        let components = URLComponents(baseURL: baseURL, resource: resouce)
        
        var request = URLRequest(url: components.url!, timeoutInterval: 30)
        request.httpMethod = resouce.httpMethod.stringValue
        
        request.setValue("Bearer " + accessToken, forHTTPHeaderField: "Authorization")
        
        return request
    }
    
    // MARK: -
    
    static func tryToDownloadClientKeys(host: String) {
        
        let url = URL(string: "https://\(host)/api/v1/apps")!
        
        let parameters: [String: String] = [
            "client_name": clientName,
            "redirect_uris": redirectURI(host: host),
            "scopes": scopes
        ]
        let data = parameters.URLQuery.data(using: .utf8)!
        
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
    
    static func tryToDownloadUserProfile(session: MastodonSession) {
        let accountResource = Accounts.currentUser()
        let request = session.createRequest(resouce: accountResource)
        
        let task = URLSession.shared.dataTask(with: request) { (data, _, _) in
            if let data = data, let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) {
                if let account = accountResource.parse(jsonObject) {
                    let session = MastodonSession(host: session.host, userName: account.username, accessToken: session.accessToken, clientID: session.clientID, clientSecret: session.clientSecret, createdAt: session.createdAt)
                    do {
                        try session.save()
                        DispatchQueue.main.async(execute: {
                            NotificationCenter.default.post(name: MastodonSessionUpdateNotification, object: nil, userInfo: nil)
                        })
                    } catch {
                        print(error)
                    }
                    
                }
            }
        }
        task.resume()
    }
    
    static func tryToDownloadAccessToken(host: String, code: String) {
        do {
            let (clientID, clientSecret) = try MastodonSession.clientKeys(of: host)
            
            let parameters: [String: String] = [
                "grant_type": "authorization_code",
                "client_id": clientID,
                "client_secret": clientSecret,
                "redirect_uri": redirectURI(host: host),
                "code": code
            ]
            guard let data = parameters.URLQuery.data(using: .utf8) else { return }
            guard let url = URL(string: "https://\(host)/oauth/token") else { return }
            
            var request = URLRequest(url: url)
            request.httpBody = data
            request.httpMethod = "POST"
            
            let task = URLSession(configuration: URLSessionConfiguration.default).dataTask(with: request) { (data, response, error) in
                switch (data, response, error) {
                case (let data?, let response as HTTPURLResponse, _):
                    if 200..<300 ~= response.statusCode {
                        do {
                            guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else { return }
                            guard let accessToken = json["access_token"] as? String else { return }
                            guard let createdAt = json["created_at"] as? Double else { return }
                            let session = MastodonSession(host: host, userName: "", accessToken: accessToken, clientID: clientID, clientSecret: clientSecret, createdAt: createdAt)
                            tryToDownloadUserProfile(session: session)
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
        } catch {
            print(error)
            return
        }
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
    
    static func sessions() -> [MastodonSession] {
        let keychain = Keychain(service: MastodonSession.accountKeychainIdentifier)
        do {
            let keys = try keychain.keys()
            
            return keys.flatMap({
                do {
                    let data = try keychain.data(of: $0)
                    guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else { return nil }
                    return MastodonSession(json: json)
                } catch {
                    return nil
                }
            })
            
        } catch {
            print(error)
            return []
        }
    }
    
    static func add(host: String) {
        do {
            let (clientID, _) = try MastodonSession.clientKeys(of: host)
            openBrowserForOAuth2(host: host, clientID: clientID)
        } catch MiniKeychain.Status.itemNotFound {
            tryToDownloadClientKeys(host: host)
        } catch {
            print(error)
        }
    }
    
    static func removeAll() {
        [MastodonSession.hostKeychainIdentifier, MastodonSession.accountKeychainIdentifier].forEach({
            removeAllData(of: $0)
        })
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
    
    static func delete(host: String) throws {
        let keychain = Keychain(service: MastodonSession.hostKeychainIdentifier)
        keychain.delete(key: host)
    }
    
    static func delete(session: MastodonSession) throws {
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
    
    static func clientKeys(of host: String) throws -> (String, String) {
        let keychain = Keychain(service: MastodonSession.hostKeychainIdentifier)
        let data = try keychain.data(of: host)
        guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: String] else { throw MastodonSessionError.invalidJSONDataInKeychain }
        guard let clientID = json["clientID"] else { throw MastodonSessionError.invalidJSONDataInKeychain }
        guard let clientSecret = json["clientSecret"] else { throw MastodonSessionError.invalidJSONDataInKeychain }
        return (clientID, clientSecret)
    }
    
}
