//
//  MastodonProtocol.swift
//  swiftodon
//
//  Created by sonson on 2017/04/27.
//  Copyright © 2017年 sonson. All rights reserved.
//

import Foundation

protocol MastodonProtocol {
    var session: MastodonSession { get }
    var version: String { get }
    var parameters: [String: String] { get }
    var method: HTTPMethod { get }
    var path: String { get }
    func request() throws -> URLRequest
}

enum MastodonProtocolError: Error {
    case cannotCreateRequest
    case unexpectedJSONData
    case httpError(code: Int)
}

extension MastodonProtocol {
    var version: String {
        return "v1"
    }
    
    func request() throws -> URLRequest {
        switch method {
        case .get:
            let query = parameters.URLQuery
            guard let url = URL(string: session.baseURL.absoluteString + path + "?" + query) else { throw MastodonProtocolError.cannotCreateRequest }
            var request = URLRequest(url: url)
            request.httpMethod = method.rawValue
            request.setValue("Bearer " + session.accessToken, forHTTPHeaderField: "Authorization")
            return request
        default:
            throw MastodonProtocolError.cannotCreateRequest
        }
    }
}

protocol AccountEndpoint {
    func parse(data: Data?, response: URLResponse?, error: Error?) throws -> Account
}

extension AccountEndpoint {
    func parse(data: Data?, response: URLResponse?, error: Error?) throws -> Account {
        switch (data, response, error) {
        case (let data?, let response as HTTPURLResponse, _):
            if 200..<300 ~= response.statusCode {
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                guard let dictionary = json as? JSONDictionary else { throw MastodonProtocolError.unexpectedJSONData }
                guard let account = Account(json: dictionary) else { throw MastodonProtocolError.unexpectedJSONData }
                return account
            } else {
                throw MastodonProtocolError.httpError(code: response.statusCode)
            }
        case (_, _, let error?):
            throw error
        default:
            fatalError("Unexpected response from URLsession.")
        }
    }
}

struct CurrentUser: MastodonProtocol, AccountEndpoint {
    let path: String
    let parameters: [String : String]
    let session: MastodonSession
    let method: HTTPMethod
    
    init(session: MastodonSession) {
        self.session = session
        self.method = .get
        self.path = "/accounts/verify_credentials"
        self.parameters = [:]
    }
}
