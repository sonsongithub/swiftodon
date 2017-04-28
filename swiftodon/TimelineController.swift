//
//  TimelineController.swift
//  swiftodon
//
//  Created by sonson on 2017/04/28.
//  Copyright © 2017年 sonson. All rights reserved.
//

import Foundation
import swiftodon
import UZTextView

let TimelineControllerUpdateNotification = UIKit.Notification.Name(rawValue: "TimelineControllerUpdateNotification")

enum TimelineType {
    case home
    case local
    case union
}

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

class TimelineController {
    let session: MastodonSession
    let type: TimelineType
    var textViewWidth: CGFloat = 0
    var contents: [Content] = []
    
    init(session: MastodonSession, type: TimelineType) {
        self.session = session
        self.type = type
    }
    
    func update() throws {
        let api = TimelineAPI(session: session)
        let request = try api.request()
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            do {
                let statusArray = try api.parse(data: data, response: response, error: error)

                let r: [Content] = statusArray.map({
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
                })
                self.contents.append(contentsOf: r)
                DispatchQueue.main.async(execute: {
                    NotificationCenter.default.post(name: TimelineControllerUpdateNotification, object: nil, userInfo: nil)
                })
            } catch {
                print(error)
            }
        }
        task.resume()
    }
}
