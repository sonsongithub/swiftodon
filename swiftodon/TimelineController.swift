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

struct DownloadingMore: TimelineContent {
    let height: CGFloat = 44
    let cellIdentifier = "LoadingCell"
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
    
    public enum TimelineDownloadType {
        case add2tail
        case insert(index: Int)
        case add2head
    }

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
    
    func createAPI(max_id: Int?, since_id: Int?, insertIndex: Int?) -> (TimelineAPI, TimelineDownloadType) {
        switch (max_id, since_id, insertIndex) {
        case (let max_id?, let since_id?, let insertIndex?):
            contents[insertIndex] = DownloadingMore()
            return (TimelineAPI(session: session, max_id: max_id, since_id: since_id), .insert(index: insertIndex))
        case (let max_id?, _, _):
            return (TimelineAPI(session: session, max_id: max_id), .add2tail)
        case (_, let since_id?, _):
            return (TimelineAPI(session: session, since_id: since_id), .add2head)
        default:
            return (TimelineAPI(session: session), .add2head)
        }
    }
    
    func update() throws {
        guard !loading else { return }
        try fetch(max_id: nil, since_id: nil)
    }
    
    func addToHead(incommingContents: [Content]) throws {
        
        if self.contents.count > 0 {
            guard let head = self.contents.first as? Content else { return }
            
            let buf = incommingContents.filter({$0.status.id > head.status.id})
            
            guard buf.count > 0 else { return }
            
            guard let tail = buf.last else { return }
            
            print("----------")
            print(tail.status.id - head.status.id)
            if tail.status.id - head.status.id == 1 {
                self.contents = buf + self.contents
            } else {
                var temp: [TimelineContent] = []
                temp = temp + buf
                temp += [DownloadMore(maxID: tail.status.id, sinceID: head.status.id)]
                self.contents = temp + self.contents
            }
        } else {
            self.contents = incommingContents + self.contents
        }
    }
    
    func addToTail(incommingContents: [Content]) throws {
        guard let tail = self.contents.last as? Content else { return }
        let temp = incommingContents.filter({$0.status.id < tail.status.id})
        guard temp.count > 0 else { return }
        self.contents += temp as [TimelineContent]
    }
    
    func insert(incommingContents: [Content], insertIndex: Int) throws {
        
        var temp: [Content] = incommingContents
        
        guard let tail = self.contents[insertIndex - 1] as? Content else { return }
        guard let head = self.contents[insertIndex + 1] as? Content else { return }
        
        self.contents.remove(at: insertIndex)
        
        var buff: [TimelineContent] = []
        
        temp = incommingContents.filter({$0.status.id < tail.status.id && $0.status.id > head.status.id})
        buff += (temp as [TimelineContent])
        
        guard incommingContents.count > 0 else { return }
        
        guard let incommingLast = temp.last else { return }
        if incommingLast.status.id - head.status.id != 1 {
            buff += [DownloadMore(maxID: incommingLast.status.id, sinceID: head.status.id)]
        }
        
        self.contents.insert(contentsOf: buff, at: insertIndex)
    }
    
    func fetch(max_id: Int?, since_id: Int?, insertIndex: Int? = nil) throws {
        guard !loading else { return }
        let (api, type) = createAPI(max_id: max_id, since_id: since_id, insertIndex: insertIndex)
        let request = try api.request()
        loading = true
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            defer { self.loading = false }
            do {
                let incommingStatus = try api.parse(data: data, response: response, error: error)
                let incommingContents: [Content] = incommingStatus.map({ $0.createContent(constrainedWidth: self.textViewWidth) })
                
                // Adding new items at specfied index.
                switch type {
                case .add2head:
                    try self.addToHead(incommingContents: incommingContents)
                case .add2tail:
                    try self.addToTail(incommingContents: incommingContents)
                case .insert(let index):
                    try self.insert(incommingContents: incommingContents, insertIndex: index)
                }
                
                if let first = self.contents.first as? Content {
                    self.latest = first.status.id
                }
                if let last = self.contents.last as? Content {
                    self.old = last.status.id
                }
                
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
