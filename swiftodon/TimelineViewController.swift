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
                home = TimelineController(session: list[0], type: .home)
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
        self.tableView.reloadData()
    }
    
    func add(sender: Any) {
        let con = AccountListViewController(nibName: nil, bundle: nil)
        let nav = UINavigationController(rootViewController: con)
        present(nav, animated: true, completion: nil)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let controller = home else { return 0 }
        return controller.contents.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let controller = home else { return 0 }
        return controller.contents[indexPath.row].height + 16
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        if let cell = cell as? TextViewCell, let controller = home {
            cell.textView.attributedString = controller.contents[indexPath.row].attributedString
        }

        return cell
    }
}
