//
//  TimelineController.swift
//  swiftodon
//
//  Created by sonson on 2017/04/28.
//  Copyright © 2017年 sonson. All rights reserved.
//

import Foundation
import swiftodon

enum TimelineType {
    case home
    case local
    case union
}

class TimelineController {
    let session: MastodonSession
    let type: TimelineType
    var textViewWidth: CGFloat = 0
    
    init(session: MastodonSession, type: TimelineType) {
        self.session = session
        self.type = type
    }
}
