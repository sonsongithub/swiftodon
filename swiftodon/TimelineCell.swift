//
//  TimelineCell.swift
//  swiftodon
//
//  Created by sonson on 2017/04/26.
//  Copyright © 2017年 sonson. All rights reserved.
//

import UIKit
import UZTextView

class TimelineCell: UITableViewCell {
    @IBOutlet var textView: UZTextView!
    @IBOutlet var iconView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
