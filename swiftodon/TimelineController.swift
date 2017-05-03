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

protocol TimelineContent {
    var height: CGFloat { get }
    var cellIdentifier: String { get }
}

struct Content: TimelineContent {
    let status: Status
    let attributedString: NSAttributedString
    let height: CGFloat
    let cellIdentifier = "TimelineContent"
}

struct DownloadMore: TimelineContent {
    let height: CGFloat = 44
    let cellIdentifier = "DownloadMore"
    let maxID: Int
    let sinceID: Int
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

extension Status {
    func createContent(constrainedWidth: CGFloat) -> Content {
        do {
            guard let data = content.data(using: .utf8) else { throw NSError(domain: "", code: 9, userInfo: nil) }
            let attr = try NSMutableAttributedString(data: data, options: [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType, NSCharacterEncodingDocumentAttribute: String.Encoding.utf8.rawValue], documentAttributes: nil)
            attr.addAttribute(NSFontAttributeName, value: UIFont.systemFont(ofSize: 14), range: attr.fullRange)
            let bodySize = UZTextView.size(of: attr, restrictedWithin: constrainedWidth, inset: UIEdgeInsets.zero)
            let bodyHeight = bodySize.height
            
            return Content(status: self, attributedString: attr, height: bodyHeight)
        } catch {
            return Content(status: self, attributedString: NSAttributedString(string: ""), height: 44)
        }
    }
}

class TimelineController {
    let session: MastodonSession
    let type: TimelineType
    var textViewWidth: CGFloat = 0
    var contents: [TimelineContent] = []
    
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
        case (let max_id?, let since_id?):
            return TimelineAPI(session: session, max_id: max_id, since_id: since_id)
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
    
    func addToHead(api: TimelineAPI, data: Data?, response: URLResponse?, error: Error?) throws {
        let incommingStatus = try api.parse(data: data, response: response, error: error)
        var incommingContents: [Content] = incommingStatus.map({ $0.createContent(constrainedWidth: self.textViewWidth) })
        
        guard incommingContents.count > 0 else { return }
        
        // Adding to the head of the existing array.
        if self.contents.count > 0 {
            guard let head = self.contents.first as? Content else { return }
            
            incommingContents = incommingContents.filter({$0.status.id > head.status.id})
            
            guard let tail = incommingContents.last else { return }
            
            print("----------")
            print(tail.status.id - head.status.id)
            if tail.status.id - head.status.id == 1 {
                self.contents = incommingContents + self.contents
            } else {
                var temp: [TimelineContent] = []
                temp = temp + incommingContents
                temp += [DownloadMore(maxID: tail.status.id, sinceID: head.status.id)]
                self.contents = temp + self.contents
            }
        } else {
            self.contents = incommingContents + self.contents
        }
    }
    
    func insert(api: TimelineAPI, data: Data?, response: URLResponse?, error: Error?, insertIndex: Int) throws {
        let incommingStatus = try api.parse(data: data, response: response, error: error)
        var incommingContents: [Content] = incommingStatus.map({ $0.createContent(constrainedWidth: self.textViewWidth) })
        
        guard let tail = self.contents[insertIndex - 1] as? Content else { return }
        guard let head = self.contents[insertIndex + 1] as? Content else { return }
        
        self.contents.remove(at: insertIndex)
        
        var buff: [TimelineContent] = []
        
        incommingContents = incommingContents.filter({$0.status.id < tail.status.id && $0.status.id > head.status.id})
        buff += (incommingContents as [TimelineContent])
        
        guard incommingContents.count > 0 else { return }
        
        guard let incommingLast = incommingContents.last else { return }
        if incommingLast.status.id - head.status.id != 1 {
            buff += [DownloadMore(maxID: incommingLast.status.id, sinceID: head.status.id)]
        }
        
        self.contents.insert(contentsOf: buff, at: insertIndex)
        
        
        
//        // Adding to the head of the existing array.
//        if self.contents.count > 0 {
//            guard let head = self.contents.first as? Content else { return }
//            
//            incommingContents = incommingContents.filter({$0.status.id > head.status.id})
//            
//            guard let tail = incommingContents.last else { return }
//            
//            print("----------")
//            print(tail.status.id - head.status.id)
//            if tail.status.id - head.status.id == 1 {
//                self.contents = incommingContents + self.contents
//            } else {
//                var temp: [TimelineContent] = []
//                temp = temp + incommingContents
//                temp += [DownloadMore(maxID: tail.status.id, sinceID: head.status.id)]
//                self.contents = temp + self.contents
//            }
//        } else {
//            self.contents = incommingContents + self.contents
//        }
    }
    
    func fetch(max_id: Int?, since_id: Int?, insertIndex: Int? = nil) throws {
        guard !loading else { return }
        let api = createAPI(max_id: max_id, since_id: since_id)
        let request = try api.request()
        loading = true
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            defer { self.loading = false }
            do {
                // Adding new items at specfied index.
                switch (max_id, since_id) {
                case (let max_id?, let since_id?):
                    if let insertIndex = insertIndex {
                        try self.insert(api: api, data: data, response: response, error: error, insertIndex: insertIndex)
                    }
                case (let max_id?, _):
                    do {}
                case (_, let since_id?):
                    try self.addToHead(api: api, data: data, response: response, error: error)
                default:
                    try self.addToHead(api: api, data: data, response: response, error: error)
                }
                DispatchQueue.main.async(execute: {
                    NotificationCenter.default.post(name: TimelineControllerUpdateNotification, object: nil, userInfo: nil)
//                    NotificationCenter.default.post(name: TimelineControllerUpdateNotification, object: nil, userInfo: ["insertedPaths": insertedIndices])
                })
            } catch {
                print(error)
            }
        }
        task.resume()
    }
}
