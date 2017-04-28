//
//  TextViewCell.swift
//  swiftodon
//
//  Created by sonson on 2017/04/28.
//  Copyright © 2017年 sonson. All rights reserved.
//

import UIKit
import UZTextView

class TextViewCell: UITableViewCell {
    @IBOutlet var textView: UZTextView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
