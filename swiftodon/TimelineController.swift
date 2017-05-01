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
    
    var latest: Int = 0
    var old: Int = 0
    var loading = false
    
    init(session: MastodonSession, type: TimelineType) {
        self.session = session
        self.type = type
    }
    
    func getLatest() throws {
        guard !loading else { return }
        try fetch(max_id: nil, since_id: latest)
    }
    
    func getOld() throws {
        guard !loading else { return }
        try fetch(max_id: old, since_id: nil)
    }
    
    func createAPI(max_id: Int?, since_id: Int?) -> TimelineAPI {
        switch (max_id, since_id) {
        case (let max_id?, _):
            return TimelineAPI(session: session, max_id: max_id)
        case (_, let since_id?):
            return TimelineAPI(session: session, since_id: since_id)
        default:
            return TimelineAPI(session: session)
        }
    }
    
    func update() throws {
        guard !loading else { return }
        try fetch(max_id: nil, since_id: nil)
    }
    
    func fetch(max_id: Int?, since_id: Int?) throws {
        guard !loading else { return }
        let api = createAPI(max_id: max_id, since_id: since_id)
        let request = try api.request()
        loading = true
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            defer { self.loading = false }
            do {
                let statusArray = try api.parse(data: data, response: response, error: error)
                
                guard statusArray.count > 0 else { return }
                
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
                
                var insertedIndices: [IndexPath] = []
                
                switch api.type {
                case .update:
                    insertedIndices = (self.contents.count..<self.contents.count + r.count).map({IndexPath(row: $0, section: 0)})
                    self.contents.append(contentsOf: r)
                case .maxID:
                    insertedIndices = (self.contents.count..<self.contents.count + r.count).map({IndexPath(row: $0, section: 0)})
                    self.contents.append(contentsOf: r)
                case .sinceID:
                    insertedIndices = (0..<r.count).map({IndexPath(row: $0, section: 0)})
                    self.contents = r + self.contents
                }
                
                let idarray = statusArray.map({$0.id})
                self.latest = idarray.max()!
                self.old = idarray.min()!
                
                DispatchQueue.main.async(execute: {
                    NotificationCenter.default.post(name: TimelineControllerUpdateNotification, object: nil, userInfo: ["insertedPaths": insertedIndices])
                })
            } catch {
                print(error)
            }
        }
        task.resume()
    }
}
