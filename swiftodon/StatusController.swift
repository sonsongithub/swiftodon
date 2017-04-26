//
//  StatusController.swift
//  swiftodon
//
//  Created by sonson on 2017/04/26.
//  Copyright © 2017年 sonson. All rights reserved.
//

import Foundation
import UIKit
import UZTextView

let StatusControllerUpdateNotification = UIKit.Notification.Name(rawValue: "StatusControllerUpdateNotification")

struct Content {
    let attributedString: NSAttributedString
    let height: CGFloat
}

extension String {
    var utf16Range: NSRange {
        return NSRange(location: 0, length: self.utf16.count)
    }
}

extension NSMutableAttributedString {
    var fullRange: NSRange {
        return NSRange(location: 0, length: self.length)
    }
}

class StatusController {
    let session: MastodonSession
    var status: [Status] = []
    var contents: [Content] = []
    var textViewWidth: CGFloat = 0
    
    init(session :MastodonSession) {
        self.session = session
    }
    
    func update() {
        let resource = Timelines.public()
        let request = session.createRequest(resouce: resource)
        let task = URLSession(configuration: URLSessionConfiguration.default).dataTask(with: request) { (data, response, error) in
            switch (data, response, error) {
            case (let data?, let response as HTTPURLResponse, _):
                if 200..<300 ~= response.statusCode {
                    do {
                        let json = try JSONSerialization.jsonObject(with: data, options: []) 
                        let statuses = resource.parse(json)
                        
                        let r: [Content] = statuses.map({
                                do {
                                    guard let data = $0.content.data(using: .utf8) else { throw NSError(domain: "", code: 9, userInfo: nil) }
                                    let attr = try NSMutableAttributedString(data: data, options: [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType, NSCharacterEncodingDocumentAttribute: String.Encoding.utf8.rawValue], documentAttributes: nil)
                                    attr.addAttribute(NSFontAttributeName, value: UIFont.systemFont(ofSize: 14), range: attr.fullRange)
                                    let bodySize = UZTextView.size(of: attr, restrictedWithin: self.textViewWidth, inset: UIEdgeInsets.zero)
                                    let bodyHeight = bodySize.height
                                    
                                    return Content(attributedString: attr, height: bodyHeight)
                                } catch {
                                    print(error)
                                    return Content(attributedString: NSAttributedString(string: ""), height: 44)
                                }
//                            if let data = html.data(using: .unicode) {
//                                let attr = try NSAttributedString(data: data, options: [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType], documentAttributes: nil)
                        })
                        
                        self.contents.append(contentsOf: r)
                        
                        print(statuses)
                        DispatchQueue.main.async(execute: {
                            NotificationCenter.default.post(name: StatusControllerUpdateNotification, object: nil, userInfo: nil)
                        })
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
}
