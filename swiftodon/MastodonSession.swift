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

struct MastodonSession {
    let host: String
    let userName: String
    let accessToken: String
    let clientID: String
    let clientSecret: String
    
    static func get(host: String) {
        
        let redirect_uri = "swiftodon://\(host)/"
        
        let url = URL(string: "https://\(host)/api/v1/apps")!
        
        let parameters: [String: String] = [
            "client_name": "com.sonson.swiftodon",
            "redirect_uris": redirect_uri,
            "scopes": "read write follow"
        ]
        
        let para: [(String, String)] = parameters.flatMap({
            guard let value = $0.1.addingPercentEncoding(withAllowedCharacters: .urlUserAllowed) else { return nil }
            return ($0.0, value)
        })
        let str = para.flatMap({"\($0.0)=\($0.1)"}).joined(separator: "&")
        print(str)
        
        let data = str.data(using: .utf8)!
        
        var request = URLRequest(url: url)
        request.httpBody = data
        request.httpMethod = "POST"
        
        let task = URLSession(configuration: URLSessionConfiguration.default).dataTask(with: request) { (data, response, error) in
            switch (data, response, error) {
            case (let data?, let response as HTTPURLResponse, _):
                do {
                    guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else { return }
                    guard let client_id = json["client_id"] as? String else { return }
                    guard let client_secret = json["client_secret"] as? String else { return }
                    try MastodonSession.save(host: host, clientID: client_id, clientSecret: client_secret)
                } catch {
                    print(error)
                }
            default:
                do {}
            }
        }
        task.resume()
    }
    
    static func add(host: String) {
        
        do {
            let (clientID, clientSecret) = try MastodonSession.clientKeys(of: host)
        } catch Status.itemNotFound {
            get(host: host)
        } catch {
            print(error)
        }
        
    }
    
    static func openBrowserForOAuth2(host: String) {
//        let parameters: [String: String] = [
//            "client_id": client_id,
//            "response_type": "code",
//            "redirect_uri": redirect_uri
//        ]
//        
//        let para: [(String, String)] = parameters.flatMap({
//            guard let value = $0.1.addingPercentEncoding(withAllowedCharacters: .urlUserAllowed) else { return nil }
//            return ($0.0, value)
//        })
//        let str = para.flatMap({"\($0.0)=\($0.1)"}).joined(separator: "&")
//        
//        let urlstring = "https://mstdn.jp/oauth/authorize?" + str
//        
//        if let url = URL(string: urlstring) {
//            print(url)
//            UIApplication.shared.open(url, options: [:], completionHandler: nil)
//        }
    }
    
    static func sessions() -> [MastodonSession] {
        let keychain = MiniKeychain(service:"com.sonson.swiftodon.clientKeys")
        do {
            let keys = try keychain.keys()
        } catch {
            print(error)
            return []
        }
        return []
    }
    
    static func save(host: String, code: String, userName: String) {
        
    }
    
    static func save(host: String, clientID: String, clientSecret: String) throws {
        let info = [
            "clientID": clientID,
            "clientSecret": clientSecret
        ]
        let data = try JSONSerialization.data(withJSONObject: info, options: [])
        let keychain = MiniKeychain(service:"com.sonson.swiftodon.client")
        try keychain.save(key: host, data: data)
    }
    
    static func clientKeys(of host: String) throws -> (String, String) {
        let keychain = MiniKeychain(service:"com.sonson.swiftodon.client")
        let data = try keychain.data(of: host)
        guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: String] else { throw MastodonSessionError.invalidJSONDataInKeychain }
        guard let clientID = json["clientID"] else { throw MastodonSessionError.invalidJSONDataInKeychain }
        guard let clientSecret = json["clientSecret"] else { throw MastodonSessionError.invalidJSONDataInKeychain }
        return (clientID, clientSecret)
    }
    
}
