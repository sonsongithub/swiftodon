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
    @IBOutlet var iconImageButton: UIButton!
    @IBOutlet var textView: UZTextView!
    @IBOutlet var idLabel: UILabel!
    
    var iconImageLoading = false
    
    var iconImageURL: URL? {
        didSet {
            
            if let url = iconImageURL {
                let string = url.absoluteString
                let hash: String = string.digest(type: .sha1)
                
                let cachePath = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
                let imageCachePath = cachePath.appendingPathComponent("image")
                do {
                    try FileManager.default.createDirectory(at: imageCachePath, withIntermediateDirectories: true, attributes: [:])
                } catch {
                    print(error)
                }
                let filePath = imageCachePath.appendingPathComponent(hash)
                if let image = UIImage(contentsOfFile: filePath.path) {
                    print("hit cache")
                    self.iconImageButton.setImage(image, for: .normal)
                } else {
                    guard !iconImageLoading else { return }
                    iconImageLoading = true
                    let request = URLRequest(url: url)
                    let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                        //                    defer { self.iconImageLoading = false }
                        guard let data = data else { return }
                        guard let image = UIImage(data: data) else { return }
                        do {
                            try data.write(to: filePath)
                        } catch {
                            print(error)
                        }
                        DispatchQueue.main.async(execute: {
                            self.iconImageButton.setImage(image, for: .normal)
                        })
                    }
                    task.resume()
                }
            }
        }
    }
    
    func didTapIconImage(sender: Any) {
        print(#function)
        
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        iconImageURL = nil
        if let iconImageButton = iconImageButton {
            iconImageButton.setImage(nil, for: .normal)
        }
        iconImageLoading = false
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        if let iconImageButton = iconImageButton {
            iconImageButton.addTarget(self, action: #selector(TextViewCell.didTapIconImage(sender:)), for: .touchUpInside)
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    
}
