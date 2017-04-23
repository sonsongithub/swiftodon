//
//  ViewController.swift
//  swiftodon
//
//  Created by sonson on 2017/04/21.
//  Copyright © 2017年 sonson. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        MastodonSession.add(host: "mstdn.jp")
        
//        let redirect_uri = "swiftodon://mstdn.jp/"
//        
//        let url = URL(string: "https://mstdn.jp/api/v1/apps")!
//        
//        let parameters: [String: String] = [
//            "client_name": "com.sonson.swiftodon",
//            "redirect_uris": redirect_uri,
//            "scopes": "read write follow"
//        ]
//        
//        let para: [(String, String)] = parameters.flatMap({
//            guard let value = $0.1.addingPercentEncoding(withAllowedCharacters: .urlUserAllowed) else { return nil }
//            return ($0.0, value)
//        })
//        let str = para.flatMap({"\($0.0)=\($0.1)"}).joined(separator: "&")
//        print(str)
//        
//        let data = str.data(using: .utf8)!
//        
//        var request = URLRequest(url: url)
//        request.httpBody = data
//        request.httpMethod = "POST"
//        
//        let task = URLSession(configuration: URLSessionConfiguration.default).dataTask(with: request) { (data, response, error) in
//            switch (data, response, error) {
//            case (let data?, let response as HTTPURLResponse, _):
//                do {
//                    guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else { return }
//                    print(json)
//                    
//                    guard let client_id = json["client_id"] as? String else { return }
//                    guard let client_secret = json["client_secret"] as? String else { return }
//                    
//                    let parameters: [String: String] = [
//                        "client_id": client_id,
//                        "response_type": "code",
//                        "redirect_uri": redirect_uri
//                    ]
//                    
//                    let para: [(String, String)] = parameters.flatMap({
//                        guard let value = $0.1.addingPercentEncoding(withAllowedCharacters: .urlUserAllowed) else { return nil }
//                        return ($0.0, value)
//                    })
//                    let str = para.flatMap({"\($0.0)=\($0.1)"}).joined(separator: "&")
//                    
//                    let urlstring = "https://mstdn.jp/oauth/authorize?" + str
//                    
//                    if let url = URL(string: urlstring) {
//                        print(url)
//                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
//                    }
//                } catch {
//                    print(error)
//                }
//            default:
//                do {}
//            }
//        }
//        task.resume()
    }

    @IBAction func open(sender: Any) {
        let controller = AddAccountViewController()
        let nav = UINavigationController(rootViewController: controller)
        self.present(nav, animated: true, completion: nil)
    }
}

