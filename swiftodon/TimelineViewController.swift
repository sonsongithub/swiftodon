//
//  TimelineViewController.swift
//  swiftodon
//
//  Created by sonson on 2017/04/28.
//  Copyright © 2017年 sonson. All rights reserved.
//

import UIKit
import swiftodon

class TimelineViewController: UITableViewController {
    var session: MastodonSession?
    var home: TimelineController?
    var local: TimelineController?
    var union: TimelineController?
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(TimelineViewController.add(sender:)))
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(TimelineViewController.didUpdate(notification:)), name: TimelineControllerUpdateNotification, object: nil)
        
        do {
            let list = try MastodonSession.sessions()
            if list.count > 0 {
                home = TimelineController(session: list[0], type: .union)
                local = TimelineController(session: list[0], type: .local)
                union = TimelineController(session: list[0], type: .union)
                home?.textViewWidth = self.view.frame.size.width - 16
                try home?.update()
            }
        } catch {
            print(error)
        }
    }
    
    func didUpdate(notification: NSNotification) {
        tableView.reloadData()
    }
    
    func add(sender: Any) {
        let con = AccountListViewController(nibName: nil, bundle: nil)
        let nav = UINavigationController(rootViewController: con)
        present(nav, animated: true, completion: nil)
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
    }
    
    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    }
    
    func pulldownCheck(_ scrollView: UIScrollView) {
        guard let controller = home else { return }
        if scrollView.contentOffset.y + scrollView.contentInset.top < -64 && scrollView.contentOffset.y < 0 {
            do {
                try controller.getLatest()
            } catch {
                print(error)
            }
        }
    }
    
    func pullupCheck(_ scrollView: UIScrollView) {
        guard let controller = home else { return }
        if scrollView.contentSize.height - scrollView.frame.size.height - scrollView.contentOffset.y < -64 && scrollView.contentOffset.y > 0 {
            do {
                try controller.getOld()
            } catch {
                print(error)
            }
        }
    }
    
    override func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        pullupCheck(scrollView)
        pulldownCheck(scrollView)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let controller = home else { return 0 }
        return controller.contents.count
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let controller = home else { return }
        do {
            guard let timelineContent = controller.contents[indexPath.row] as? DownloadMore else { return }
            try controller.fetch(max_id: timelineContent.maxID, since_id: timelineContent.sinceID, insertIndex: indexPath.row)
            tableView.beginUpdates()
            tableView.reloadRows(at: [indexPath], with: .fade)
            tableView.endUpdates()
        } catch {

        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let controller = home else { return 0 }
        
        switch controller.contents[indexPath.row] {
        case (let content as Content):
            return content.height + 49
        default:
            return 44
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let controller = home else { fatalError() }
        let timelineContent = controller.contents[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: timelineContent.cellIdentifier, for: indexPath)

        if let cell = cell as? TextViewCell, let content = timelineContent as? Content {
            cell.textView.attributedString = content.attributedString
            cell.idLabel.text = String(content.status.id)
        } else if let cell = cell as? LoadingCell {
            cell.indicatorView.startAnimating()
        }

        return cell
    }
}
